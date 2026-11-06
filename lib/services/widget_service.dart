import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../utils/format.dart';
import 'repository.dart';

class WidgetService {
  static const _androidName = 'ShiftWidgetProvider';

  static Future<void> init() async {
    try {
      await HomeWidget.registerInteractivityCallback(shiftWidgetCallback);
    } catch (e) {
      debugPrint('Widget callback registration failed: $e');
    }
  }

  /// Pushes the current status to the home-screen widget.
  static Future<void> update(Repository repo) async {
    try {
      final clockedIn = repo.isClockedIn;
      final start = repo.activeStart;
      await HomeWidget.saveWidgetData<bool>('clocked_in', clockedIn);
      await HomeWidget.saveWidgetData<String>(
        'status',
        clockedIn && start != null ? 'Clocked in at ${fmtClock(start)}' : 'Clocked out',
      );
      await HomeWidget.saveWidgetData<String>(
        'today',
        'Today: ${fmtMinutes(repo.ledger.day(DateTime.now()))}',
      );
      await HomeWidget.saveWidgetData<String>(
        'action_label',
        clockedIn ? 'Punch Out' : 'Punch In',
      );
      await HomeWidget.updateWidget(androidName: _androidName);
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }
}

/// Runs in the background when the widget's punch button is tapped.
@pragma('vm:entry-point')
Future<void> shiftWidgetCallback(Uri? uri) async {
  if (uri == null || uri.host != 'toggle') return;
  final repo = Repository.background();
  await repo.load();
  await repo.togglePunch();
}
