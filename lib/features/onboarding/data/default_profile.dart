import '../domain/availability.dart';
import '../domain/space.dart';
import '../domain/user_profile.dart';

/// The profile every install uses until onboarding (#59–#69) collects the
/// user's answers, the summary step (#69) saves them, and Drift (#43)
/// streams them: Baton Rouge, LA, with the plan/04 worked-example goals,
/// experience, and availability.
const defaultUserProfile = UserProfile(
  city: 'Baton Rouge',
  admin1: 'Louisiana',
  countryCode: 'US',
  lat: 30.45,
  lon: -91.19,
  timezone: 'America/Chicago',
  goals: [Goal.food, Goal.hobby],
  experience: Experience.beginner,
  availability: Availability([64, 0, 64, 0, 0, 2, 2]),
);

/// The primary space until OB-03 (#66) collects one, #69 saves it, and
/// Drift (#43) streams it: a 3 ft × 6 ft balcony with partial sun that gets
/// rain, planted in containers.
const defaultSpace = Space(
  id: 'default',
  type: SpaceType.balcony,
  areaSqFt: 18,
  sun: SunLevel.partial,
  rainExposed: true,
  inContainerDefault: true,
);
