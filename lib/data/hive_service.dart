import 'package:hive_flutter/hive_flutter.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/routine.dart';
import '../constants/exercises.dart';

abstract final class HiveService {
  static const _exercises = 'exercises';
  static const _workouts = 'workouts';
  static const _routines = 'routines';
  static const _settings = 'settings';
  static const _seeded = 'seeded';

  static Box<Exercise> get exercises => Hive.box<Exercise>(_exercises);
  static Box<Workout> get workouts => Hive.box<Workout>(_workouts);
  static Box<Routine> get routines => Hive.box<Routine>(_routines);
  static Box<dynamic> get settings => Hive.box<dynamic>(_settings);

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive
      ..registerAdapter(ExerciseAdapter())
      ..registerAdapter(WorkoutAdapter())
      ..registerAdapter(WorkoutExerciseAdapter())
      ..registerAdapter(WorkoutSetAdapter())
      ..registerAdapter(RoutineAdapter())
      ..registerAdapter(RoutineExerciseAdapter())
      ..registerAdapter(RoutineSetAdapter());

    await Future.wait([
      Hive.openBox<Exercise>(_exercises),
      Hive.openBox<Workout>(_workouts),
      Hive.openBox<Routine>(_routines),
      Hive.openBox<dynamic>(_settings),
    ]);

    await _seedIfNeeded();
  }

  static Future<void> _seedIfNeeded() async {
    final box = settings;
    if (box.get(_seeded, defaultValue: false) as bool) return;

    final exerciseBox = exercises;
    for (final ex in kSeedExercises) {
      await exerciseBox.put(ex.id, ex);
    }

    await box.put(_seeded, true);
  }
}
