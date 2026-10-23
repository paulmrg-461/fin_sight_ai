/// Calendar date stored as UTC noon so date parts are stable across zones.
DateTime calendarDate(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day, 12);

/// Calendar month stored as UTC noon on the first day.
DateTime calendarMonth(DateTime value) =>
    DateTime.utc(value.year, value.month, 1, 12);

/// True when the value already uses the UTC-noon convention (for tests).
bool isCalendarDate(DateTime value) =>
    value.isUtc && value.hour == 12 && value.minute == 0;
