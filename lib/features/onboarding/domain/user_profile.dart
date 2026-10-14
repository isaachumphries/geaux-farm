import 'availability.dart';

/// Gardening goals from OB-04 (plan/02 § Stored values). `other` carries
/// free text in [UserProfile.goalOtherText].
enum Goal { food, design, hobby, other }

/// Self-reported experience from OB-04; scoring maps beginner = 1,
/// intermediate = 2, expert = 3.
enum Experience { beginner, intermediate, expert }

/// How the user heard about the app (OB-06). `other` carries free text in
/// [UserProfile.heardOtherText].
enum HeardFrom {
  friendFamily,
  instagram,
  tiktok,
  appStore,
  lsuCampus,
  farmersMarket,
  other,
}

/// The single local user profile (Drift `user_profile`, id always 1).
class UserProfile {
  const UserProfile({
    required this.city,
    required this.admin1,
    required this.countryCode,
    this.postcode,
    required this.lat,
    required this.lon,
    required this.timezone,
    required this.goals,
    this.goalOtherText,
    required this.experience,
    this.heardFrom,
    this.heardOtherText,
    required this.availability,
    this.units = 'imperial',
    this.notificationsEnabled = true,
    this.notificationPermissionAsked = false,
    this.firstPlantPromptDismissed = false,
    this.onboardingCompletedAt,
  });

  final String city;
  final String admin1;
  final String countryCode;
  final String? postcode;

  /// Rounded to 2 decimals (plan/02).
  final double lat;
  final double lon;
  final String timezone;
  final List<Goal> goals;
  final String? goalOtherText;
  final Experience experience;
  final HeardFrom? heardFrom;
  final String? heardOtherText;
  final Availability availability;

  /// `'imperial'` or `'metric'`.
  final String units;
  final bool notificationsEnabled;
  final bool notificationPermissionAsked;
  final bool firstPlantPromptDismissed;
  final DateTime? onboardingCompletedAt;
}
