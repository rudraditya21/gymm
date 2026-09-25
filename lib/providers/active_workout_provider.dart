import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_service.dart';
import '../models/active_workout.dart';
import '../models/exercise.dart';
import '../models/pr_result.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../utils/format.dart';
import 'history_provider.dart';

class ActiveWorkoutNotifier extends Notifier<ActiveWorkoutState?> {
  Future<void> _draftWrite = Future.value();

  @override
  ActiveWorkoutState? build() => HiveService.activeWorkoutDraft;

  bool get isActive => state != null;

  void startEmpty() {
    _setState(ActiveWorkoutState(
      id: const Uuid().v4(),
      name: _defaultName(),
      startedAt: DateTime.now(),
      exercises: [],
    ));
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

    _setState(ActiveWorkoutState(
      id: const Uuid().v4(),
      name: routine.name,
      startedAt: DateTime.now(),
      exercises: exercises,
    ));
  }

  void rename(String name) {
    if (state == null) return;
    _setState(state!.copyWith(name: name));
  }

  void setNotes(String notes) {
    if (state == null) return;
    _setState(state!.copyWith(notes: notes));
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
    _setState(state!.copyWith(exercises: [...state!.exercises, newExercise]));
  }

  void removeExercise(int exerciseIndex) {
    if (state == null) return;
    final updated = [...state!.exercises]..removeAt(exerciseIndex);
    _setState(state!.copyWith(exercises: updated));
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
    _setState(state!.copyWith(exercises: exercises));
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
              isDropSet: e.value.isDropSet,
              isAmrap: e.value.isAmrap,
              weight: e.value.weight,
              reps: e.value.reps,
              prevWeight: e.value.prevWeight,
              prevReps: e.value.prevReps,
              durationSeconds: e.value.durationSeconds,
              distanceMeters: e.value.distanceMeters,
            ))
        .toList();
    exercises[exerciseIndex] = ex.copyWith(sets: reindexed);
    _setState(state!.copyWith(exercises: exercises));
  }

  void toggleWarmup(int exerciseIndex, int setIndex) {
    _updateSet(exerciseIndex, setIndex,
        (s) => s.copyWith(isWarmup: !s.isWarmup));
  }

  void cycleSetType(int exerciseIndex, int setIndex) {
    _updateSet(exerciseIndex, setIndex, (s) {
      switch (s.setType) {
        case SetType.normal:
          return s.copyWith(isWarmup: true, isDropSet: false, isAmrap: false);
        case SetType.warmup:
          return s.copyWith(isWarmup: false, isDropSet: true, isAmrap: false);
        case SetType.dropSet:
          return s.copyWith(isWarmup: false, isDropSet: false, isAmrap: true);
        case SetType.amrap:
          return s.copyWith(isWarmup: false, isDropSet: false, isAmrap: false);
      }
    });
  }

  void completeSet(int exerciseIndex, int setIndex, double? weight, int? reps,
      [int? durationSeconds, double? distanceMeters]) {
    _updateSet(
      exerciseIndex,
      setIndex,
      (s) => ActiveSet(
        index: s.index,
        isWarmup: s.isWarmup,
        isCompleted: !s.isCompleted,
        isDropSet: s.isDropSet,
        isAmrap: s.isAmrap,
        weight: weight ?? s.weight,
        reps: reps ?? s.reps,
        prevWeight: s.prevWeight,
        prevReps: s.prevReps,
        durationSeconds: durationSeconds ?? s.durationSeconds,
        distanceMeters: distanceMeters ?? s.distanceMeters,
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

  Future<(Workout, List<PRResult>)> finish() async {
    final s = state!;
    final now = DateTime.now();

    // Compute PRs before saving so we compare against previous workouts only
    final prs = _computePRs(s);

    final workout = Workout(
      id: s.id,
      name: s.name,
      startedAt: s.startedAt,
      finishedAt: now,
      notes: s.notes.isEmpty ? null : s.notes,
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
                          isDropSet: as_.isDropSet,
                          isAmrap: as_.isAmrap,
                          durationSeconds: as_.durationSeconds,
                          distanceMeters: as_.distanceMeters,
                        ))
                    .toList(),
              ))
          .toList(),
    );

    await HiveService.workouts.put(workout.id, workout);
    ref.read(historyProvider.notifier).refresh();
    _setState(null);
    await _draftWrite;
    return (workout, prs);
  }

  List<PRResult> _computePRs(ActiveWorkoutState s) {
    final results = <PRResult>[];
    for (final ex in s.exercises) {
      // Skip cardio exercises — no 1RM to compare
      final isCardio = ex.sets.isNotEmpty &&
          ex.sets.every((set) => set.weight == null && set.durationSeconds != null);
      if (isCardio) continue;
      final historicalBest = _bestHistoricalE1RM(ex.exerciseId);
      double newBest = 0;
      double bestWeight = 0;
      int bestReps = 0;
      for (final set in ex.sets) {
        if (!set.isCompleted || set.weight == null || set.reps == null) continue;
        final e = estimate1RM(set.weight!, set.reps!);
        if (e > newBest) {
          newBest = e;
          bestWeight = set.weight!;
          bestReps = set.reps!;
        }
      }
      if (newBest > historicalBest) {
        results.add(PRResult(
          exerciseName: ex.exerciseName,
          weight: bestWeight,
          reps: bestReps,
          estimated1RM: newBest,
        ));
      }
    }
    return results;
  }

  double _bestHistoricalE1RM(String exerciseId) {
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

  void createSuperset(int index1, int index2) {
    if (state == null) return;
    final groupId = const Uuid().v4();
    final exercises = [...state!.exercises];
    exercises[index1] = exercises[index1].copyWith(supersetGroupId: groupId);
    exercises[index2] = exercises[index2].copyWith(supersetGroupId: groupId);
    _setState(state!.copyWith(exercises: exercises));
  }

  void removeFromSuperset(int exerciseIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    exercises[exerciseIndex] =
        exercises[exerciseIndex].copyWith(clearSuperset: true);
    _setState(state!.copyWith(exercises: exercises));
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    if (newIndex > oldIndex) newIndex--;
    final item = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, item);
    _setState(state!.copyWith(exercises: exercises));
  }

  void cancel() => _setState(null);

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _updateSet(int ei, int si, ActiveSet Function(ActiveSet) fn) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final ex = exercises[ei];
    final sets = [...ex.sets];
    sets[si] = fn(sets[si]);
    exercises[ei] = ex.copyWith(sets: sets);
    _setState(state!.copyWith(exercises: exercises));
  }

  void _setState(ActiveWorkoutState? next) {
    state = next;
    _draftWrite = _draftWrite.then<void>(
      (_) => _persistDraft(next),
      onError: (_, __) => _persistDraft(next),
    );
  }

  Future<void> _persistDraft(ActiveWorkoutState? draft) => draft == null
      ? HiveService.clearActiveWorkoutDraft()
      : HiveService.saveActiveWorkoutDraft(draft);

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
