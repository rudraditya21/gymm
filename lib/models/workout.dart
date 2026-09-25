import 'package:hive_flutter/hive_flutter.dart';

class WorkoutSet {
  final double? weight;
  final int? reps;
  final bool isCompleted;
  final bool isWarmup;
  final bool isDropSet;
  final bool isAmrap;
  final int? durationSeconds;
  final double? distanceMeters;

  const WorkoutSet({
    this.weight,
    this.reps,
    this.isCompleted = false,
    this.isWarmup = false,
    this.isDropSet = false,
    this.isAmrap = false,
    this.durationSeconds,
    this.distanceMeters,
  });
}

class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final List<WorkoutSet> sets;

  const WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });
}

class Workout {
  final String id;
  final String name;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<WorkoutExercise> exercises;
  final String? notes;

  const Workout({
    required this.id,
    required this.name,
    required this.startedAt,
    this.finishedAt,
    required this.exercises,
    this.notes,
  });

  Duration get duration =>
      finishedAt != null ? finishedAt!.difference(startedAt) : Duration.zero;

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

// ── Adapters ─────────────────────────────────────────────────────────────────

class WorkoutSetAdapter extends TypeAdapter<WorkoutSet> {
  @override
  final int typeId = 3;

  @override
  WorkoutSet read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return WorkoutSet(
      weight: fields[0] as double?,
      reps: fields[1] as int?,
      isCompleted: fields[2] as bool? ?? false,
      isWarmup: fields[3] as bool? ?? false,
      isDropSet: fields[5] as bool? ?? false,
      isAmrap: fields[6] as bool? ?? false,
      durationSeconds: fields[7] as int?,
      distanceMeters: (fields[8] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSet obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.weight)
      ..writeByte(1)
      ..write(obj.reps)
      ..writeByte(2)
      ..write(obj.isCompleted)
      ..writeByte(3)
      ..write(obj.isWarmup)
      ..writeByte(5)
      ..write(obj.isDropSet)
      ..writeByte(6)
      ..write(obj.isAmrap)
      ..writeByte(7)
      ..write(obj.durationSeconds)
      ..writeByte(8)
      ..write(obj.distanceMeters);
  }
}

class WorkoutExerciseAdapter extends TypeAdapter<WorkoutExercise> {
  @override
  final int typeId = 2;

  @override
  WorkoutExercise read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return WorkoutExercise(
      exerciseId: fields[0] as String,
      exerciseName: fields[1] as String,
      sets: (fields[2] as List).cast<WorkoutSet>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutExercise obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.sets);
  }
}

class WorkoutAdapter extends TypeAdapter<Workout> {
  @override
  final int typeId = 1;

  @override
  Workout read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Workout(
      id: fields[0] as String,
      name: fields[1] as String,
      startedAt: fields[2] as DateTime,
      finishedAt: fields[3] as DateTime?,
      exercises: (fields[4] as List).cast<WorkoutExercise>(),
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.startedAt)
      ..writeByte(3)
      ..write(obj.finishedAt)
      ..writeByte(4)
      ..write(obj.exercises)
      ..writeByte(5)
      ..write(obj.notes);
  }
}
