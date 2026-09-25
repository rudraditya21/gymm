import '../data/hive_service.dart';
import '../models/workout.dart';

/// Returns a map of muscle group name → intensity (0.0–1.0).
/// Intensity is normalized volume (primary muscle gets full vol,
/// secondary muscles get 30%). Bodyweight/cardio sets count by set count.
Map<String, double> computeMuscleIntensities(List<Workout> workouts) {
  final scores = <String, double>{};

  for (final w in workouts) {
    for (final ex in w.exercises) {
      final exercise = HiveService.exercises.get(ex.exerciseId);
      if (exercise == null) continue;

      final primary = exercise.primaryMuscle;
      // Skip muscles with no body region
      if (primary == 'Cardio' || primary == 'Full Body') continue;

      final completedSets = ex.sets.where((s) => s.isWorkingSet).toList();
      if (completedSets.isEmpty) continue;

      final vol = completedSets.fold<double>(
          0, (s, set) => s + (set.weight ?? 0) * (set.reps ?? 0));

      // Bodyweight / cardio sets: proxy with set count
      final score = vol > 0 ? vol : completedSets.length * 50.0;

      scores.update(primary, (v) => v + score, ifAbsent: () => score);

      for (final m in exercise.secondaryMuscles) {
        if (m == 'Cardio' || m == 'Full Body') continue;
        scores.update(m, (v) => v + score * 0.3, ifAbsent: () => score * 0.3);
      }
    }
  }

  final maxScore =
      scores.values.fold(0.0, (a, b) => a > b ? a : b);
  if (maxScore == 0) return {};

  return scores.map(
    (k, v) => MapEntry(k, (v / maxScore).clamp(0.0, 1.0)),
  );
}
