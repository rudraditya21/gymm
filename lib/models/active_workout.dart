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
  // Cardio fields
  final int? durationSeconds;
  final double? distanceMeters;

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
    this.durationSeconds,
    this.distanceMeters,
  });

  SetType get setType {
    if (isWarmup) return SetType.warmup;
    if (isDropSet) return SetType.dropSet;
    if (isAmrap) return SetType.amrap;
    return SetType.normal;
  }

  bool get isWorkingSet => isCompleted && !isWarmup;

  ActiveSet copyWith({
    bool? isWarmup,
    bool? isCompleted,
    bool? isDropSet,
    bool? isAmrap,
    double? weight,
    int? reps,
    int? durationSeconds,
    double? distanceMeters,
    bool clearWeight = false,
    bool clearReps = false,
    bool clearDuration = false,
    bool clearDistance = false,
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
      durationSeconds: clearDuration ? null : (durationSeconds ?? this.durationSeconds),
      distanceMeters: clearDistance ? null : (distanceMeters ?? this.distanceMeters),
    );
  }
}

class ActiveExercise {
  final String exerciseId;
  final String exerciseName;
  final List<ActiveSet> sets;
  final String? supersetGroupId;

  const ActiveExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.supersetGroupId,
  });

  ActiveExercise copyWith({
    List<ActiveSet>? sets,
    String? supersetGroupId,
    bool clearSuperset = false,
  }) =>
      ActiveExercise(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        sets: sets ?? this.sets,
        supersetGroupId:
            clearSuperset ? null : (supersetGroupId ?? this.supersetGroupId),
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
                .where((s) => s.isWorkingSet)
                .fold(0.0, (eSum, s) => eSum + (s.weight ?? 0) * (s.reps ?? 0)),
      );

  int get completedSetsCount =>
      exercises.fold(0, (sum, e) => sum + e.sets.where((s) => s.isCompleted).length);

  Map<String, dynamic> toStorageMap() => {
        'id': id,
        'name': name,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'notes': notes,
        'exercises': exercises
            .map(
              (exercise) => {
                'exerciseId': exercise.exerciseId,
                'exerciseName': exercise.exerciseName,
                'supersetGroupId': exercise.supersetGroupId,
                'sets': exercise.sets
                    .map(
                      (set) => {
                        'index': set.index,
                        'isWarmup': set.isWarmup,
                        'isCompleted': set.isCompleted,
                        'isDropSet': set.isDropSet,
                        'isAmrap': set.isAmrap,
                        'weight': set.weight,
                        'reps': set.reps,
                        'prevWeight': set.prevWeight,
                        'prevReps': set.prevReps,
                        'durationSeconds': set.durationSeconds,
                        'distanceMeters': set.distanceMeters,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      };

  static ActiveWorkoutState fromStorageMap(Map<dynamic, dynamic> map) {
    ActiveSet setFromMap(Map<dynamic, dynamic> set) => ActiveSet(
          index: set['index'] as int,
          isWarmup: set['isWarmup'] as bool? ?? false,
          isCompleted: set['isCompleted'] as bool? ?? false,
          isDropSet: set['isDropSet'] as bool? ?? false,
          isAmrap: set['isAmrap'] as bool? ?? false,
          weight: (set['weight'] as num?)?.toDouble(),
          reps: set['reps'] as int?,
          prevWeight: (set['prevWeight'] as num?)?.toDouble(),
          prevReps: set['prevReps'] as int?,
          durationSeconds: set['durationSeconds'] as int?,
          distanceMeters: (set['distanceMeters'] as num?)?.toDouble(),
        );

    ActiveExercise exerciseFromMap(Map<dynamic, dynamic> exercise) =>
        ActiveExercise(
          exerciseId: exercise['exerciseId'] as String,
          exerciseName: exercise['exerciseName'] as String,
          supersetGroupId: exercise['supersetGroupId'] as String?,
          sets: (exercise['sets'] as List<dynamic>)
              .map((set) => setFromMap(set as Map<dynamic, dynamic>))
              .toList(),
        );

    return ActiveWorkoutState(
      id: map['id'] as String,
      name: map['name'] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['startedAt'] as int),
      notes: map['notes'] as String? ?? '',
      exercises: (map['exercises'] as List<dynamic>)
          .map((exercise) => exerciseFromMap(exercise as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}
