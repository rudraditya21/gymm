import 'package:hive_flutter/hive_flutter.dart';

const kBodyParts = [
  'Neck',
  'Shoulders',
  'Chest',
  'Left Bicep',
  'Right Bicep',
  'Left Forearm',
  'Right Forearm',
  'Waist',
  'Hips',
  'Left Thigh',
  'Right Thigh',
  'Left Calf',
  'Right Calf',
];

class MeasurementEntry {
  final DateTime date;
  final String bodyPart;
  final double valueCm;

  const MeasurementEntry({
    required this.date,
    required this.bodyPart,
    required this.valueCm,
  });
}

class MeasurementEntryAdapter extends TypeAdapter<MeasurementEntry> {
  @override
  final int typeId = 9;

  @override
  MeasurementEntry read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return MeasurementEntry(
      date: DateTime.fromMillisecondsSinceEpoch(fields[0] as int),
      bodyPart: fields[1] as String,
      valueCm: (fields[2] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date.millisecondsSinceEpoch)
      ..writeByte(1)
      ..write(obj.bodyPart)
      ..writeByte(2)
      ..write(obj.valueCm);
  }
}
