import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/garden/data/plantings_provider.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';

import '../helpers/in_memory_database.dart';

/// Reads the next value a stream provider emits, keeping it listened to.
Future<T> _next<T>(ProviderContainer c, StreamProvider<T> provider) {
  c.listen(provider, (_, _) {});
  return c.read(provider.future);
}

void main() {
  late ProviderContainer container;
  late AppDatabase db;

  setUp(() {
    container = ProviderContainer(overrides: [inMemoryDatabaseOverride()]);
    addTearDown(container.dispose);
    db = container.read(appDatabaseProvider);
  });

  group('userProfileProvider', () {
    test('yields the default profile before onboarding saves a row', () async {
      final profile = await _next(container, userProfileProvider);
      expect(profile, same(defaultUserProfile));
      expect(profile.onboardingCompletedAt, isNull);
    });

    test('streams the saved row, every column mapped', () async {
      final completed = DateTime(2026, 10, 7, 9, 30);
      await db
          .into(db.userProfileTable)
          .insert(
            UserProfileTableCompanion.insert(
              id: const Value(1),
              city: 'Lafayette',
              admin1: 'Louisiana',
              countryCode: 'US',
              postcode: const Value('70501'),
              lat: 30.22,
              lon: -92.02,
              timezone: 'America/Chicago',
              goals: [Goal.design, Goal.other],
              goalOtherText: const Value('Pollinators'),
              experience: Experience.expert,
              heardFrom: const Value(HeardFrom.lsuCampus),
              heardOtherText: const Value('n/a'),
              availability: const Availability([1, 2, 4, 8, 16, 32, 64]),
              units: 'metric',
              notificationsEnabled: const Value(false),
              notificationPermissionAsked: const Value(true),
              firstPlantPromptDismissed: const Value(true),
              onboardingCompletedAt: Value(completed),
            ),
          );

      final p = await _next(container, userProfileProvider);
      expect(p.city, 'Lafayette');
      expect(p.admin1, 'Louisiana');
      expect(p.countryCode, 'US');
      expect(p.postcode, '70501');
      expect(p.lat, 30.22);
      expect(p.lon, -92.02);
      expect(p.timezone, 'America/Chicago');
      expect(p.goals, [Goal.design, Goal.other]);
      expect(p.goalOtherText, 'Pollinators');
      expect(p.experience, Experience.expert);
      expect(p.heardFrom, HeardFrom.lsuCampus);
      expect(p.heardOtherText, 'n/a');
      expect(p.availability.days, [1, 2, 4, 8, 16, 32, 64]);
      expect(p.units, 'metric');
      expect(p.notificationsEnabled, isFalse);
      expect(p.notificationPermissionAsked, isTrue);
      expect(p.firstPlantPromptDismissed, isTrue);
      expect(p.onboardingCompletedAt, completed);
    });

    test('boolean columns use their plan/09 defaults', () async {
      await db
          .into(db.userProfileTable)
          .insert(
            UserProfileTableCompanion.insert(
              id: const Value(1),
              city: 'Baton Rouge',
              admin1: 'Louisiana',
              countryCode: 'US',
              lat: 30.45,
              lon: -91.19,
              timezone: 'America/Chicago',
              goals: [Goal.food],
              experience: Experience.beginner,
              availability: const Availability([0, 0, 0, 0, 0, 0, 2]),
              units: 'imperial',
            ),
          );

      final p = await _next(container, userProfileProvider);
      expect(p.notificationsEnabled, isTrue);
      expect(p.notificationPermissionAsked, isFalse);
      expect(p.firstPlantPromptDismissed, isFalse);
      expect(p.onboardingCompletedAt, isNull);
    });
  });

  group('primarySpaceProvider', () {
    test('yields the default space before onboarding saves one', () async {
      expect(await _next(container, primarySpaceProvider), same(defaultSpace));
    });

    test('streams the row where is_primary is true', () async {
      Future<void> insert(String id, SpaceType type, bool primary) => db
          .into(db.spacesTable)
          .insert(
            SpacesTableCompanion.insert(
              id: id,
              type: type,
              areaSqFt: 32,
              sun: SunLevel.full,
              sunUnsure: false,
              rainExposed: true,
              inContainerDefault: false,
              isPrimary: primary,
            ),
          );
      await insert('a', SpaceType.windowsill, false);
      await insert('b', SpaceType.smallYard, true);

      final s = await _next(container, primarySpaceProvider);
      expect(s.id, 'b');
      expect(s.type, SpaceType.smallYard);
      expect(s.sun, SunLevel.full);
      expect(s.isPrimary, isTrue);
    });
  });

  group('plantingsProvider', () {
    test('streams every planting, oldest first', () async {
      expect(await _next(container, plantingsProvider), isEmpty);

      Future<void> insert(String id, DateTime at) => db
          .into(db.plantingsTable)
          .insert(
            PlantingsTableCompanion.insert(
              id: id,
              plantId: 'kale',
              spaceId: 'b',
              nickname: id,
              setup: GrowSetup.greenhouse,
              inContainer: false,
              startMethod: 'transplant',
              status: PlantingStatus.planned,
              createdAt: at,
            ),
          );
      await insert('second', DateTime(2026, 10, 2));
      await insert('first', DateTime(2026, 10, 1));
      // Let the stream re-emit after the writes.
      await Future<void>.delayed(Duration.zero);

      final plantings = container.read(plantingsProvider).requireValue;
      expect(plantings.map((p) => p.id), ['first', 'second']);
      expect(plantings.first.setup, GrowSetup.greenhouse);
      expect(plantings.first.status, PlantingStatus.planned);
      expect(plantings.first.startMethod, 'transplant');
    });
  });
}
