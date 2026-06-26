import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/active_workout.dart';
import '../providers/active_workout_provider.dart';
import '../providers/rest_timer_provider.dart';
import '../providers/settings_provider.dart';
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
                  child: Text(
                    exercise.exerciseName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
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
          // Sets
          ...exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            return SetRow(
              key: ValueKey('${exercise.exerciseId}_$setIndex'),
              set: set,
              useKg: useKg,
              onComplete: (weight, reps) {
                notifier.completeSet(exerciseIndex, setIndex, weight, reps);
                if (!set.isCompleted) {
                  ref.read(restTimerProvider.notifier).start(restSeconds);
                }
              },
              onRemove: () => notifier.removeSet(exerciseIndex, setIndex),
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

  TextStyle _headerStyle(ColorScheme cs) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: cs.onSurface.withValues(alpha: 0.4),
      );
}
