import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/format.dart';

class VolumeChartScreen extends ConsumerStatefulWidget {
  const VolumeChartScreen({super.key});

  @override
  ConsumerState<VolumeChartScreen> createState() => _VolumeChartScreenState();
}

enum _Period { weekly, monthly }

class _VolumeChartScreenState extends ConsumerState<VolumeChartScreen> {
  _Period _period = _Period.weekly;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final history = ref.watch(historyProvider);
    final useKg = ref.watch(settingsProvider).useKg;

    final buckets = _period == _Period.weekly
        ? _weeklyBuckets(history, useKg)
        : _monthlyBuckets(history, useKg);

    final maxY = buckets.isEmpty
        ? 100.0
        : buckets.map((b) => b.volume).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Volume',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period toggle
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: cs.secondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              children: [
                _PeriodBtn(
                  label: 'Weekly',
                  selected: _period == _Period.weekly,
                  onTap: () => setState(() => _period = _Period.weekly),
                  cs: cs,
                ),
                _PeriodBtn(
                  label: 'Monthly',
                  selected: _period == _Period.monthly,
                  onTap: () => setState(() => _period = _Period.monthly),
                  cs: cs,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (buckets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 64),
                child: Text(
                  'No workout data yet',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            )
          else ...[
            // Chart
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(0, 12, 16, 8),
              decoration: BoxDecoration(
                color: cs.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.25,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: cs.onSurface.withValues(alpha: 0.07),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: maxY / 4,
                        getTitlesWidget: (val, _) => Text(
                          _shortVolume(val, useKg),
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (val, _) {
                          final i = val.toInt();
                          if (i < 0 || i >= buckets.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              buckets[i].label,
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: buckets.asMap().entries.map((e) {
                    final isEmpty = e.value.volume == 0;
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: isEmpty ? 0 : e.value.volume,
                          color: isEmpty
                              ? cs.primary.withValues(alpha: 0.12)
                              : cs.primary,
                          width: _period == _Period.weekly ? 14 : 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => cs.surface,
                      getTooltipItem: (group, _, rod, __) {
                        final b = buckets[group.x];
                        return BarTooltipItem(
                          '${b.label}\n',
                          GoogleFonts.dmSans(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                          children: [
                            TextSpan(
                              text: formatVolume(
                                  useKg ? rod.toY : rod.toY / 2.20462,
                                  useKg: useKg),
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Summary rows
            _sectionHeader('BREAKDOWN', cs),
            const SizedBox(height: 8),
            ...buckets.reversed
                .where((b) => b.volume > 0)
                .map((b) => _BucketRow(bucket: b, useKg: useKg, cs: cs)),
          ],
        ],
      ),
    );
  }

  String _shortVolume(double val, bool useKg) {
    if (val == 0) return '0';
    final v = useKg ? val : val * 2.20462;
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toInt().toString();
  }

  Widget _sectionHeader(String text, ColorScheme cs) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.4,
          color: cs.onSurface.withValues(alpha: 0.45),
        ),
      );
}

// ── Data model ────────────────────────────────────────────────────────────────

class _Bucket {
  final String label;
  final double volume; // always in kg internally

  const _Bucket({required this.label, required this.volume});
}

List<_Bucket> _weeklyBuckets(List history, bool useKg) {
  final now = DateTime.now();
  final buckets = <_Bucket>[];

  for (int w = 11; w >= 0; w--) {
    final weekStart = now.subtract(Duration(days: now.weekday - 1 + w * 7));
    final wStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final wEnd = wStart.add(const Duration(days: 7));

    double vol = 0;
    for (final workout in history) {
      if (workout.startedAt.isAfter(wStart) &&
          workout.startedAt.isBefore(wEnd)) {
        vol += workout.totalVolume;
      }
    }

    final label = '${_shortMonth(wStart.month)}${wStart.day}';
    buckets.add(_Bucket(label: label, volume: vol));
  }
  return buckets;
}

List<_Bucket> _monthlyBuckets(List history, bool useKg) {
  final now = DateTime.now();
  final buckets = <_Bucket>[];

  for (int m = 11; m >= 0; m--) {
    final month = DateTime(now.year, now.month - m, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);

    double vol = 0;
    for (final workout in history) {
      if (!workout.startedAt.isBefore(month) &&
          workout.startedAt.isBefore(nextMonth)) {
        vol += workout.totalVolume;
      }
    }

    buckets.add(_Bucket(
      label: _shortMonth(month.month),
      volume: vol,
    ));
  }
  return buckets;
}

String _shortMonth(int m) => const [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][m];

// ── Widgets ───────────────────────────────────────────────────────────────────

class _PeriodBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _PeriodBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: selected
                  ? cs.onPrimary
                  : cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}

class _BucketRow extends StatelessWidget {
  final _Bucket bucket;
  final bool useKg;
  final ColorScheme cs;

  const _BucketRow({
    required this.bucket,
    required this.useKg,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              bucket.label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatVolume(bucket.volume, useKg: useKg),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
