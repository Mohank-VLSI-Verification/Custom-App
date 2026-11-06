import '../utils/time_utils.dart';

class Settings {
  /// First day of any bi-weekly pay period (periods repeat every 14 days).
  final DateTime payPeriodStart;

  /// Round each shift to the nearest N minutes. 0 = no rounding.
  final int roundMinutes;

  /// Unpaid break taken off every workday, in minutes.
  final int breakMinutes;

  /// Any one payday. Paydays repeat every 14 days from it. Null = not set.
  final DateTime? paydayAnchor;

  const Settings({
    required this.payPeriodStart,
    required this.roundMinutes,
    required this.breakMinutes,
    this.paydayAnchor,
  });

  static Settings defaults() => Settings(
        payPeriodStart: DateTime(2026, 11, 1),
        roundMinutes: 0,
        breakMinutes: 30,
      );

  Settings copyWith({
    DateTime? payPeriodStart,
    int? roundMinutes,
    int? breakMinutes,
    DateTime? paydayAnchor,
    bool clearPayday = false,
  }) =>
      Settings(
        payPeriodStart: payPeriodStart ?? this.payPeriodStart,
        roundMinutes: roundMinutes ?? this.roundMinutes,
        breakMinutes: breakMinutes ?? this.breakMinutes,
        paydayAnchor: clearPayday ? null : (paydayAnchor ?? this.paydayAnchor),
      );

  Map<String, dynamic> toJson() => {
        'payPeriodStart': dateKey(payPeriodStart),
        'roundMinutes': roundMinutes,
        'breakMinutes': breakMinutes,
        'paydayAnchor': paydayAnchor == null ? null : dateKey(paydayAnchor!),
      };

  factory Settings.fromJson(Map<String, dynamic> json) {
    final d = Settings.defaults();
    final start = json['payPeriodStart'] as String?;
    final pay = json['paydayAnchor'] as String?;
    return Settings(
      payPeriodStart: start == null ? d.payPeriodStart : dateOnly(DateTime.parse(start)),
      roundMinutes: (json['roundMinutes'] as num?)?.toInt() ?? d.roundMinutes,
      breakMinutes: (json['breakMinutes'] as num?)?.toInt() ?? d.breakMinutes,
      paydayAnchor: pay == null ? null : dateOnly(DateTime.parse(pay)),
    );
  }
}
