import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_service.dart';
import '../models/scheduled_entry.dart';
import '../utils/date_range.dart';

class ScheduleNotifier extends Notifier<List<ScheduledEntry>> {
  @override
  List<ScheduledEntry> build() =>
      HiveService.schedule.values.toList();

  Future<void> scheduleRoutine(
      DateTime date, String routineId, String routineName) async {
    final entry = ScheduledEntry(
      date: startOfLocalDay(date),
      isRestDay: false,
      routineId: routineId,
      routineName: routineName,
    );
    await HiveService.schedule.put(localDateKey(date), entry);
    state = HiveService.schedule.values.toList();
  }

  Future<void> markRestDay(DateTime date) async {
    final entry = ScheduledEntry(
      date: startOfLocalDay(date),
      isRestDay: true,
    );
    await HiveService.schedule.put(localDateKey(date), entry);
    state = HiveService.schedule.values.toList();
  }

  Future<void> remove(DateTime date) async {
    await HiveService.schedule.delete(localDateKey(date));
    state = HiveService.schedule.values.toList();
  }

  Future<void> removeForRoutine(String routineId) async {
    final keys = HiveService.schedule.keys
        .where((key) => HiveService.schedule.get(key)?.routineId == routineId)
        .toList();
    await HiveService.schedule.deleteAll(keys);
    state = HiveService.schedule.values.toList();
  }
}

final scheduleProvider =
    NotifierProvider<ScheduleNotifier, List<ScheduledEntry>>(
  ScheduleNotifier.new,
);
