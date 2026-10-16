import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'widgets/widgets.dart';

/// The 4-tab shell: Home, Garden, Care, Community. Each tab keeps its own
/// navigation stack (plan/09 § Routes).
class TabShell extends StatelessWidget {
  const TabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final current = navigationShell.currentIndex;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: GeauxBottomNav(
        currentIndex: current,
        // Tapping the active tab again returns it to its root.
        onTap: (i) =>
            navigationShell.goBranch(i, initialLocation: i == current),
        items: const [
          GeauxNavItem(icon: Symbols.home_rounded, label: 'Home'),
          GeauxNavItem(icon: Symbols.yard_rounded, label: 'Garden'),
          GeauxNavItem(icon: Symbols.event_available_rounded, label: 'Care'),
          GeauxNavItem(icon: Symbols.groups_rounded, label: 'Community'),
        ],
      ),
    );
  }
}
