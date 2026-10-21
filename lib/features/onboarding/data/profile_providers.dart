import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../domain/space.dart';
import '../domain/user_profile.dart';
import 'default_profile.dart';

/// The `user_profile` row (id 1). Until onboarding saves one (#69) it
/// yields [defaultUserProfile], whose null `onboardingCompletedAt` keeps
/// the router's onboarding redirect on.
final userProfileProvider = StreamProvider<UserProfile>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.userProfileTable)..where((t) => t.id.equals(1));
  return query.watchSingleOrNull().map(
    (row) => row == null ? defaultUserProfile : _profileFromRow(row),
  );
});

/// The `spaces` row where `is_primary` is true. Until onboarding saves one
/// (#69) it yields [defaultSpace].
final primarySpaceProvider = StreamProvider<Space>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.spacesTable)
    ..where((t) => t.isPrimary.equals(true))
    ..limit(1);
  return query.watchSingleOrNull().map(
    (row) => row == null ? defaultSpace : _spaceFromRow(row),
  );
});

/// Every row in the `spaces` table. Empty until onboarding adds one (#69).
/// Care scheduling reads all spaces, not only the primary one, so each
/// planting resolves to the space it actually sits in.
final spacesProvider = StreamProvider<List<Space>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .select(db.spacesTable)
      .watch()
      .map((rows) => rows.map(_spaceFromRow).toList());
});

UserProfile _profileFromRow(UserProfileRow r) => UserProfile(
  city: r.city,
  admin1: r.admin1,
  countryCode: r.countryCode,
  postcode: r.postcode,
  lat: r.lat,
  lon: r.lon,
  timezone: r.timezone,
  goals: r.goals,
  goalOtherText: r.goalOtherText,
  experience: r.experience,
  heardFrom: r.heardFrom,
  heardOtherText: r.heardOtherText,
  availability: r.availability,
  units: r.units,
  notificationsEnabled: r.notificationsEnabled,
  notificationPermissionAsked: r.notificationPermissionAsked,
  firstPlantPromptDismissed: r.firstPlantPromptDismissed,
  onboardingCompletedAt: r.onboardingCompletedAt,
);

Space _spaceFromRow(SpaceRow r) => Space(
  id: r.id,
  type: r.type,
  areaSqFt: r.areaSqFt,
  sun: r.sun,
  sunUnsure: r.sunUnsure,
  rainExposed: r.rainExposed,
  inContainerDefault: r.inContainerDefault,
  isPrimary: r.isPrimary,
);
