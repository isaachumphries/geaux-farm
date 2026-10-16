import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/geocoding_repository.dart';
import '../domain/onboarding_draft.dart';
import '../domain/space.dart';
import '../domain/space_rules.dart';
import '../domain/user_profile.dart';

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

  /// OB-03: picks a space type, moves the area slider to its default, and
  /// derives `rainExposed` (the rain switch starts on for Balcony).
  void setSpaceType(SpaceType type) => state = state.copyWith(
    spaceType: type,
    areaSqFt: defaultAreaSqFt[type],
    rainExposed: derivedSpaceDefaults(type, true).rainExposed,
  );

  void setAreaSqFt(int sqFt) => state = state.copyWith(areaSqFt: sqFt);

  /// OB-03 sun answer; "Not sure" is `SunLevel.partial` with [unsure].
  void setSun(SunLevel sun, {bool unsure = false}) =>
      state = state.copyWith(sun: sun, sunUnsure: unsure);

  /// OB-03 rain switch; only Balcony or patio reads it.
  void setRainSwitch(bool on) {
    final type = state.spaceType;
    if (type == null) return;
    state = state.copyWith(
      rainExposed: derivedSpaceDefaults(type, on).rainExposed,
    );
  }

  /// OB-04: adds or removes [goal]. Removing Other clears its text.
  void toggleGoal(Goal goal) {
    final goals = {...state.goals};
    final removed = goals.remove(goal);
    if (!removed) goals.add(goal);
    state = state.copyWith(
      goals: goals,
      goalOtherText: goal == Goal.other && removed ? null : state.goalOtherText,
    );
  }

  void setGoalOtherText(String text) => state = state.copyWith(
    goalOtherText: text.trim().isEmpty ? null : text.trim(),
  );

  void setExperience(Experience experience) =>
      state = state.copyWith(experience: experience);

  /// OB-05: the 7 Mon..Sun bitmasks from the grid.
  void setAvailability(List<int> days) =>
      state = state.copyWith(availability: List.unmodifiable(days));

  /// Back to an empty draft.
  void reset() => state = const OnboardingDraft();
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, OnboardingDraft>(
      OnboardingDraftNotifier.new,
    );
