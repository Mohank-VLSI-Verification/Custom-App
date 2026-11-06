import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'settings_sheet.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

/// Settings gear shown in every tab's app bar.
List<Widget> appBarActions(BuildContext context) => [
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        tooltip: 'Settings',
        onPressed: () => showSettingsSheet(context),
      ),
      const SizedBox(width: 4),
    ];

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      );
}

class DayHeader extends StatelessWidget {
  final DateTime day;
  const DayHeader(this.day, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
        child: Text(
          fmtDayHeader(day),
          style: const TextStyle(
            fontSize: 13,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
      );
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  const StatTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}

class ShiftRow extends StatelessWidget {
  final Shift shift;
  final int paidMinutes;
  final VoidCallback? onTap;

  const ShiftRow({
    super.key,
    required this.shift,
    required this.paidMinutes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text);
    return Material(
      color: AppColors.tile,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(fmtRange(shift.start, shift.end),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style),
                  ),
                  const SizedBox(width: 8),
                  Text(fmtMinutes(paidMinutes), style: style),
                ],
              ),
              if (shift.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(shift.note,
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyNote extends StatelessWidget {
  final String text;
  const EmptyNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text,
            style: const TextStyle(fontSize: 14, color: AppColors.muted)),
      );
}
