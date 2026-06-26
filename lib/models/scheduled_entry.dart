import 'package:hive_flutter/hive_flutter.dart';

class ScheduledEntry {
  final DateTime date;
  final bool isRestDay;
  final String? routineId;
  final String? routineName;

  const ScheduledEntry({
    required this.date,
    required this.isRestDay,
    this.routineId,
    this.routineName,
  });
}

class ScheduledEntryAdapter extends TypeAdapter<ScheduledEntry> {
  @override
  final int typeId = 8;

  @override
  ScheduledEntry read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return ScheduledEntry(
      date: DateTime.fromMillisecondsSinceEpoch(fields[0] as int),
      isRestDay: fields[1] as bool,
      routineId: fields[2] as String?,
      routineName: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduledEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date.millisecondsSinceEpoch)
      ..writeByte(1)
      ..write(obj.isRestDay)
      ..writeByte(2)
      ..write(obj.routineId)
      ..writeByte(3)
      ..write(obj.routineName);
  }
}
