import 'package:hive_flutter/hive_flutter.dart';

class RoutineSet {
  final double? weightTarget;
  final int? repsTarget;

  const RoutineSet({this.weightTarget, this.repsTarget});
}

class RoutineExercise {
  final String exerciseId;
  final String exerciseName;
  final List<RoutineSet> sets;

  const RoutineExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });
}

class Routine {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<RoutineExercise> exercises;

  const Routine({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.exercises,
  });
}

// ── Adapters ─────────────────────────────────────────────────────────────────

class RoutineSetAdapter extends TypeAdapter<RoutineSet> {
  @override
  final int typeId = 6;

  @override
  RoutineSet read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return RoutineSet(
      weightTarget: fields[0] as double?,
      repsTarget: fields[1] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, RoutineSet obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.weightTarget)
      ..writeByte(1)
      ..write(obj.repsTarget);
  }
}

class RoutineExerciseAdapter extends TypeAdapter<RoutineExercise> {
  @override
  final int typeId = 5;

  @override
  RoutineExercise read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return RoutineExercise(
      exerciseId: fields[0] as String,
      exerciseName: fields[1] as String,
      sets: (fields[2] as List).cast<RoutineSet>(),
    );
  }

  @override
  void write(BinaryWriter writer, RoutineExercise obj) {
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

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 4;

  @override
  Routine read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Routine(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      exercises: (fields[3] as List).cast<RoutineExercise>(),
    );
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.exercises);
  }
}
