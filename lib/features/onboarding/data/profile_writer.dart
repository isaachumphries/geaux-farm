import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../domain/space.dart';
import '../domain/user_profile.dart';

/// Writes the `user_profile` row (id 1) and the primary `spaces` row.
class ProfileWriter {
  ProfileWriter(this._db);

  final AppDatabase _db;

  /// Stores [profile] and [space] as the primary space in one transaction,
  /// replacing any earlier rows.
  Future<void> save(UserProfile profile, Space space) {
    return _db.transaction(() async {
      await _db
          .into(_db.userProfileTable)
          .insertOnConflictUpdate(
            UserProfileTableCompanion.insert(
              id: const Value(1),
              city: profile.city,
              admin1: profile.admin1,
              countryCode: profile.countryCode,
              postcode: Value(profile.postcode),
              lat: profile.lat,
              lon: profile.lon,
              timezone: profile.timezone,
              goals: profile.goals,
              goalOtherText: Value(profile.goalOtherText),
              experience: profile.experience,
              heardFrom: Value(profile.heardFrom),
              heardOtherText: Value(profile.heardOtherText),
              availability: profile.availability,
              units: profile.units,
              notificationsEnabled: Value(profile.notificationsEnabled),
              notificationPermissionAsked: Value(
                profile.notificationPermissionAsked,
              ),
              firstPlantPromptDismissed: Value(
                profile.firstPlantPromptDismissed,
              ),
              onboardingCompletedAt: Value(profile.onboardingCompletedAt),
            ),
          );
      await (_db.update(_db.spacesTable)
            ..where((t) => t.id.equals(space.id).not()))
          .write(const SpacesTableCompanion(isPrimary: Value(false)));
      await _db
          .into(_db.spacesTable)
          .insertOnConflictUpdate(
            SpacesTableCompanion.insert(
              id: space.id,
              type: space.type,
              areaSqFt: space.areaSqFt,
              sun: space.sun,
              sunUnsure: space.sunUnsure,
              rainExposed: space.rainExposed,
              inContainerDefault: space.inContainerDefault,
              isPrimary: true,
            ),
          );
    });
  }
}

final profileWriterProvider = Provider<ProfileWriter>(
  (ref) => ProfileWriter(ref.watch(appDatabaseProvider)),
);
