import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_service.dart';
import '../models/workout.dart';

class HistoryNotifier extends Notifier<List<Workout>> {
  @override
  List<Workout> build() => _load();

  List<Workout> _load() {
    final list = HiveService.workouts.values.toList();
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }

  void refresh() => state = _load();

  Future<void> delete(String id) async {
    await HiveService.workouts.delete(id);
    state = _load();
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<Workout>>(
  HistoryNotifier.new,
);

// Single workout lookup
final workoutByIdProvider = Provider.family<Workout?, String>((ref, id) {
  final history = ref.watch(historyProvider);
  try {
    return history.firstWhere((w) => w.id == id);
  } catch (_) {
    return null;
  }
});
