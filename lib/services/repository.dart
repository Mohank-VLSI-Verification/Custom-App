import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';
import '../models/shift.dart';
import 'ledger.dart';

class Repository extends ChangeNotifier {
  Repository._();

  /// The instance the app UI uses.
  static final Repository instance = Repository._();

  static const _kShifts = 'shifts';
  static const _kSettings = 'settings';
  static const _kActive = 'active_start';

  List<Shift> _shifts = [];
  Settings _settings = Settings.defaults();
  DateTime? _activeStart;
  Ledger _ledger = Ledger.empty;

  /// Newest first.
  List<Shift> get shifts => List.unmodifiable(_shifts);
  Settings get settings => _settings;
  DateTime? get activeStart => _activeStart;
  bool get isClockedIn => _activeStart != null;
  Ledger get ledger => _ledger;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final shifts = <Shift>[];
    final raw = prefs.getString(_kShifts);
    if (raw != null) {
      try {
        for (final e in jsonDecode(raw) as List) {
          shifts.add(Shift.fromJson(Map<String, dynamic>.from(e as Map)));
        }
      } catch (_) {}
    }
    _shifts = shifts;

    final rawSettings = prefs.getString(_kSettings);
    if (rawSettings != null) {
      try {
        _settings = Settings.fromJson(
            Map<String, dynamic>.from(jsonDecode(rawSettings) as Map));
      } catch (_) {
        _settings = Settings.defaults();
      }
    }

    final active = prefs.getString(_kActive);
    _activeStart = active == null ? null : DateTime.tryParse(active);

    _recompute();
    notifyListeners();
  }

  void _recompute() {
    _shifts.sort((a, b) => b.start.compareTo(a.start));
    _ledger = Ledger.build(_shifts, _settings);
  }

  Future<void> _persist() async {
    _recompute();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kShifts, jsonEncode(_shifts.map((s) => s.toJson()).toList()));
    await prefs.setString(_kSettings, jsonEncode(_settings.toJson()));
    if (_activeStart == null) {
      await prefs.remove(_kActive);
    } else {
      await prefs.setString(_kActive, _activeStart!.toIso8601String());
    }
  }

  Future<void> togglePunch() => isClockedIn ? punchOut() : punchIn();

  Future<void> punchIn() async {
    if (isClockedIn) return;
    _activeStart = DateTime.now();
    await _persist();
  }

  Future<void> punchOut() async {
    final start = _activeStart;
    if (start == null) return;
    _shifts.add(Shift(id: Shift.newId(), start: start, end: DateTime.now()));
    _activeStart = null;
    await _persist();
  }

  Future<void> addShift(Shift shift) async {
    _shifts.add(shift);
    await _persist();
  }

  Future<void> updateShift(Shift shift) async {
    final i = _shifts.indexWhere((s) => s.id == shift.id);
    if (i < 0) return;
    _shifts[i] = shift;
    await _persist();
  }

  Future<void> deleteShift(String id) async {
    _shifts.removeWhere((s) => s.id == id);
    await _persist();
  }

  Future<void> updateSettings(Settings settings) async {
    _settings = settings;
    await _persist();
  }
}
