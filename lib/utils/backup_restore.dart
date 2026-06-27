import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/hive_service.dart';
import '../models/body_weight_entry.dart';
import '../models/exercise.dart';
import '../models/measurement_entry.dart';
import '../models/routine.dart';
import '../models/workout.dart';

// ── Export ────────────────────────────────────────────────────────────────────

Future<void> exportBackup() async {
  final data = {
    'version': 2,
    'workouts': HiveService.workouts.values.map(_workoutToJson).toList(),
    'routines': HiveService.routines.values.map(_routineToJson).toList(),
    'bodyWeight': HiveService.bodyWeight.values.map(_bwToJson).toList(),
    'customExercises': HiveService.exercises.values
        .where((e) => e.isCustom)
        .map(_exerciseToJson)
        .toList(),
    'measurements':
        HiveService.measurements.values.map(_measurementToJson).toList(),
    'settings': {
      'useKg': HiveService.settings.get('useKg', defaultValue: true),
      'useCm': HiveService.settings.get('useCm', defaultValue: true),
      'restSeconds':
          HiveService.settings.get('restSeconds', defaultValue: 90),
      'autoStartRest':
          HiveService.settings.get('autoStartRest', defaultValue: true),
    },
  };

  final json = const JsonEncoder.withIndent('  ').convert(data);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/gymm_backup.json');
  await file.writeAsString(json);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/json')],
    subject: 'Gymm backup',
  );
}

// ── Import ────────────────────────────────────────────────────────────────────

class ImportResult {
  final int workouts;
  final int routines;
  final int exercises;
  final int measurements;

  const ImportResult({
    required this.workouts,
    required this.routines,
    required this.exercises,
    required this.measurements,
  });

  @override
  String toString() =>
      'Imported $workouts workouts, $routines routines, '
      '$exercises exercises, $measurements measurements';
}

/// Returns null on cancel, throws on parse/IO error.
Future<ImportResult?> importBackup() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;

  final bytes = result.files.first.bytes;
  if (bytes == null) return null;

  final raw = utf8.decode(bytes);
  final data = jsonDecode(raw) as Map<String, dynamic>;

  // Workouts
  final workoutsRaw = data['workouts'] as List<dynamic>? ?? [];
  for (final w in workoutsRaw) {
    final workout = _workoutFromJson(w as Map<String, dynamic>);
    await HiveService.workouts.put(workout.id, workout);
  }

  // Routines
  final routinesRaw = data['routines'] as List<dynamic>? ?? [];
  for (final r in routinesRaw) {
    final routine = _routineFromJson(r as Map<String, dynamic>);
    await HiveService.routines.put(routine.id, routine);
  }

  // Body weight
  final bwRaw = data['bodyWeight'] as List<dynamic>? ?? [];
  for (final e in bwRaw) {
    final entry = _bwFromJson(e as Map<String, dynamic>);
    final key =
        '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
    await HiveService.bodyWeight.put(key, entry);
  }

  // Custom exercises
  final exRaw = data['customExercises'] as List<dynamic>? ?? [];
  for (final e in exRaw) {
    final ex = _exerciseFromJson(e as Map<String, dynamic>);
    await HiveService.exercises.put(ex.id, ex);
  }

  // Measurements
  final mRaw = data['measurements'] as List<dynamic>? ?? [];
  for (final m in mRaw) {
    final entry = _measurementFromJson(m as Map<String, dynamic>);
    final key =
        '${entry.bodyPart}_${entry.date.year}-${entry.date.month}-${entry.date.day}';
    await HiveService.measurements.put(key, entry);
  }

  // Settings
  final settings = data['settings'] as Map<String, dynamic>?;
  if (settings != null) {
    if (settings['useKg'] != null) {
      await HiveService.settings.put('useKg', settings['useKg']);
    }
    if (settings['useCm'] != null) {
      await HiveService.settings.put('useCm', settings['useCm']);
    }
    if (settings['restSeconds'] != null) {
      await HiveService.settings.put('restSeconds', settings['restSeconds']);
    }
    if (settings['autoStartRest'] != null) {
      await HiveService.settings.put('autoStartRest', settings['autoStartRest']);
    }
  }

  return ImportResult(
    workouts: workoutsRaw.length,
    routines: routinesRaw.length,
    exercises: exRaw.length,
    measurements: mRaw.length,
  );
}

// ── Serialisation helpers ─────────────────────────────────────────────────────

Map<String, dynamic> _workoutToJson(Workout w) => {
      'id': w.id,
      'name': w.name,
      'startedAt': w.startedAt.millisecondsSinceEpoch,
      'finishedAt': w.finishedAt?.millisecondsSinceEpoch,
      'notes': w.notes,
      'exercises': w.exercises.map(_weToJson).toList(),
    };

Map<String, dynamic> _weToJson(WorkoutExercise e) => {
      'exerciseId': e.exerciseId,
      'exerciseName': e.exerciseName,
      'sets': e.sets.map(_wsToJson).toList(),
    };

Map<String, dynamic> _wsToJson(WorkoutSet s) => {
      'weight': s.weight,
      'reps': s.reps,
      'isCompleted': s.isCompleted,
      'isWarmup': s.isWarmup,
      'isDropSet': s.isDropSet,
      'isAmrap': s.isAmrap,
      'durationSeconds': s.durationSeconds,
      'distanceMeters': s.distanceMeters,
    };

Workout _workoutFromJson(Map<String, dynamic> m) => Workout(
      id: m['id'] as String,
      name: m['name'] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(m['startedAt'] as int),
      finishedAt: m['finishedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['finishedAt'] as int)
          : null,
      notes: m['notes'] as String?,
      exercises: (m['exercises'] as List<dynamic>)
          .map((e) => _weFromJson(e as Map<String, dynamic>))
          .toList(),
    );

WorkoutExercise _weFromJson(Map<String, dynamic> m) => WorkoutExercise(
      exerciseId: m['exerciseId'] as String,
      exerciseName: m['exerciseName'] as String,
      sets: (m['sets'] as List<dynamic>)
          .map((s) => _wsFromJson(s as Map<String, dynamic>))
          .toList(),
    );

WorkoutSet _wsFromJson(Map<String, dynamic> m) => WorkoutSet(
      weight: (m['weight'] as num?)?.toDouble(),
      reps: m['reps'] as int?,
      isCompleted: m['isCompleted'] as bool? ?? false,
      isWarmup: m['isWarmup'] as bool? ?? false,
      isDropSet: m['isDropSet'] as bool? ?? false,
      isAmrap: m['isAmrap'] as bool? ?? false,
      durationSeconds: m['durationSeconds'] as int?,
      distanceMeters: (m['distanceMeters'] as num?)?.toDouble(),
    );

Map<String, dynamic> _routineToJson(Routine r) => {
      'id': r.id,
      'name': r.name,
      'createdAt': r.createdAt.millisecondsSinceEpoch,
      'exercises': r.exercises.map(_reToJson).toList(),
    };

Map<String, dynamic> _reToJson(RoutineExercise e) => {
      'exerciseId': e.exerciseId,
      'exerciseName': e.exerciseName,
      'sets': e.sets
          .map((s) => {
                'weightTarget': s.weightTarget,
                'repsTarget': s.repsTarget,
              })
          .toList(),
    };

Routine _routineFromJson(Map<String, dynamic> m) => Routine(
      id: m['id'] as String,
      name: m['name'] as String,
      createdAt: m['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int)
          : DateTime.now(),
      exercises: (m['exercises'] as List<dynamic>)
          .map((e) => _reFromJson(e as Map<String, dynamic>))
          .toList(),
    );

RoutineExercise _reFromJson(Map<String, dynamic> m) => RoutineExercise(
      exerciseId: m['exerciseId'] as String,
      exerciseName: m['exerciseName'] as String,
      sets: (m['sets'] as List<dynamic>)
          .map((s) => RoutineSet(
                weightTarget: (s['weightTarget'] as num?)?.toDouble(),
                repsTarget: s['repsTarget'] as int?,
              ))
          .toList(),
    );

Map<String, dynamic> _bwToJson(BodyWeightEntry e) => {
      'date': e.date.millisecondsSinceEpoch,
      'weight': e.weight,
    };

BodyWeightEntry _bwFromJson(Map<String, dynamic> m) => BodyWeightEntry(
      date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
      weight: (m['weight'] as num).toDouble(),
    );

Map<String, dynamic> _exerciseToJson(Exercise e) => {
      'id': e.id,
      'name': e.name,
      'primaryMuscle': e.primaryMuscle,
      'secondaryMuscles': e.secondaryMuscles,
      'equipment': e.equipment,
    };

Exercise _exerciseFromJson(Map<String, dynamic> m) => Exercise(
      id: m['id'] as String,
      name: m['name'] as String,
      primaryMuscle: m['primaryMuscle'] as String,
      secondaryMuscles:
          (m['secondaryMuscles'] as List<dynamic>).cast<String>(),
      equipment: m['equipment'] as String,
      isCustom: true,
    );

Map<String, dynamic> _measurementToJson(MeasurementEntry e) => {
      'date': e.date.millisecondsSinceEpoch,
      'bodyPart': e.bodyPart,
      'valueCm': e.valueCm,
    };

MeasurementEntry _measurementFromJson(Map<String, dynamic> m) =>
    MeasurementEntry(
      date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
      bodyPart: m['bodyPart'] as String,
      valueCm: (m['valueCm'] as num).toDouble(),
    );
