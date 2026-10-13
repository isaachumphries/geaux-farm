import 'package:flutter/material.dart';

import 'theme.dart';

/// Root widget. #41 replaces the placeholder home with the router.
class GeauxFarmApp extends StatelessWidget {
  const GeauxFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geaux Farm',
      theme: AppTheme.light(),
      home: const Scaffold(body: Center(child: Text('Geaux Farm'))),
    );
  }
}
