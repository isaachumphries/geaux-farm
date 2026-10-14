import 'package:flutter/material.dart';

import '../features/home/presentation/home_first_run_screen.dart';
import 'theme.dart';

/// Root widget. #41 replaces the single home screen with the router.
class GeauxFarmApp extends StatelessWidget {
  const GeauxFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geaux Farm',
      theme: AppTheme.light(),
      home: const HomeFirstRunScreen(),
    );
  }
}
