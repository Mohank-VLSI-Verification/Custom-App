class Shift {
  final String id;
  final DateTime start;
  final DateTime end;
  final String note;

  const Shift({
    required this.id,
    required this.start,
    required this.end,
    this.note = '',
  });

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Whole minutes between the punch-in and punch-out minutes shown on
  /// screen. Seconds are ignored so 6:20 AM – 4:06 PM is exactly 9h 46m.
  int get workedMinutes {
    final s = DateTime(start.year, start.month, start.day, start.hour, start.minute);
    final e = DateTime(end.year, end.month, end.day, end.hour, end.minute);
    final m = e.difference(s).inMinutes;
    return m < 0 ? 0 : m;
  }

  Shift copyWith({DateTime? start, DateTime? end, String? note}) => Shift(
        id: id,
        start: start ?? this.start,
        end: end ?? this.end,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'note': note,
      };

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: json['id'] as String,
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
        note: (json['note'] as String?) ?? '',
      );
}
