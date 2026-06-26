import 'package:hive_flutter/hive_flutter.dart';

class BodyWeightEntry {
  final DateTime date;
  final double weight;

  const BodyWeightEntry({required this.date, required this.weight});
}

class BodyWeightEntryAdapter extends TypeAdapter<BodyWeightEntry> {
  @override
  final int typeId = 7;

  @override
  BodyWeightEntry read(BinaryReader reader) {
    return BodyWeightEntry(
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      weight: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, BodyWeightEntry obj) {
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeDouble(obj.weight);
  }
}
