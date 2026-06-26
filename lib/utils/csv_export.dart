import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/hive_service.dart';
import '../models/workout.dart';

Future<void> exportWorkoutsAsCsv() async {
  final workouts = HiveService.workouts.values.toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  final buf = StringBuffer();
  buf.writeln('date,workout_name,duration_min,exercise,set,weight_kg,reps,completed,type');

  for (final w in workouts) {
    final date = _fmtDate(w.startedAt);
    final name = _escape(w.name);
    final dur = w.duration.inMinutes;
    for (final ex in w.exercises) {
      final exName = _escape(ex.exerciseName);
      for (int i = 0; i < ex.sets.length; i++) {
        final s = ex.sets[i];
        final type = _setType(s);
        buf.writeln(
          '$date,$name,$dur,$exName,${i + 1},${s.weight ?? ''},${s.reps ?? ''},${s.isCompleted ? 1 : 0},$type',
        );
      }
    }
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/gymm_export.csv');
  await file.writeAsString(buf.toString());

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv')],
    subject: 'Gymm workout export',
  );
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _escape(String s) {
  if (s.contains(',') || s.contains('"') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

String _setType(WorkoutSet s) {
  if (s.isWarmup) return 'warmup';
  if (s.isDropSet) return 'drop';
  if (s.isAmrap) return 'amrap';
  return 'normal';
}
