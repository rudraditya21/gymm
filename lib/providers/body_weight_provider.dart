import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_service.dart';
import '../models/body_weight_entry.dart';

class BodyWeightNotifier extends Notifier<List<BodyWeightEntry>> {
  @override
  List<BodyWeightEntry> build() => _sorted();

  Future<void> add(DateTime date, double weight) async {
    final key = _dateKey(date);
    await HiveService.bodyWeight.put(key, BodyWeightEntry(date: date, weight: weight));
    state = _sorted();
  }

  Future<void> remove(DateTime date) async {
    await HiveService.bodyWeight.delete(_dateKey(date));
    state = _sorted();
  }

  List<BodyWeightEntry> _sorted() {
    final entries = HiveService.bodyWeight.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final bodyWeightProvider =
    NotifierProvider<BodyWeightNotifier, List<BodyWeightEntry>>(
  BodyWeightNotifier.new,
);
