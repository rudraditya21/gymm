import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/format.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final workout = ref.watch(workoutByIdProvider(workoutId));
    final useKg = ref.watch(settingsProvider).useKg;

    if (workout == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Workout not found')),
      );
    }

    final date = workout.startedAt;
    final dateStr =
        '${_monthName(date.month)} ${date.day}, ${date.year}';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          workout.name,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SummaryItem(
                      label: 'Duration',
                      value: formatDuration(workout.duration),
                      cs: cs,
                    ),
                    _SummaryItem(
                      label: 'Volume',
                      value: formatVolume(workout.totalVolume, useKg: useKg),
                      cs: cs,
                    ),
                    _SummaryItem(
                      label: 'Sets',
                      value: '${workout.completedSetsCount}',
                      cs: cs,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              workout.notes!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Exercises
          ...workout.exercises.map((ex) {
            final completedSets = ex.sets.where((s) => s.isCompleted).toList();
            if (completedSets.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.exerciseName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...completedSets.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    final wText = s.weight != null
                        ? formatWeightNum(s.weight, useKg: useKg)
                        : '–';
                    final unit = useKg ? 'kg' : 'lb';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${i + 1}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          Text(
                            '$wText $unit × ${s.reps ?? '–'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: cs.onSurface,
                            ),
                          ),
                          if (s.isWarmup) ...[
                            const SizedBox(width: 8),
                            Text(
                              'W',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
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

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _SummaryItem(
      {required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
