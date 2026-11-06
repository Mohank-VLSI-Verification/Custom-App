import 'package:flutter/material.dart';

import '../services/repository.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/time_utils.dart';

Future<void> showSettingsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const SettingsSheet(),
    );

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  static const _roundOptions = [0, 5, 6, 10, 15, 30];
  static const _breakOptions = [0, 15, 30, 45, 60];

  List<DropdownMenuItem<int>> _items(
      List<int> options, int current, String Function(int) label) {
    final values = {...options, current}.toList()..sort();
    return [
      for (final v in values) DropdownMenuItem(value: v, child: Text(label(v))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repository.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final s = repo.settings;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pay period start date'),
                subtitle: Text(fmtLongDate(s.payPeriodStart)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: s.payPeriodStart,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    await repo.updateSettings(
                        s.copyWith(payPeriodStart: dateOnly(picked)));
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Unpaid break per workday'),
                trailing: DropdownButton<int>(
                  value: s.breakMinutes,
                  underline: const SizedBox.shrink(),
                  items: _items(_breakOptions, s.breakMinutes, fmtBreakOption),
                  onChanged: (v) {
                    if (v != null) repo.updateSettings(s.copyWith(breakMinutes: v));
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Round each shift to nearest'),
                trailing: DropdownButton<int>(
                  value: s.roundMinutes,
                  underline: const SizedBox.shrink(),
                  items: _items(_roundOptions, s.roundMinutes, fmtRoundOption),
                  onChanged: (v) {
                    if (v != null) repo.updateSettings(s.copyWith(roundMinutes: v));
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hours are calculated from your punch-in and punch-out times, '
                'minus the unpaid break once per workday.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              if (s.paydayAnchor != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Payday: every 2 weeks from ${fmtLongDate(s.paydayAnchor!)}. '
                  'Long-press a date on the Calendar to change it.',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
