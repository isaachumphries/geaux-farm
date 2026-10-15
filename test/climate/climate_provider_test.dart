import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/climate/data/climate_repository.dart';
import 'package:geaux_farm/features/climate/data/climate_service.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';

import '../recommendations/fixtures/baton_rouge.dart' as fx;

final _now = DateTime(2026, 10, 7, 9);

UserProfile _at(double lat, double lon) => UserProfile(
  city: 'Baton Rouge',
  admin1: 'Louisiana',
  countryCode: 'US',
  postcode: '70803',
  lat: lat,
  lon: lon,
  timezone: 'America/Chicago',
  goals: const [Goal.food],
  experience: Experience.beginner,
  availability: fx.workedExampleProfile.availability,
);

ClimateProfile _profile(DateTime computedAt, {String zone = '8b'}) =>
    ClimateProfile(
      months: fx.batonRougeMonths,
      annualExtremeMinF: 19.66,
      annualPrecipIn: 58.18,
      annualRhPct: 75,
      zone: zone,
      zoneSource: ZoneSource.computed,
      lastSpringFrostDoy: 51,
      computedAt: computedAt,
    );

/// Stands in for the network build: counts calls, then fails or saves a
/// fresh profile through the real repository, as [ClimateService] does.
class _FakeService extends Fake implements ClimateService {
  _FakeService(this._repository);

  final ClimateRepository _repository;
  int calls = 0;
  bool fail = false;

  @override
  Future<ClimateProfile> build({
    required double lat,
    required double lon,
    required String countryCode,
    String? postcode,
  }) async {
    calls++;
    if (fail) throw const ClimateUnavailableException('archive down');
    final p = _profile(_now, zone: 'built');
    await _repository.saveProfile(p, lat: lat, lon: lon);
    return p;
  }
}

void main() {
  late AppDatabase db;
  late ClimateRepository repository;
  late _FakeService service;
  late StreamController<UserProfile> profiles;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    repository = ClimateRepository(db);
    service = _FakeService(repository);
    profiles = StreamController<UserProfile>.broadcast();
    addTearDown(profiles.close);
  });

  /// A fresh container on the shared database, as on an app start, with
  /// the user at ([lat], [lon]).
  ProviderContainer start({double lat = 30.45, double lon = -91.19}) {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        climateServiceProvider.overrideWithValue(service),
        clockProvider.overrideWithValue(() => _now),
        userProfileProvider.overrideWith((ref) async* {
          yield _at(lat, lon);
          yield* profiles.stream;
        }),
      ],
    );
    addTearDown(c.dispose);
    c.listen(climateProvider, (_, _) {});
    return c;
  }

  Future<void> seed(DateTime computedAt, {double lat = 30.45}) =>
      repository.saveProfile(_profile(computedAt), lat: lat, lon: -91.19);

  Future<int> metaRows() async =>
      (await db.select(db.climateMetaTable).get()).length;

  test('no climate_meta row → exactly one build', () async {
    final p = await start().read(climateProvider.future);
    expect(service.calls, 1);
    expect(p.zone, 'built');
    expect(await metaRows(), 1);
  });

  test('365 days old → cached profile, no build', () async {
    await seed(_now.subtract(const Duration(days: 365)));
    final p = await start().read(climateProvider.future);
    expect(service.calls, 0);
    expect(p.zone, '8b');
  });

  test('366 days old → one build', () async {
    await seed(_now.subtract(const Duration(days: 366)));
    final p = await start().read(climateProvider.future);
    expect(service.calls, 1);
    expect(p.zone, 'built');
  });

  test('stored lat 30.45, current 30.46 → one build', () async {
    await seed(_now);
    await start(lat: 30.46).read(climateProvider.future);
    expect(service.calls, 1);
  });

  test('current 30.451 rounds to the stored 30.45 → no build', () async {
    await seed(_now);
    await start(lat: 30.451).read(climateProvider.future);
    expect(service.calls, 0);
  });

  test('a location change while running triggers a build', () async {
    await seed(_now);
    final c = start();
    await c.read(climateProvider.future);
    expect(service.calls, 0);

    profiles.add(_at(29.95, -90.07));
    await Future<void>.delayed(Duration.zero);
    final p = await c.read(climateProvider.future);
    expect(service.calls, 1);
    expect(p.zone, 'built');
    expect(await repository.loadLocation(), (lat: 29.95, lon: -90.07));
  });

  test(
    'a failed build → error, nothing saved, retried on next start',
    () async {
      service.fail = true;
      final first = start();
      await expectLater(
        first.read(climateProvider.future),
        throwsA(isA<ClimateUnavailableException>()),
      );
      expect(first.read(climateProvider), isA<AsyncError<ClimateProfile>>());
      expect(await metaRows(), 0);
      expect(service.calls, 1);
      first.dispose();

      service.fail = false;
      final p = await start().read(climateProvider.future);
      expect(service.calls, 2);
      expect(p.zone, 'built');
    },
  );

  test('rebuild() builds even with a fresh cache and saves', () async {
    await seed(_now.subtract(const Duration(days: 3)));
    final c = start();
    expect((await c.read(climateProvider.future)).zone, '8b');
    expect(service.calls, 0);

    await c.read(climateProvider.notifier).rebuild();
    expect(service.calls, 1);
    expect(c.read(climateProvider).requireValue.zone, 'built');
    expect((await repository.loadProfile())!.computedAt, _now);
  });

  test('a failed rebuild() leaves the state in error', () async {
    final c = start();
    await c.read(climateProvider.future);
    service.fail = true;
    await c.read(climateProvider.notifier).rebuild();
    expect(c.read(climateProvider), isA<AsyncError<ClimateProfile>>());
  });

  test('only loading, a full profile, or an error is ever emitted', () async {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        climateServiceProvider.overrideWithValue(service),
        clockProvider.overrideWithValue(() => _now),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(_at(30.45, -91.19)),
        ),
      ],
    );
    addTearDown(c.dispose);
    final seen = <AsyncValue<ClimateProfile>>[];
    c.listen(
      climateProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );
    await c.read(climateProvider.future);

    expect(seen.first, isA<AsyncLoading<ClimateProfile>>());
    expect(seen.last.requireValue.months, hasLength(12));
    for (final s in seen) {
      if (s.hasValue) expect(s.requireValue.months, hasLength(12));
    }
  });
}
