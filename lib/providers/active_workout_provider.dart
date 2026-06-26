import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_service.dart';
import '../models/active_workout.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../utils/format.dart';
import 'history_provider.dart';

class ActiveWorkoutNotifier extends Notifier<ActiveWorkoutState?> {
  @override
  ActiveWorkoutState? build() => null;

  bool get isActive => state != null;

  void startEmpty() {
    state = ActiveWorkoutState(
      id: const Uuid().v4(),
      name: _defaultName(),
      startedAt: DateTime.now(),
      exercises: [],
    );
  }

  void startFromRoutine(Routine routine) {
    final exercises = routine.exercises.map((re) {
      final prev = _lastSets(re.exerciseId);
      return ActiveExercise(
        exerciseId: re.exerciseId,
        exerciseName: re.exerciseName,
        sets: List.generate(
          re.sets.isEmpty ? 1 : re.sets.length,
          (i) {
            final prevSet = i < prev.length ? prev[i] : null;
            final templateSet = i < re.sets.length ? re.sets[i] : null;
            return ActiveSet(
              index: i,
              weight: prevSet?.weight ?? templateSet?.weightTarget,
              reps: prevSet?.reps ?? templateSet?.repsTarget,
              prevWeight: prevSet?.weight,
              prevReps: prevSet?.reps,
            );
          },
        ),
      );
    }).toList();

    state = ActiveWorkoutState(
      id: const Uuid().v4(),
      name: routine.name,
      startedAt: DateTime.now(),
      exercises: exercises,
    );
  }

  void rename(String name) {
    if (state == null) return;
    state = state!.copyWith(name: name);
  }

  void addExercise(Exercise exercise) {
    if (state == null) return;
    final prev = _lastSets(exercise.id);
    final prevSet = prev.isNotEmpty ? prev.first : null;
    final newExercise = ActiveExercise(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      sets: [
        ActiveSet(
          index: 0,
          weight: prevSet?.weight,
          reps: prevSet?.reps,
          prevWeight: prevSet?.weight,
          prevReps: prevSet?.reps,
        ),
      ],
    );
    state = state!.copyWith(exercises: [...state!.exercises, newExercise]);
  }

  void removeExercise(int exerciseIndex) {
    if (state == null) return;
    final updated = [...state!.exercises]..removeAt(exerciseIndex);
    state = state!.copyWith(exercises: updated);
  }

  void addSet(int exerciseIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final ex = exercises[exerciseIndex];
    final lastSet = ex.sets.isNotEmpty ? ex.sets.last : null;
    final newSet = ActiveSet(
      index: ex.sets.length,
      weight: lastSet?.weight,
      reps: lastSet?.reps,
      prevWeight: null,
      prevReps: null,
    );
    exercises[exerciseIndex] = ex.copyWith(sets: [...ex.sets, newSet]);
    state = state!.copyWith(exercises: exercises);
  }

  void removeSet(int exerciseIndex, int setIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final ex = exercises[exerciseIndex];
    final sets = [...ex.sets]..removeAt(setIndex);
    // Reindex
    final reindexed = sets
        .asMap()
        .entries
        .map((e) => ActiveSet(
              index: e.key,
              isWarmup: e.value.isWarmup,
              isCompleted: e.value.isCompleted,
              weight: e.value.weight,
              reps: e.value.reps,
              prevWeight: e.value.prevWeight,
              prevReps: e.value.prevReps,
            ))
        .toList();
    exercises[exerciseIndex] = ex.copyWith(sets: reindexed);
    state = state!.copyWith(exercises: exercises);
  }

  void toggleWarmup(int exerciseIndex, int setIndex) {
    _updateSet(exerciseIndex, setIndex,
        (s) => s.copyWith(isWarmup: !s.isWarmup));
  }

  void completeSet(int exerciseIndex, int setIndex, double? weight, int? reps) {
    _updateSet(
      exerciseIndex,
      setIndex,
      (s) => ActiveSet(
        index: s.index,
        isWarmup: s.isWarmup,
        isCompleted: !s.isCompleted,
        weight: weight ?? s.weight,
        reps: reps ?? s.reps,
        prevWeight: s.prevWeight,
        prevReps: s.prevReps,
      ),
    );
  }

  void updateWeight(int exerciseIndex, int setIndex, double? weight) {
    _updateSet(exerciseIndex, setIndex,
        (s) => s.copyWith(weight: weight, clearWeight: weight == null));
  }

  void updateReps(int exerciseIndex, int setIndex, int? reps) {
    _updateSet(exerciseIndex, setIndex,
        (s) => s.copyWith(reps: reps, clearReps: reps == null));
  }

  Future<Workout> finish() async {
    final s = state!;
    final now = DateTime.now();

    final workout = Workout(
      id: s.id,
      name: s.name,
      startedAt: s.startedAt,
      finishedAt: now,
      exercises: s.exercises
          .map((ae) => WorkoutExercise(
                exerciseId: ae.exerciseId,
                exerciseName: ae.exerciseName,
                sets: ae.sets
                    .map((as_) => WorkoutSet(
                          weight: as_.weight,
                          reps: as_.reps,
                          isCompleted: as_.isCompleted,
                          isWarmup: as_.isWarmup,
                        ))
                    .toList(),
              ))
          .toList(),
    );

    await HiveService.workouts.put(workout.id, workout);
    ref.read(historyProvider.notifier).refresh();
    state = null;
    return workout;
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    if (newIndex > oldIndex) newIndex--;
    final item = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, item);
    state = state!.copyWith(exercises: exercises);
  }

  void cancel() => state = null;

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _updateSet(int ei, int si, ActiveSet Function(ActiveSet) fn) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final ex = exercises[ei];
    final sets = [...ex.sets];
    sets[si] = fn(sets[si]);
    exercises[ei] = ex.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);
  }

  List<WorkoutSet> _lastSets(String exerciseId) {
    final workouts = HiveService.workouts.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    for (final workout in workouts) {
      for (final ex in workout.exercises) {
        if (ex.exerciseId == exerciseId) return ex.sets;
      }
    }
    return [];
  }

  String _defaultName() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning Workout';
    if (h < 17) return 'Afternoon Workout';
    return 'Evening Workout';
  }

  // Used by exercise detail to find PRs
  static double bestE1RM(String exerciseId) {
    double best = 0;
    for (final workout in HiveService.workouts.values) {
      for (final ex in workout.exercises) {
        if (ex.exerciseId != exerciseId) continue;
        for (final s in ex.sets) {
          if (!s.isCompleted || s.weight == null || s.reps == null) continue;
          final e = estimate1RM(s.weight!, s.reps!);
          if (e > best) best = e;
        }
      }
    }
    return best;
  }
}

final activeWorkoutProvider =
    NotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>(
  ActiveWorkoutNotifier.new,
);
