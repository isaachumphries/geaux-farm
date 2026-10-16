import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/onboarding/data/attribution_repository.dart';
import 'package:geaux_farm/features/onboarding/data/onboarding_repository.dart';
import 'package:geaux_farm/features/onboarding/data/profile_writer.dart';
import 'package:geaux_farm/features/onboarding/domain/onboarding_draft.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';

import 'finished_draft.dart';

class _Attribution implements AttributionRepository {
  _Attribution({this.fail = false});

  final bool fail;
  final calls = <(HeardFrom, String?)>[];

  @override
  Future<void> submit(HeardFrom source, String? otherText) async {
    calls.add((source, otherText));
    if (fail) throw Exception('insert failed');
  }
}

/// Fails after the profile insert, inside the same transaction.
class _FailingWriter extends ProfileWriter {
  _FailingWriter(this.db) : super(db);

  final AppDatabase db;

  @override
  Future<void> save(UserProfile profile, Space space) =>
      db.transaction(() async {
        await super.save(profile, space);
        throw Exception('disk full');
      });
}

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 10, 7, 9, 41);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
  });

  OnboardingRepository repo({
    ProfileWriter? writer,
    AttributionRepository? attribution,
  }) => OnboardingRepository(
    writer: writer ?? ProfileWriter(db),
    attribution: attribution ?? _Attribution(),
    now: () => now,
  );

  test('Finish writes profile id 1 and exactly one primary space', () async {
    final attribution = _Attribution();
    await repo(attribution: attribution).completeOnboarding(finishedDraft);

    final profile = await db.select(db.userProfileTable).getSingle();
    expect(profile.id, 1);
    expect(profile.onboardingCompletedAt, now);
    expect(profile.city, 'Baton Rouge');
    expect(profile.postcode, '70801');
    expect(profile.lat, 30.45);
    expect(profile.timezone, 'America/Chicago');
    expect(profile.goals, [Goal.food, Goal.hobby]);
    expect(profile.experience, Experience.intermediate);
    expect(profile.availability.days, [64, 0, 64, 0, 0, 2, 2]);
    expect(profile.heardFrom, HeardFrom.instagram);

    final spaces = await db.select(db.spacesTable).get();
    expect(spaces, hasLength(1));
    final space = spaces.single;
    expect(space.isPrimary, isTrue);
    expect(space.type, SpaceType.balcony);
    expect(space.areaSqFt, 16);
    expect(space.sun, SunLevel.partial);
    expect(space.rainExposed, isTrue);
    expect(space.inContainerDefault, isTrue);
    expect(space.id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4')));

    await pumpEventQueue();
    expect(attribution.calls, [(HeardFrom.instagram, null)]);
  });

  test('a failure inside the transaction writes neither row', () async {
    final attribution = _Attribution();
    await expectLater(
      repo(
        writer: _FailingWriter(db),
        attribution: attribution,
      ).completeOnboarding(finishedDraft),
      throwsException,
    );
    expect(await db.select(db.userProfileTable).get(), isEmpty);
    expect(await db.select(db.spacesTable).get(), isEmpty);
    await pumpEventQueue();
    expect(attribution.calls, isEmpty);
  });

  test(
    'Skip (no heardFrom) sends nothing; a failed insert is ignored',
    () async {
      final skipped = _Attribution();
      await repo(attribution: skipped)
          .completeOnboarding(finishedDraft.copyWith(heardFrom: null));
      await pumpEventQueue();
      expect(skipped.calls, isEmpty);

      final failing = _Attribution(fail: true);
      await repo(attribution: failing).completeOnboarding(
        finishedDraft.copyWith(
          heardFrom: HeardFrom.other,
          heardOtherText: 'Flyer at the library',
        ),
      );
      await pumpEventQueue();
      expect(failing.calls, [(HeardFrom.other, 'Flyer at the library')]);
    },
  );

  test('an incomplete draft throws and writes nothing', () async {
    await expectLater(
      repo().completeOnboarding(const OnboardingDraft()),
      throwsStateError,
    );
    expect(await db.select(db.userProfileTable).get(), isEmpty);
  });

  test('a windowsill never gets rain; a yard is in the ground', () async {
    await repo().completeOnboarding(
      finishedDraft.copyWith(
        spaceType: SpaceType.windowsill,
        rainExposed: true,
      ),
    );
    var space = await (db.select(
      db.spacesTable,
    )..where((t) => t.isPrimary.equals(true))).getSingle();
    expect(space.rainExposed, isFalse);
    expect(space.inContainerDefault, isTrue);

    await repo().completeOnboarding(
      finishedDraft.copyWith(
        spaceType: SpaceType.largeYard,
        rainExposed: false,
      ),
    );
    space = await (db.select(
      db.spacesTable,
    )..where((t) => t.isPrimary.equals(true))).getSingle();
    expect(space.rainExposed, isTrue);
    expect(space.inContainerDefault, isFalse);
  });
}
