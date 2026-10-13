import 'package:flutter/material.dart';

/// Root widget. #35 replaces the default theme with the design tokens and
/// #41 replaces the placeholder home with the router.
class GeauxFarmApp extends StatelessWidget {
  const GeauxFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geaux Farm',
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(body: Center(child: Text('Geaux Farm'))),
    );
  }
}
