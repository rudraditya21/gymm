import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/hive_service.dart';
import '../../models/workout.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/format.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final exercises = ref.watch(exercisesProvider);
    final useKg = ref.watch(settingsProvider).useKg;

    final exercise = exercises.where((e) => e.id == exerciseId).firstOrNull;
    if (exercise == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox());
    }

    final history = _exerciseHistory(exerciseId);
    final bestE1RM = _bestEstimated1RM(history);
    final chartData = _chartPoints(history, useKg);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          exercise.name,
          style: GoogleFonts.dmSans(
            fontSize: 17,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _InfoTag(label: exercise.primaryMuscle, cs: cs),
                const SizedBox(width: 8),
                _InfoTag(label: exercise.equipment, cs: cs),
                if (exercise.isCustom) ...[
                  const SizedBox(width: 8),
                  _InfoTag(label: 'Custom', cs: cs),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Best 1RM
          if (bestE1RM > 0) ...[
            _SectionHeader('PERSONAL RECORD', cs),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 20, color: cs.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 8),
                  Text(
                    'Est. 1RM: ${formatWeight(bestE1RM, useKg: useKg)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Progress chart
          if (chartData.length >= 2) ...[
            _SectionHeader('WEIGHT PROGRESS', cs),
            const SizedBox(height: 8),
            _ProgressChart(data: chartData, useKg: useKg, cs: cs),
            const SizedBox(height: 20),
          ],
          // History
          if (history.isNotEmpty) ...[
            _SectionHeader('HISTORY', cs),
            const SizedBox(height: 8),
            ...history.map((entry) => _HistoryEntry(
                  workout: entry.workout,
                  sets: entry.sets,
                  useKg: useKg,
                  cs: cs,
                )),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Text(
                  'No workout history yet',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_ExerciseEntry> _exerciseHistory(String exId) {
    final workouts = HiveService.workouts.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return workouts
        .map((w) {
          final sets = w.exercises
              .where((e) => e.exerciseId == exId)
              .expand((e) => e.sets)
              .where((s) => s.isWorkingSet)
              .toList();
          if (sets.isEmpty) return null;
          return _ExerciseEntry(workout: w, sets: sets);
        })
        .whereType<_ExerciseEntry>()
        .take(20)
        .toList();
  }

  double _bestEstimated1RM(List<_ExerciseEntry> history) {
    double best = 0;
    for (final entry in history) {
      for (final s in entry.sets) {
        if (s.weight == null || s.reps == null) continue;
        final e = estimate1RM(s.weight!, s.reps!);
        if (e > best) best = e;
      }
    }
    return best;
  }

  List<FlSpot> _chartPoints(List<_ExerciseEntry> history, bool useKg) {
    final reversed = history.reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < reversed.length; i++) {
      final entry = reversed[i];
      double maxW = 0;
      for (final s in entry.sets) {
        if (s.weight != null && s.weight! > maxW) maxW = s.weight!;
      }
      final display = useKg ? maxW : maxW * 2.20462;
      spots.add(FlSpot(i.toDouble(), display));
    }
    return spots;
  }
}

class _ExerciseEntry {
  final Workout workout;
  final List<WorkoutSet> sets;
  _ExerciseEntry({required this.workout, required this.sets});
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _SectionHeader(this.text, this.cs);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.4,
        color: cs.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _InfoTag({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outline),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          color: cs.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _ProgressChart extends StatelessWidget {
  final List<FlSpot> data;
  final bool useKg;
  final ColorScheme cs;

  const _ProgressChart(
      {required this.data, required this.useKg, required this.cs});

  @override
  Widget build(BuildContext context) {
    final maxY = data.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = data.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final padding = (maxY - minY) * 0.15 + 5;

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.onSurface.withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (val, _) => Text(
                  val.toInt().toString(),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: cs.primary,
              barWidth: 2,
              dotData: FlDotData(
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: cs.primary,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: cs.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  final Workout workout;
  final List<WorkoutSet> sets;
  final bool useKg;
  final ColorScheme cs;

  const _HistoryEntry({
    required this.workout,
    required this.sets,
    required this.useKg,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final date = workout.startedAt;
    final dateStr = '${_monthName(date.month)} ${date.day}';
    final bestSet = sets.reduce((a, b) =>
        (a.weight ?? 0) > (b.weight ?? 0) ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              dateStr,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${sets.length} sets',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 12),
          if (bestSet.weight != null)
            Text(
              'Best: ${formatWeight(bestSet.weight, useKg: useKg)} × ${bestSet.reps ?? '–'}',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: cs.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  static String _monthName(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];
}
