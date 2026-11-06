import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/ledger.dart';
import '../services/repository.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/time_utils.dart';
import 'widgets.dart';

enum TrendRange { day, week, month }

class _Bucket {
  final String label; // under the bar
  final String title; // tooltip heading
  final int minutes;
  const _Bucket(this.label, this.title, this.minutes);
}

class TrendsTab extends StatefulWidget {
  const TrendsTab({super.key});

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> {
  TrendRange _range = TrendRange.week;
  int? _touched;

  Repository get _repo => Repository.instance;

  String get _unit => switch (_range) {
        TrendRange.day => 'day',
        TrendRange.week => 'week',
        TrendRange.month => 'month',
      };

  List<_Bucket> _buckets(Ledger ledger) {
    final now = today();
    switch (_range) {
      case TrendRange.day:
        return [
          for (var i = 13; i >= 0; i--)
            () {
              final d = addDays(now, -i);
              return _Bucket('${d.day}', fmtDay(d), ledger.day(d));
            }(),
        ];
      case TrendRange.week:
        final thisWeek = startOfWeek(now);
        return [
          for (var i = 7; i >= 0; i--)
            () {
              final s = addDays(thisWeek, -7 * i);
              return _Bucket(DateFormat('M/d').format(s),
                  'Week of ${fmtMonthDay(s)}', ledger.range(s, addDays(s, 6)));
            }(),
        ];
      case TrendRange.month:
        return [
          for (var i = 5; i >= 0; i--)
            () {
              final s = DateTime(now.year, now.month - i, 1);
              final e = DateTime(s.year, s.month + 1, 0);
              return _Bucket(DateFormat.MMM().format(s),
                  DateFormat('MMMM yyyy').format(s), ledger.range(s, e));
            }(),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends'),
        actions: appBarActions(context),
      ),
      body: ListenableBuilder(
        listenable: _repo,
        builder: (context, _) {
          final buckets = _buckets(_repo.ledger);
          final total = buckets.fold<int>(0, (a, b) => a + b.minutes);
          final worked = buckets.where((b) => b.minutes > 0).toList();
          final avg = worked.isEmpty ? 0 : (total / worked.length).round();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _rangePicker(),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                child: Row(
                  children: [
                    _stat('This $_unit', buckets.last.minutes, highlight: true),
                    _stat('Avg / $_unit', avg),
                    _stat('Total shown', total),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.fromLTRB(20, 22, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle('Hours per $_unit'),
                    const SizedBox(height: 6),
                    const Text('Tap a bar for details',
                        style: TextStyle(fontSize: 14, color: AppColors.muted)),
                    const SizedBox(height: 18),
                    SizedBox(height: 260, child: _chart(context, buckets)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _rangePicker() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<TrendRange>(
        segments: const [
          ButtonSegment(value: TrendRange.day, label: Text('Day')),
          ButtonSegment(value: TrendRange.week, label: Text('Week')),
          ButtonSegment(value: TrendRange.month, label: Text('Month')),
        ],
        selected: {_range},
        onSelectionChanged: (s) => setState(() {
          _range = s.first;
          _touched = null;
        }),
        style: const ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 14)),
          textStyle: WidgetStatePropertyAll(
              TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _stat(String label, int minutes, {bool highlight = false}) {
    final color =
        highlight ? Theme.of(context).colorScheme.primary : AppColors.text;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(fmtMinutes(minutes),
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _chart(BuildContext context, List<_Bucket> buckets) {
    final primary = Theme.of(context).colorScheme.primary;
    final maxHours =
        buckets.fold<double>(0, (m, b) => math.max(m, b.minutes / 60));
    var top = maxHours <= 0 ? 2 : maxHours.ceil();
    if (top.isOdd) top += 1;
    final interval = top / 2;
    final barWidth = _range == TrendRange.day ? 13.0 : 20.0;
    const axisStyle = TextStyle(fontSize: 12, color: AppColors.muted);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: top.toDouble(),
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.grid, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: interval,
              getTitlesWidget: (value, meta) =>
                  Text(value.round().toString(), style: axisStyle),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= buckets.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(buckets[i].label, style: axisStyle),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return;
            final i = response?.spot?.touchedBarGroupIndex;
            setState(() => _touched = (i == null || i == _touched) ? null : i);
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.tile,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final b = buckets[group.x];
              return BarTooltipItem(
                '${b.title}\n',
                const TextStyle(fontSize: 12, color: AppColors.muted),
                children: [
                  TextSpan(
                    text: fmtMinutes(b.minutes),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < buckets.length; i++)
            BarChartGroupData(
              x: i,
              showingTooltipIndicators: _touched == i ? const [0] : const [],
              barRods: [
                BarChartRodData(
                  toY: buckets[i].minutes / 60,
                  width: barWidth,
                  color: primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
