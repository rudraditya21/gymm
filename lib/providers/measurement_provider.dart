import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_service.dart';
import '../models/measurement_entry.dart';
import '../utils/date_range.dart';

class MeasurementNotifier extends Notifier<List<MeasurementEntry>> {
  @override
  List<MeasurementEntry> build() =>
      HiveService.measurements.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<MeasurementEntry> forPart(String bodyPart) =>
      state.where((e) => e.bodyPart == bodyPart).toList();

  Future<void> add(String bodyPart, DateTime date, double valueCm) async {
    final localDate = startOfLocalDay(date);
    final key = _key(bodyPart, localDate);
    await HiveService.measurements.put(
      key,
      MeasurementEntry(
        date: localDate,
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

  void refresh() => _reload();

  static String _key(String part, DateTime d) {
    return '${part}_${localDateKey(d)}';
  }
}

final measurementProvider =
    NotifierProvider<MeasurementNotifier, List<MeasurementEntry>>(
  MeasurementNotifier.new,
);
