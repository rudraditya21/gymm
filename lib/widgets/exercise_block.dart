import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/hive_service.dart';
import '../models/active_workout.dart';
import '../models/workout.dart';
import '../providers/active_workout_provider.dart';
import '../providers/rest_timer_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/format.dart';
import 'set_row.dart';

class ExerciseBlock extends ConsumerWidget {
  final int exerciseIndex;
  final ActiveExercise exercise;

  const ExerciseBlock({
    super.key,
    required this.exerciseIndex,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final useKg = ref.watch(settingsProvider).useKg;
    final restSeconds = ref.watch(settingsProvider).restSeconds;
    final suggestion = _overloadSuggestion(exercise.exerciseId, useKg);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      if (suggestion != null)
                        Text(
                          suggestion,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz,
                      color: cs.onSurface.withValues(alpha: 0.45)),
                  onSelected: (val) {
                    if (val == 'remove') notifier.removeExercise(exerciseIndex);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove exercise'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Column headers
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('SET',
                      textAlign: TextAlign.center,
                      style: _headerStyle(cs)),
                ),
                SizedBox(
                  width: 60,
                  child: Text('PREV',
                      textAlign: TextAlign.center,
                      style: _headerStyle(cs)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(useKg ? 'KG' : 'LB',
                      textAlign: TextAlign.center,
                      style: _headerStyle(cs)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text('REPS',
                      textAlign: TextAlign.center,
                      style: _headerStyle(cs)),
                ),
                const SizedBox(width: 8),
                const SizedBox(width: 36),
              ],
            ),
          ),
          // Sets — swipe left to delete
          ...exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            return Dismissible(
              key: ValueKey('${exercise.exerciseId}_set_$setIndex'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) =>
                  notifier.removeSet(exerciseIndex, setIndex),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: cs.error.withValues(alpha: 0.12),
                child: Icon(Icons.delete_outline,
                    color: cs.error, size: 20),
              ),
              child: SetRow(
                key: ValueKey('${exercise.exerciseId}_row_$setIndex'),
                set: set,
                useKg: useKg,
                onComplete: (weight, reps) {
                  notifier.completeSet(
                      exerciseIndex, setIndex, weight, reps);
                  if (!set.isCompleted) {
                    ref
                        .read(restTimerProvider.notifier)
                        .start(restSeconds);
                  }
                },
                onRemove: () =>
                    notifier.removeSet(exerciseIndex, setIndex),
              ),
            );
          }),
          // Add set
          TextButton.icon(
            onPressed: () => notifier.addSet(exerciseIndex),
            icon: Icon(Icons.add, size: 16, color: cs.primary),
            label: Text(
              'Add Set',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns "Last: 80 × 10  →  Try 82.5 kg" or null when no history.
  String? _overloadSuggestion(String exerciseId, bool useKg) {
    final workouts = HiveService.workouts.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    WorkoutSet? best;
    for (final w in workouts) {
      for (final ex in w.exercises) {
        if (ex.exerciseId != exerciseId) continue;
        for (final s in ex.sets) {
          if (!s.isCompleted || s.weight == null || s.reps == null) continue;
          if (best == null || (s.weight ?? 0) > (best.weight ?? 0)) {
            best = s;
          }
        }
        if (best != null) break;
      }
      if (best != null) break;
    }

    if (best == null) return null;

    final increment = useKg ? 2.5 : 5.0;
    final lastW = formatWeightNum(best.weight, useKg: useKg);
    final suggestW =
        formatWeightNum((best.weight ?? 0) + increment, useKg: useKg);
    final unit = useKg ? 'kg' : 'lb';
    return 'Last: $lastW × ${best.reps}  →  Try $suggestW $unit';
  }

  TextStyle _headerStyle(ColorScheme cs) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: cs.onSurface.withValues(alpha: 0.4),
      );
}
