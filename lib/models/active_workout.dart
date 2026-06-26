enum SetType { normal, warmup, dropSet, amrap }

class ActiveSet {
  final int index;
  final bool isWarmup;
  final bool isCompleted;
  final bool isDropSet;
  final bool isAmrap;
  final double? weight;
  final int? reps;
  final double? prevWeight;
  final int? prevReps;

  const ActiveSet({
    required this.index,
    this.isWarmup = false,
    this.isCompleted = false,
    this.isDropSet = false,
    this.isAmrap = false,
    this.weight,
    this.reps,
    this.prevWeight,
    this.prevReps,
  });

  SetType get setType {
    if (isWarmup) return SetType.warmup;
    if (isDropSet) return SetType.dropSet;
    if (isAmrap) return SetType.amrap;
    return SetType.normal;
  }

  ActiveSet copyWith({
    bool? isWarmup,
    bool? isCompleted,
    bool? isDropSet,
    bool? isAmrap,
    double? weight,
    int? reps,
    bool clearWeight = false,
    bool clearReps = false,
  }) {
    return ActiveSet(
      index: index,
      isWarmup: isWarmup ?? this.isWarmup,
      isCompleted: isCompleted ?? this.isCompleted,
      isDropSet: isDropSet ?? this.isDropSet,
      isAmrap: isAmrap ?? this.isAmrap,
      weight: clearWeight ? null : (weight ?? this.weight),
      reps: clearReps ? null : (reps ?? this.reps),
      prevWeight: prevWeight,
      prevReps: prevReps,
    );
  }
}

class ActiveExercise {
  final String exerciseId;
  final String exerciseName;
  final List<ActiveSet> sets;

  const ActiveExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  ActiveExercise copyWith({List<ActiveSet>? sets}) => ActiveExercise(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        sets: sets ?? this.sets,
      );
}

class ActiveWorkoutState {
  final String id;
  final String name;
  final DateTime startedAt;
  final List<ActiveExercise> exercises;
  final String notes;

  const ActiveWorkoutState({
    required this.id,
    required this.name,
    required this.startedAt,
    required this.exercises,
    this.notes = '',
  });

  ActiveWorkoutState copyWith({
    String? name,
    List<ActiveExercise>? exercises,
    String? notes,
  }) =>
      ActiveWorkoutState(
        id: id,
        name: name ?? this.name,
        startedAt: startedAt,
        exercises: exercises ?? this.exercises,
        notes: notes ?? this.notes,
      );

  double get totalVolume => exercises.fold(
        0.0,
        (sum, e) =>
            sum +
            e.sets
                .where((s) => s.isCompleted)
                .fold(0.0, (eSum, s) => eSum + (s.weight ?? 0) * (s.reps ?? 0)),
      );

  int get completedSetsCount =>
      exercises.fold(0, (sum, e) => sum + e.sets.where((s) => s.isCompleted).length);
}
