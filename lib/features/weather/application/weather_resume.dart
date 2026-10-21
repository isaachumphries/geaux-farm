import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/data/profile_providers.dart';
import '../data/weather_provider.dart';

/// Refetches the forecast when the app comes back to the foreground. App
/// start is already covered by the provider's first build. Both go through
/// `refresh()`, so a fetch happens only when the cache is more than 60
/// minutes old (plan/06 § Caching and refresh).
///
/// The app root watches this, so it is alive for the whole session.
final weatherResumeRefreshProvider = Provider<void>((ref) {
  Future<void> refreshForProfile() async {
    final profile = await ref.read(userProfileProvider.future);
    if (!ref.mounted) return;
    final location = forecastLocation(profile.lat, profile.lon);
    await ref.read(weatherProvider(location).notifier).refresh();
  }

  final lifecycle = AppLifecycleListener(onResume: refreshForProfile);
  ref.onDispose(lifecycle.dispose);
});
