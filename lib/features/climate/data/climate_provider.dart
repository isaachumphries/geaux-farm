import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/data/profile_providers.dart';
import '../../recommendations/application/clock_provider.dart';
import '../domain/climate_profile.dart';
import '../domain/rebuild_rules.dart';
import 'climate_service.dart';

/// Where the climate profile is built for.
typedef _ClimateLocation = ({
  double lat,
  double lon,
  String countryCode,
  String? postcode,
});

/// The user's climate profile (plan/09 § State management). [build]
/// returns the stored profile unless a rebuild rule fires
/// ([needsClimateRebuild]); then it builds, saves, and returns a new one.
/// A failed build leaves the state in error with nothing saved, so the next
/// app start builds again.
class ClimateNotifier extends AsyncNotifier<ClimateProfile> {
  @override
  Future<ClimateProfile> build() async {
    final location = await ref.watch(
      userProfileProvider.selectAsync(
        (p) => (
          lat: p.lat,
          lon: p.lon,
          countryCode: p.countryCode,
          postcode: p.postcode,
        ),
      ),
    );
    final repository = ref.read(climateRepositoryProvider);
    final cached = await repository.loadProfile();
    final rebuild = needsClimateRebuild(
      stored: cached == null ? null : await repository.loadLocation(),
      computedAt: cached?.computedAt,
      lat: location.lat,
      lon: location.lon,
      now: ref.read(clockProvider)(),
    );
    if (cached != null && !rebuild) return cached;
    return _build(location);
  }

  /// Builds for the current location regardless of the cache: the Retry
  /// and "Continue anyway" actions on OB-02b (#65).
  Future<void> rebuild() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final p = await ref.read(userProfileProvider.future);
      return _build((
        lat: p.lat,
        lon: p.lon,
        countryCode: p.countryCode,
        postcode: p.postcode,
      ));
    });
  }

  Future<ClimateProfile> _build(_ClimateLocation location) => ref
      .read(climateServiceProvider)
      .build(
        lat: location.lat,
        lon: location.lon,
        countryCode: location.countryCode,
        postcode: location.postcode,
      );
}

final climateProvider = AsyncNotifierProvider<ClimateNotifier, ClimateProfile>(
  ClimateNotifier.new,
  // No automatic retries: a failed build waits for the next app start or
  // an explicit rebuild() (plan/04; Open-Meteo is one request per build).
  retry: (_, _) => null,
);
