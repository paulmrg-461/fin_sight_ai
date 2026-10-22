/// Shared date formatting helpers (no locale dependency).
String formatDisplayDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Returns a new date at the end of the day (23:59:59.999).
DateTime endOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

/// Returns a new date at the start of the day (00:00:00.000).
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);
