import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../services/repository.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/time_utils.dart';
import 'shift_edit_sheet.dart';
import 'widgets.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  /// 0 = current pay period, -1 = previous, ...
  int _periodOffset = 0;

  Repository get _repo => Repository.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Tracker'),
        actions: appBarActions(context),
      ),
      body: ListenableBuilder(
        listenable: _repo,
        builder: (context, _) {
          final anchor = _repo.settings.payPeriodStart;
          final current = periodIndexFor(anchor, DateTime.now());
          final period = periodBounds(anchor, current + _periodOffset);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _statusCard(context),
              const SizedBox(height: 16),
              _periodCard(period),
              const SizedBox(height: 16),
              _shiftsCard(context, period),
            ],
          );
        },
      ),
    );
  }

  Widget _statusCard(BuildContext context) {
    final clockedIn = _repo.isClockedIn;
    final start = _repo.activeStart;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          const Text(
            'STATUS',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            clockedIn ? 'Clocked in' : 'Clocked out',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 66,
            child: FilledButton(
              onPressed: () => _repo.togglePunch(),
              style: FilledButton.styleFrom(
                backgroundColor:
                    clockedIn ? AppColors.punchOut : AppColors.punchIn,
                foregroundColor: clockedIn ? Colors.white : scheme.onPrimary,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700),
              ),
              child: Text(clockedIn ? 'Punch Out' : 'Punch In'),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            clockedIn && start != null
                ? 'Clocked in at ${fmtClock(start)}'
                : 'Tap to record your clock-in time.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _periodCard(Period p) {
    final ledger = _repo.ledger;
    final total = ledger.range(p.start, p.end);
    final week2Start = addDays(p.start, 7);
    final w1 = ledger.range(p.start, addDays(p.start, 6));
    final w2 = ledger.range(week2Start, p.end);
    final isCurrent = _periodOffset == 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle('This Pay Period')),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _periodOffset--),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    isCurrent ? null : () => setState(() => _periodOffset++),
              ),
            ],
          ),
          Text(
            '${fmtMonthDay(p.start)} – ${fmtMonthDay(p.end)}${isCurrent ? '  (current)' : ''}',
            style: const TextStyle(fontSize: 15, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  fmtMinutes(total),
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('paid',
                    style: TextStyle(fontSize: 16, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Week 1 (${fmtMonthDay(p.start)})',
                  value: fmtMinutes(w1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Week 2 (${fmtMonthDay(week2Start)})',
                  value: fmtMinutes(w2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shiftsCard(BuildContext context, Period p) {
    final ledger = _repo.ledger;
    final inPeriod = _repo.shifts.where((s) {
      final d = dateOnly(s.start);
      return !d.isBefore(p.start) && !d.isAfter(p.end);
    }).toList(); // newest first

    final children = <Widget>[];
    DateTime? lastDay;
    for (final Shift s in inPeriod) {
      final d = dateOnly(s.start);
      if (lastDay == null || !sameDay(d, lastDay)) {
        children.add(DayHeader(d));
        lastDay = d;
      } else {
        children.add(const SizedBox(height: 8));
      }
      children.add(ShiftRow(
        shift: s,
        paidMinutes: ledger.shift(s),
        onTap: () => openShiftEditor(context, existing: s),
      ));
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle('Shifts')),
              TextButton.icon(
                onPressed: () => openShiftEditor(context, day: today()),
                icon: const Icon(Icons.add),
                label: const Text('Add', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          if (children.isEmpty)
            const EmptyNote('No shifts in this period yet.')
          else
            ...children,
        ],
      ),
    );
  }
}
