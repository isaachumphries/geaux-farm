import 'package:flutter/material.dart';

/// Stand-in for a route whose screen is not built yet. The app bar shows
/// the frame code and name (e.g. `GD-01 My Garden`); the body stays empty
/// until the feature issue replaces it.
class TitledScaffold extends StatelessWidget {
  const TitledScaffold(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const SizedBox.shrink(),
    );
  }
}
