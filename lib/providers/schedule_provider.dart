import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_service.dart';
import '../models/scheduled_entry.dart';

class ScheduleNotifier extends Notifier<List<ScheduledEntry>> {
  @override
  List<ScheduledEntry> build() =>
      HiveService.schedule.values.toList();

  Future<void> scheduleRoutine(
      DateTime date, String routineId, String routineName) async {
    final key = _key(date);
    final entry = ScheduledEntry(
      date: _normalize(date),
      isRestDay: false,
      routineId: routineId,
      routineName: routineName,
    );
    await HiveService.schedule.put(key, entry);
    state = HiveService.schedule.values.toList();
  }

  Future<void> markRestDay(DateTime date) async {
    final key = _key(date);
    final entry = ScheduledEntry(
      date: _normalize(date),
      isRestDay: true,
    );
    await HiveService.schedule.put(key, entry);
    state = HiveService.schedule.values.toList();
  }

  Future<void> remove(DateTime date) async {
    await HiveService.schedule.delete(_key(date));
    state = HiveService.schedule.values.toList();
  }

  static int _key(DateTime d) => _normalize(d).millisecondsSinceEpoch;
  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}

final scheduleProvider =
    NotifierProvider<ScheduleNotifier, List<ScheduledEntry>>(
  ScheduleNotifier.new,
);
