DateTime startOfWeek(DateTime date) {
  final startOfDay = DateTime(date.year, date.month, date.day);
  return DateTime(
    startOfDay.year,
    startOfDay.month,
    startOfDay.day - startOfDay.weekday + 1,
  );
}

DateTime addCalendarDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

bool isWithinDateRange(DateTime value, DateTime start, DateTime end) =>
    !value.isBefore(start) && value.isBefore(end);
