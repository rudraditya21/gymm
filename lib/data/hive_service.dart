import 'package:hive_flutter/hive_flutter.dart';

import '../models/active_workout.dart';
import '../models/body_weight_entry.dart';
import '../models/exercise.dart';
import '../models/measurement_entry.dart';
import '../models/scheduled_entry.dart';
import '../models/workout.dart';
import '../models/routine.dart';
import '../constants/exercises.dart';

abstract final class HiveService {
  static const _exercises = 'exercises';
  static const _workouts = 'workouts';
  static const _routines = 'routines';
  static const _settings = 'settings';
  static const _bodyWeight = 'body_weight';
  static const _schedule = 'schedule';
  static const _measurements = 'measurements';
  static const _seeded = 'seeded';
  static const _activeWorkoutDraft = 'active_workout_draft';

  static Box<Exercise> get exercises => Hive.box<Exercise>(_exercises);
  static Box<Workout> get workouts => Hive.box<Workout>(_workouts);
  static Box<Routine> get routines => Hive.box<Routine>(_routines);
  static Box<dynamic> get settings => Hive.box<dynamic>(_settings);
  static Box<BodyWeightEntry> get bodyWeight =>
      Hive.box<BodyWeightEntry>(_bodyWeight);
  static Box<ScheduledEntry> get schedule =>
      Hive.box<ScheduledEntry>(_schedule);
  static Box<MeasurementEntry> get measurements =>
      Hive.box<MeasurementEntry>(_measurements);

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive
      ..registerAdapter(ExerciseAdapter())
      ..registerAdapter(WorkoutAdapter())
      ..registerAdapter(WorkoutExerciseAdapter())
      ..registerAdapter(WorkoutSetAdapter())
      ..registerAdapter(RoutineAdapter())
      ..registerAdapter(RoutineExerciseAdapter())
      ..registerAdapter(RoutineSetAdapter())
      ..registerAdapter(BodyWeightEntryAdapter())
      ..registerAdapter(ScheduledEntryAdapter())
      ..registerAdapter(MeasurementEntryAdapter());

    await Future.wait([
      Hive.openBox<Exercise>(_exercises),
      Hive.openBox<Workout>(_workouts),
      Hive.openBox<Routine>(_routines),
      Hive.openBox<dynamic>(_settings),
      Hive.openBox<BodyWeightEntry>(_bodyWeight),
      Hive.openBox<ScheduledEntry>(_schedule),
      Hive.openBox<MeasurementEntry>(_measurements),
    ]);

    await _seedIfNeeded();
  }

  static DateTime get onboardingDate {
    final ms = settings.get('onboardingDate') as int?;
    if (ms == null) return DateTime.now();
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime(d.year, d.month, d.day);
  }

  static ActiveWorkoutState? get activeWorkoutDraft {
    final value = settings.get(_activeWorkoutDraft);
    if (value is! Map<dynamic, dynamic>) return null;

    try {
      return ActiveWorkoutState.fromStorageMap(value);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveActiveWorkoutDraft(ActiveWorkoutState draft) =>
      settings.put(_activeWorkoutDraft, draft.toStorageMap());

  static Future<void> clearActiveWorkoutDraft() =>
      settings.delete(_activeWorkoutDraft);

  static Future<void> _seedIfNeeded() async {
    final box = settings;

    // Store onboarding date on very first launch.
    if (box.get('onboardingDate') == null) {
      final now = DateTime.now();
      await box.put('onboardingDate',
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch);
    }

    if (box.get(_seeded, defaultValue: false) as bool) return;

    final exerciseBox = exercises;
    for (final ex in kSeedExercises) {
      await exerciseBox.put(ex.id, ex);
    }

    await box.put(_seeded, true);
  }
}
