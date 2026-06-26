import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_service.dart';
import '../models/measurement_entry.dart';

class MeasurementNotifier extends Notifier<List<MeasurementEntry>> {
  @override
  List<MeasurementEntry> build() =>
      HiveService.measurements.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<MeasurementEntry> forPart(String bodyPart) =>
      state.where((e) => e.bodyPart == bodyPart).toList();

  Future<void> add(String bodyPart, DateTime date, double valueCm) async {
    final key = _key(bodyPart, date);
    await HiveService.measurements.put(
      key,
      MeasurementEntry(
        date: _normalize(date),
        bodyPart: bodyPart,
        valueCm: valueCm,
      ),
    );
    _reload();
  }

  Future<void> remove(String bodyPart, DateTime date) async {
    await HiveService.measurements.delete(_key(bodyPart, date));
    _reload();
  }

  void _reload() {
    state = HiveService.measurements.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  static String _key(String part, DateTime d) {
    final n = _normalize(d);
    return '${part}_${n.year}-${n.month}-${n.day}';
  }

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}

final measurementProvider =
    NotifierProvider<MeasurementNotifier, List<MeasurementEntry>>(
  MeasurementNotifier.new,
);
