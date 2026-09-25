import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_service.dart';
import '../models/body_weight_entry.dart';
import '../utils/date_range.dart';

class BodyWeightNotifier extends Notifier<List<BodyWeightEntry>> {
  @override
  List<BodyWeightEntry> build() => _sorted();

  Future<void> add(DateTime date, double weight) async {
    final localDate = startOfLocalDay(date);
    await HiveService.bodyWeight.put(
      localDateKey(localDate),
      BodyWeightEntry(date: localDate, weight: weight),
    );
    state = _sorted();
  }

  Future<void> remove(DateTime date) async {
    await HiveService.bodyWeight.delete(localDateKey(date));
    state = _sorted();
  }

  List<BodyWeightEntry> _sorted() {
    final entries = HiveService.bodyWeight.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  void refresh() => state = _sorted();
}

final bodyWeightProvider =
    NotifierProvider<BodyWeightNotifier, List<BodyWeightEntry>>(
  BodyWeightNotifier.new,
);
