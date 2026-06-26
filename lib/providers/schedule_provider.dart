import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_service.dart';
import '../models/scheduled_entry.dart';

class ScheduleNotifier extends Notifier<List<ScheduledEntry>> {
  @override
  List<ScheduledEntry> build() =>
      HiveService.schedule.values.toList();

  Future<void> scheduleRoutine(
      DateTime date, String routineId, String routineName) async {
    final entry = ScheduledEntry(
      date: _normalize(date),
      isRestDay: false,
      routineId: routineId,
      routineName: routineName,
    );
    await HiveService.schedule.put(_key(date), entry);
    state = HiveService.schedule.values.toList();
  }

  Future<void> markRestDay(DateTime date) async {
    final entry = ScheduledEntry(
      date: _normalize(date),
      isRestDay: true,
    );
    await HiveService.schedule.put(_key(date), entry);
    state = HiveService.schedule.values.toList();
  }

  Future<void> remove(DateTime date) async {
    await HiveService.schedule.delete(_key(date));
    state = HiveService.schedule.values.toList();
  }

  // String key avoids Hive's int key limit (max 0xFFFFFFFF).
  static String _key(DateTime d) {
    final n = _normalize(d);
    return '${n.year}-${n.month}-${n.day}';
  }

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}

final scheduleProvider =
    NotifierProvider<ScheduleNotifier, List<ScheduledEntry>>(
  ScheduleNotifier.new,
);
