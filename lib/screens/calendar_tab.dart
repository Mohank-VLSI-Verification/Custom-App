import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/repository.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/time_utils.dart';
import 'shift_edit_sheet.dart';
import 'widgets.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focused = today();
  DateTime _selected = today();

  Repository get _repo => Repository.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: appBarActions(context),
      ),
      body: ListenableBuilder(
        listenable: _repo,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AppCard(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              child: _calendar(context),
            ),
            const SizedBox(height: 16),
            _dayCard(context),
          ],
        ),
      ),
    );
  }

  Widget _calendar(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2100, 12, 31),
      focusedDay: _focused,
      currentDay: DateTime.now(),
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      startingDayOfWeek: StartingDayOfWeek.sunday,
      availableGestures: AvailableGestures.horizontalSwipe,
      daysOfWeekHeight: 36,
      rowHeight: 64,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: onSurface),
        leftChevronIcon: Icon(Icons.chevron_left, color: onSurface),
        rightChevronIcon: Icon(Icons.chevron_right, color: onSurface),
      ),
      calendarStyle: const CalendarStyle(outsideDaysVisible: false),
      selectedDayPredicate: (day) => sameDay(day, _selected),
      onDaySelected: (selected, focused) => setState(() {
        _selected = dateOnly(selected);
        _focused = dateOnly(focused);
      }),
      onDayLongPressed: (selected, focused) => _onLongPress(dateOnly(selected)),
      onPageChanged: (focused) => _focused = dateOnly(focused),
      calendarBuilders: CalendarBuilders(
        prioritizedBuilder: (context, day, focused) => _cell(context, day),
        dowBuilder: (context, day) {
          final weekend = day.weekday == DateTime.saturday ||
              day.weekday == DateTime.sunday;
          return Center(
            child: Text(
              DateFormat.E().format(day),
              style: TextStyle(
                fontSize: 15,
                color: weekend ? AppColors.faint : AppColors.muted,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cell(BuildContext context, DateTime rawDay) {
    final day = dateOnly(rawDay);
    final scheme = Theme.of(context).colorScheme;
    final selected = sameDay(day, _selected);
    final isToday = sameDay(day, DateTime.now());
    final weekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final payday = isPayday(_repo.settings.paydayAnchor, day);
    final minutes = _repo.ledger.day(day);

    Color numberColor = weekend ? AppColors.weekendDate : AppColors.text;
    if (isToday) numberColor = scheme.primary;
    if (selected) numberColor = Colors.white;

    return Column(
      children: [
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? scheme.primary : null,
            border: payday
                ? Border.all(color: AppColors.payday, width: 2.5)
                : null,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  selected || isToday ? FontWeight.w700 : FontWeight.w500,
              color: numberColor,
            ),
          ),
        ),
        if (minutes > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                fmtMinutes(minutes),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.hoursGreen,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onLongPress(DateTime day) async {
    setState(() {
      _selected = day;
      _focused = day;
    });
    final settings = _repo.settings;
    final alreadyPayday = isPayday(settings.paydayAnchor, day);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                fmtDay(day),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading:
                  const Icon(Icons.payments_outlined, color: AppColors.payday),
              title: const Text('Payday'),
              subtitle: const Text('Repeats every 2 weeks'),
              trailing: alreadyPayday ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(ctx).pop('payday'),
            ),
            if (settings.paydayAnchor != null)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: const Icon(Icons.event_busy_outlined),
                title: const Text('Remove payday'),
                onTap: () => Navigator.of(ctx).pop('clear'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == 'payday') {
      await _repo.updateSettings(settings.copyWith(paydayAnchor: day));
    } else if (choice == 'clear') {
      await _repo.updateSettings(settings.copyWith(clearPayday: true));
    }
  }

  Widget _dayCard(BuildContext context) {
    final ledger = _repo.ledger;
    final shifts = _repo.shifts
        .where((s) => sameDay(s.start, _selected))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final payday = isPayday(_repo.settings.paydayAnchor, _selected);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionTitle(fmtDay(_selected)),
              if (payday) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.payday.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Payday',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.payday),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                fmtMinutes(ledger.day(_selected)),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (shifts.isEmpty) const EmptyNote('No shifts on this day.'),
          for (final s in shifts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ShiftRow(
                shift: s,
                paidMinutes: ledger.shift(s),
                onTap: () => openShiftEditor(context, existing: s),
              ),
            ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => openShiftEditor(context, day: _selected),
            icon: const Icon(Icons.add),
            label: const Text('Add shift on this day',
                style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
