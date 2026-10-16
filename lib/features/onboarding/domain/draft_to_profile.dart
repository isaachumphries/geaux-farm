import 'availability.dart';
import 'onboarding_draft.dart';
import 'space.dart';
import 'space_rules.dart';
import 'user_profile.dart';

/// The saved rows built from a finished draft, or null while a required
/// answer is missing. Pure: [now] and [spaceId] come from the caller.
({UserProfile profile, Space space})? profileFromDraft(
  OnboardingDraft d, {
  required DateTime now,
  required String spaceId,
}) {
  final city = d.city, admin1 = d.admin1, countryCode = d.countryCode;
  final lat = d.lat, lon = d.lon;
  final type = d.spaceType, area = d.areaSqFt, sun = d.sun;
  if (city == null || admin1 == null || countryCode == null) return null;
  if (lat == null || lon == null) return null;
  if (type == null || area == null || sun == null) return null;
  if (d.goals.isEmpty || d.availability.every((b) => b == 0)) return null;

  final derived = derivedSpaceDefaults(type, d.rainExposed ?? true);
  return (
    profile: UserProfile(
      city: city,
      admin1: admin1,
      countryCode: countryCode,
      postcode: d.postcode,
      lat: lat,
      lon: lon,
      // Open-Meteo search and the device both give one; UTC is a last
      // resort so Finish never fails on it.
      timezone: d.timezone ?? 'UTC',
      goals: Goal.values.where(d.goals.contains).toList(),
      goalOtherText: d.goals.contains(Goal.other) ? d.goalOtherText : null,
      experience: d.experience ?? Experience.beginner,
      heardFrom: d.heardFrom,
      heardOtherText: d.heardFrom == HeardFrom.other ? d.heardOtherText : null,
      availability: Availability(List.of(d.availability)),
      onboardingCompletedAt: now,
    ),
    space: Space(
      id: spaceId,
      type: type,
      areaSqFt: area,
      sun: sun,
      sunUnsure: d.sunUnsure,
      rainExposed: derived.rainExposed,
      inContainerDefault: derived.inContainerDefault,
    ),
  );
}
