import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/geocoding_repository.dart';
import '../domain/onboarding_draft.dart';

/// Holds the onboarding answers in memory only. A killed app starts again
/// at Welcome with an empty draft (plan/02 § Persistence). Each step issue
/// adds its own setters here.
class OnboardingDraftNotifier extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  /// OB-02: stores [place] with lat and lon rounded to 2 decimals.
  void setLocation(GeoPlace place) => state = state.copyWith(
    city: place.name,
    admin1: place.admin1,
    countryCode: place.countryCode,
    postcode: place.postcode,
    lat: roundCoordinate(place.lat),
    lon: roundCoordinate(place.lon),
    timezone: place.timezone,
  );

  /// Back to an empty draft.
  void reset() => state = const OnboardingDraft();
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, OnboardingDraft>(
      OnboardingDraftNotifier.new,
    );
