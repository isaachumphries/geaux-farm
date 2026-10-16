import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../climate/data/climate_service.dart';
import '../../climate/domain/climate_profile.dart';
import 'onboarding_draft_provider.dart';

/// The OB-02b climate build for the draft location. The profile is not in
/// Drift yet, so this builds from the draft rather than through
/// `climateProvider`. The service stores the result with its location, so
/// Home's `climateProvider` reuses it after OB-07 instead of building again.
class OnboardingClimateNotifier extends AsyncNotifier<ClimateProfile> {
  @override
  Future<ClimateProfile> build() {
    final location = ref.watch(
      onboardingDraftProvider.select(
        (d) => (
          lat: d.lat,
          lon: d.lon,
          countryCode: d.countryCode,
          postcode: d.postcode,
        ),
      ),
    );
    final lat = location.lat;
    final lon = location.lon;
    if (lat == null || lon == null) {
      throw StateError('No location in the onboarding draft');
    }
    return ref
        .read(climateServiceProvider)
        .build(
          lat: lat,
          lon: lon,
          countryCode: location.countryCode ?? '',
          postcode: location.postcode,
        );
  }

  /// Retry on the error state: build again.
  void retry() => ref.invalidateSelf();
}

final onboardingClimateProvider =
    AsyncNotifierProvider<OnboardingClimateNotifier, ClimateProfile>(
      OnboardingClimateNotifier.new,
      // One request per build; retrying is the user's Retry tap.
      retry: (_, _) => null,
    );
