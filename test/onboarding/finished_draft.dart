import 'package:geaux_farm/features/onboarding/domain/onboarding_draft.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';

/// A draft with every step answered: Baton Rouge, a 16 sq ft balcony that
/// gets rain, partial sun, Food + Hobby, the plan/02 demo availability,
/// and Instagram.
const finishedDraft = OnboardingDraft(
  city: 'Baton Rouge',
  admin1: 'Louisiana',
  countryCode: 'US',
  postcode: '70801',
  lat: 30.45,
  lon: -91.19,
  timezone: 'America/Chicago',
  spaceType: SpaceType.balcony,
  areaSqFt: 16,
  sun: SunLevel.partial,
  rainExposed: true,
  goals: {Goal.hobby, Goal.food},
  experience: Experience.intermediate,
  availability: [64, 0, 64, 0, 0, 2, 2],
  heardFrom: HeardFrom.instagram,
);
