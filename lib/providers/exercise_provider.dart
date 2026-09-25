import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_service.dart';
import '../models/exercise.dart';

enum ExerciseDeletionResult { deleted, referencedByHistory }

class ExercisesNotifier extends Notifier<List<Exercise>> {
  @override
  List<Exercise> build() => _load();

  List<Exercise> _load() {
    final list = HiveService.exercises.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> addCustom({
    required String name,
    required String primaryMuscle,
    required List<String> secondaryMuscles,
    required String equipment,
  }) async {
    final ex = Exercise(
      id: const Uuid().v4(),
      name: name,
      primaryMuscle: primaryMuscle,
      secondaryMuscles: secondaryMuscles,
      equipment: equipment,
      isCustom: true,
    );
    await HiveService.exercises.put(ex.id, ex);
    state = _load();
  }

  Future<ExerciseDeletionResult> delete(String id) async {
    final isReferencedByHistory = HiveService.workouts.values.any(
      (workout) => workout.exercises.any((exercise) => exercise.exerciseId == id),
    );
    if (isReferencedByHistory) {
      return ExerciseDeletionResult.referencedByHistory;
    }

    await HiveService.exercises.delete(id);
    state = _load();
    return ExerciseDeletionResult.deleted;
  }

  void refresh() => state = _load();
}

final exercisesProvider = NotifierProvider<ExercisesNotifier, List<Exercise>>(
  ExercisesNotifier.new,
);

// Derived read-only provider for search + filter
final exerciseFilterProvider = StateProvider<String?>((ref) => null);
final exerciseSearchProvider = StateProvider<String>((ref) => '');

final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final all = ref.watch(exercisesProvider);
  final filter = ref.watch(exerciseFilterProvider);
  final search = ref.watch(exerciseSearchProvider).toLowerCase().trim();

  return all.where((ex) {
    final matchesMuscle = filter == null || ex.primaryMuscle == filter;
    final matchesSearch = search.isEmpty ||
        ex.name.toLowerCase().contains(search) ||
        ex.primaryMuscle.toLowerCase().contains(search);
    return matchesMuscle && matchesSearch;
  }).toList();
});
