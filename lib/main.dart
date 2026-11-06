import 'package:flutter/material.dart';

import 'screens/root_screen.dart';
import 'services/repository.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Repository.instance.load();
  runApp(const ShiftTrackerApp());
}

class ShiftTrackerApp extends StatelessWidget {
  const ShiftTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shift Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const RootScreen(),
    );
  }
}
