DateTime startOfLocalDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

String localDateKey(DateTime date) {
  final localDate = startOfLocalDay(date);
  return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
}

DateTime startOfWeek(DateTime date) {
  final startOfDay = startOfLocalDay(date);
  return DateTime(
    startOfDay.year,
    startOfDay.month,
    startOfDay.day - startOfDay.weekday + 1,
  );
}

DateTime addCalendarDays(DateTime date, int days) =>
    startOfLocalDay(DateTime(date.year, date.month, date.day + days));

bool isWithinDateRange(DateTime value, DateTime start, DateTime end) =>
    !value.isBefore(start) && value.isBefore(end);
