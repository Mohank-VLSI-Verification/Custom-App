/// Local midnight of [d]. Also converts table_calendar's UTC days to local.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime today() => dateOnly(DateTime.now());

/// Calendar days from [a] to [b] (DST-safe).
int daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Weeks start on Sunday.
DateTime startOfWeek(DateTime d) {
  final x = dateOnly(d);
  return addDays(x, -(x.weekday % 7));
}

int _floorDiv(int a, int b) => (a - (a % b)) ~/ b;

class Period {
  final DateTime start; // first day
  final DateTime end; // last day (inclusive)
  const Period(this.start, this.end);
}

/// Index of the 14-day pay period containing [day], counted from [anchor].
int periodIndexFor(DateTime anchor, DateTime day) =>
    _floorDiv(daysBetween(anchor, day), 14);

Period periodBounds(DateTime anchor, int index) {
  final s = addDays(dateOnly(anchor), index * 14);
  return Period(s, addDays(s, 13));
}

/// True if [day] falls on the bi-weekly payday cycle set by [anchor].
bool isPayday(DateTime? anchor, DateTime day) =>
    anchor != null && daysBetween(anchor, day) % 14 == 0;

int roundToStep(int minutes, int step) =>
    step <= 0 ? minutes : (minutes / step).round() * step;
