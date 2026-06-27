import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_service.dart';
import '../models/routine.dart';

class RoutinesNotifier extends Notifier<List<Routine>> {
  @override
  List<Routine> build() => _load();

  List<Routine> _load() {
    final list = HiveService.routines.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> save(Routine routine) async {
    await HiveService.routines.put(routine.id, routine);
    state = _load();
  }

  Future<void> create({
    required String name,
    required List<RoutineExercise> exercises,
  }) async {
    final routine = Routine(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      exercises: exercises,
    );
    await HiveService.routines.put(routine.id, routine);
    state = _load();
  }

  Future<void> delete(String id) async {
    await HiveService.routines.delete(id);
    state = _load();
  }

  void refresh() => state = _load();
}

final routinesProvider = NotifierProvider<RoutinesNotifier, List<Routine>>(
  RoutinesNotifier.new,
);
