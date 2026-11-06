import '../models/settings.dart';
import '../models/shift.dart';
import '../utils/time_utils.dart';

/// Paid minutes per shift and per day.
///
/// Each shift's worked minutes are rounded (if rounding is on). The unpaid
/// break is then taken once per workday, starting from that day's first shift.
/// A shift belongs to the day it started.
class Ledger {
  final Map<String, int> _byShift;
  final Map<DateTime, int> _byDay;

  Ledger._(this._byShift, this._byDay);

  static final Ledger empty = Ledger._(const {}, const {});

  factory Ledger.build(List<Shift> shifts, Settings settings) {
    final groups = <DateTime, List<Shift>>{};
    for (final s in shifts) {
      groups.putIfAbsent(dateOnly(s.start), () => <Shift>[]).add(s);
    }
    final byShift = <String, int>{};
    final byDay = <DateTime, int>{};
    groups.forEach((day, list) {
      list.sort((a, b) => a.start.compareTo(b.start));
      var breakLeft = settings.breakMinutes < 0 ? 0 : settings.breakMinutes;
      var total = 0;
      for (final s in list) {
        final worked = roundToStep(s.workedMinutes, settings.roundMinutes);
        final deduct = worked < breakLeft ? worked : breakLeft;
        breakLeft -= deduct;
        final paid = worked - deduct;
        byShift[s.id] = paid;
        total += paid;
      }
      byDay[day] = total;
    });
    return Ledger._(byShift, byDay);
  }

  int shift(Shift s) => _byShift[s.id] ?? 0;

  int day(DateTime d) => _byDay[dateOnly(d)] ?? 0;

  /// Paid minutes from [first] to [last], both days inclusive.
  int range(DateTime first, DateTime last) {
    var total = 0;
    var d = dateOnly(first);
    final end = dateOnly(last);
    while (!d.isAfter(end)) {
      total += day(d);
      d = addDays(d, 1);
    }
    return total;
  }
}
