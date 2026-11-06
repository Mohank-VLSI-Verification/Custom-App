import 'package:intl/intl.dart';

/// 556 -> "9h 16m"
String fmtMinutes(int minutes) {
  final m = minutes < 0 ? 0 : minutes;
  return '${m ~/ 60}h ${m % 60}m';
}

String fmtClock(DateTime t) => DateFormat('h:mm a').format(t);

String fmtRange(DateTime a, DateTime b) => '${fmtClock(a)} – ${fmtClock(b)}';

/// "Thu, Nov 5"
String fmtDay(DateTime d) => DateFormat('EEE, MMM d').format(d);

/// "THU, NOV 5"
String fmtDayHeader(DateTime d) => fmtDay(d).toUpperCase();

/// "Nov 1"
String fmtMonthDay(DateTime d) => DateFormat('MMM d').format(d);

/// "Sun, Nov 1, 2026"
String fmtLongDate(DateTime d) => DateFormat('EEE, MMM d, yyyy').format(d);

String fmtRoundOption(int m) => m == 0 ? 'No rounding' : '$m min';

String fmtBreakOption(int m) => m == 0 ? 'None' : '$m min';
