import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/repository.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/time_utils.dart';
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
      startingDayOfWeek: StartingDayOfWeek.monday,
      weekNumbersVisible: true,
      availableGestures: AvailableGestures.horizontalSwipe,
      daysOfWeekHeight: 28,
      rowHeight: 70,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        leftChevronIcon: Icon(Icons.chevron_left, color: onSurface, size: 28),
        rightChevronIcon:
            Icon(Icons.chevron_right, color: onSurface, size: 28),
      ),
      calendarStyle: const CalendarStyle(outsideDaysVisible: true),
      selectedDayPredicate: (day) => sameDay(day, _selected),
      onDaySelected: (selected, focused) => setState(() {
        _selected = dateOnly(selected);
        _focused = dateOnly(selected);
      }),
      onDayLongPressed: (selected, focused) => _onLongPress(dateOnly(selected)),
      onPageChanged: (focused) => _focused = dateOnly(focused),
      calendarBuilders: CalendarBuilders(
        prioritizedBuilder: (context, day, focused) =>
            _cell(context, day, focused),
        headerTitleBuilder: (context, day) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.MMMM().format(day),
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: onSurface),
            ),
            Text(
              '${day.year}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        dowBuilder: (context, day) => Center(
          child: Text(
            DateFormat.E().format(day),
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
        weekNumberBuilder: (context, weekNumber) => Center(
          child: Text(
            '$weekNumber',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.faint),
          ),
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, DateTime rawDay, DateTime focused) {
    final day = dateOnly(rawDay);
    final scheme = Theme.of(context).colorScheme;
    final outside = day.month != focused.month;
    final selected = sameDay(day, _selected);
    final isToday = sameDay(day, DateTime.now());
    final weekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final payday = !outside && isPayday(_repo.settings.paydayAnchor, day);
    final minutes = outside ? 0 : _repo.ledger.day(day);

    // Payday: solid green tile. Worked day: tinted tile. Selected: outline.
    Color? fill;
    Color fg;
    if (payday) {
      fill = AppColors.payday;
      fg = Colors.white;
    } else if (minutes > 0) {
      fill = scheme.primary.withValues(alpha: 0.14);
      fg = scheme.primary;
    } else {
      fg = outside
          ? AppColors.outsideDate
          : (isToday
              ? scheme.primary
              : (weekend ? AppColors.muted : AppColors.text));
    }

    return Padding(
      padding: const EdgeInsets.all(2.5),
      child: Container(
        padding: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          border: selected && !outside
              ? Border.all(color: scheme.primary, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            if (minutes > 0) ...[
              const SizedBox(height: 3),
              Text(
                '${minutes ~/ 60}H',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: fg),
              ),
              Text(
                '${minutes % 60}M',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: fg.withValues(alpha: 0.85)),
              ),
            ],
          ],
        ),
      ),
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
}
