import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/onboarding/data/profile_providers.dart';
import 'notification_wiring.dart';
import 'router.dart';
import 'theme.dart';

/// Root widget: the themed router.
class GeauxFarmApp extends ConsumerWidget {
  const GeauxFarmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationStartupProvider);
    // Hold a blank cream screen until the first profile read lands, so the
    // onboarding redirect is decided before any screen shows.
    final profile = ref.watch(userProfileProvider);
    if (!profile.hasValue && !profile.hasError) {
      return MaterialApp(
        title: 'Geaux Farm',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const Scaffold(),
      );
    }
    return MaterialApp.router(
      title: 'Geaux Farm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(goRouterProvider),
    );
  }
}
