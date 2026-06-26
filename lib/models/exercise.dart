import 'package:hive_flutter/hive_flutter.dart';

class Exercise {
  final String id;
  final String name;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final String equipment;
  final bool isCustom;

  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.secondaryMuscles,
    required this.equipment,
    required this.isCustom,
  });
}

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 0;

  @override
  Exercise read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Exercise(
      id: fields[0] as String,
      name: fields[1] as String,
      primaryMuscle: fields[2] as String,
      secondaryMuscles: (fields[3] as List).cast<String>(),
      equipment: fields[4] as String,
      isCustom: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.primaryMuscle)
      ..writeByte(3)
      ..write(obj.secondaryMuscles)
      ..writeByte(4)
      ..write(obj.equipment)
      ..writeByte(5)
      ..write(obj.isCustom);
  }
}
