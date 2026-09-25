import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/categories.dart';
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
  // Superset props
  final String? supersetLabel;
  final bool isLastInSuperset;
  final bool isLastExercise;

  const ExerciseBlock({
    super.key,
    required this.exerciseIndex,
    required this.exercise,
    this.supersetLabel,
    this.isLastInSuperset = true,
    this.isLastExercise = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final useKg = settings.useKg;
    final restSeconds = settings.restSeconds;
    final autoStartRest = settings.autoStartRest;

    // Detect exercise type via Hive exercise record
    final ex = HiveService.exercises.get(exercise.exerciseId);
    final isCardio = ex?.primaryMuscle == MuscleGroup.cardio;
    final isBodyweight = !isCardio && ex?.equipment == Equipment.bodyweight;

    final suggestion =
        isCardio ? null : _overloadSuggestion(exercise.exerciseId, useKg);

    // Superset accent color
    final inSuperset = supersetLabel != null;
    final accentColor = inSuperset ? cs.primary : cs.outline;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inSuperset ? accentColor : cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                // Superset label chip
                if (inSuperset) ...[
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      supersetLabel!,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      if (suggestion != null)
                        Text(
                          suggestion,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      if (isCardio)
                        Text(
                          'Cardio — log time & distance',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      if (isBodyweight)
                        Text(
                          'Bodyweight — weight is optional',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz,
                      color: cs.onSurface.withValues(alpha: 0.45)),
                  onSelected: (val) {
                    if (val == 'remove') {
                      notifier.removeExercise(exerciseIndex);
                    } else if (val == 'link_superset') {
                      notifier.createSuperset(exerciseIndex, exerciseIndex + 1);
                    } else if (val == 'unlink_superset') {
                      notifier.removeFromSuperset(exerciseIndex);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove exercise'),
                    ),
                    if (!isLastExercise && !inSuperset)
                      const PopupMenuItem(
                        value: 'link_superset',
                        child: Text('Superset with next'),
                      ),
                    if (inSuperset)
                      const PopupMenuItem(
                        value: 'unlink_superset',
                        child: Text('Remove from superset'),
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
                  child: Text(
                    isCardio
                        ? 'MIN'
                        : isBodyweight
                            ? (useKg ? '+KG' : '+LB')
                            : (useKg ? 'KG' : 'LB'),
                    textAlign: TextAlign.center,
                    style: _headerStyle(cs),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    isCardio ? 'KM' : 'REPS',
                    textAlign: TextAlign.center,
                    style: _headerStyle(cs),
                  ),
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
                isCardio: isCardio,
                isBodyweight: isBodyweight,
                onComplete: (weight, reps, duration, distance) {
                  notifier.completeSet(
                      exerciseIndex, setIndex, weight, reps, duration, distance);
                  if (!set.isCompleted && isLastInSuperset && autoStartRest) {
                    ref
                        .read(restTimerProvider.notifier)
                        .start(restSeconds);
                  }
                },
                onRemove: () =>
                    notifier.removeSet(exerciseIndex, setIndex),
                onCycleType: () =>
                    notifier.cycleSetType(exerciseIndex, setIndex),
              ),
            );
          }),
          // Add set
          TextButton.icon(
            onPressed: () => notifier.addSet(exerciseIndex),
            icon: Icon(Icons.add, size: 16, color: cs.primary),
            label: Text(
              'Add Set',
              style: GoogleFonts.dmSans(
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
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: cs.onSurface.withValues(alpha: 0.4),
      );
}
