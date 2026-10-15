import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/recommendations/application/recommendations_provider.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';
import 'package:geaux_farm/features/recommendations/domain/indoor_climate.dart';
import 'package:geaux_farm/features/recommendations/domain/score_plant.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';

import 'fixtures/baton_rouge.dart' as fx;

/// `id:score:inSeason` for each item, in list order.
List<String> _summary(List<ScoredPlant> items) => [
  for (final s in items)
    '${s.plant.id}:${s.compatibility.score}:${s.compatibility.inSeason}',
];

ProviderContainer _container({
  required DateTime Function() clock,
  Space? space,
  bool disposeOnTearDown = true,
}) {
  final container = ProviderContainer(
    overrides: [
      catalogProvider.overrideWithValue(
        AsyncData(fx.loadReferencePlants().values.toList()),
      ),
      clockProvider.overrideWithValue(clock),
      climateProvider.overrideWith(_SettableClimate.new),
      // The profile streams read Drift; feed them the defaults instead.
      userProfileProvider.overrideWith(
        (ref) => Stream.value(defaultUserProfile),
      ),
      primarySpaceProvider.overrideWithValue(AsyncData(space ?? defaultSpace)),
    ],
  );
  if (disposeOnTearDown) addTearDown(container.dispose);
  return container;
}

/// Reads the list the way a screen does: listened to, so the stream
/// providers it watches are not paused.
Future<List<ScoredPlant>> _read(ProviderContainer container) {
  container.listen(recommendationsProvider, (_, _) {});
  return container.read(recommendationsProvider.future);
}

/// Climate the test can replace after the first build.
class _SettableClimate extends ClimateNotifier {
  @override
  Future<ClimateProfile> build() async => fx.batonRougeClimate;

  void set(ClimateProfile profile) => state = AsyncData(profile);
}

void main() {
  test('the default Baton Rouge balcony user gets the plan/04 order on '
      '2026-10-13', () async {
    final container = _container(clock: () => DateTime(2026, 10, 13, 9));

    final recs = await _read(container);

    expect(_summary(recs), [
      'kale:100:true',
      'english-lavender:74:true',
      'sweet-basil:100:false',
      'cherry-tomato:88:false',
    ]);
  });

  test('an April clock puts the warm-season plants first', () async {
    final container = _container(clock: () => DateTime(2026, 4, 13, 9));

    final recs = await _read(container);

    // April mean 69.25 °F suits planting all four, but kale's 5-month
    // window reaches June (high 90.0 > 85) and lavender's reaches August
    // (high 92.1 > 90), so only basil and tomato are in season.
    expect(_summary(recs), [
      'sweet-basil:100:true',
      'cherry-tomato:88:true',
      'kale:100:false',
      'english-lavender:74:false',
    ]);
  });

  test('a windowsill is scored indoors; a balcony outdoors', () async {
    const windowsill = Space(
      id: 'w',
      type: SpaceType.windowsill,
      areaSqFt: 4,
      sun: SunLevel.full,
      rainExposed: false,
      inContainerDefault: true,
    );
    final today = DateTime(2026, 10, 13);
    final plants = fx.loadReferencePlants().values;
    List<String> expected(Space space, GrowSetup setup) {
      final ctx = UserContext(
        profile: defaultUserProfile,
        space: space,
        climate: fx.batonRougeClimate,
      );
      final scored = [
        for (final p in plants)
          ScoredPlant(p, scorePlant(p, ctx, setup, today)),
      ];
      return _summary(scored)..sort();
    }

    final indoor = await _read(
      _container(clock: () => today, space: windowsill),
    );
    final outdoor = await _read(
      _container(clock: () => today, space: defaultSpace),
    );

    expect(_summary(indoor)..sort(), expected(windowsill, GrowSetup.indoor));
    expect(
      _summary(outdoor)..sort(),
      expected(defaultSpace, GrowSetup.outdoor),
    );
    // Indoors kale loses its space fit (not an indoor plant) and every
    // plant is in season in the fixed 65–75 °F climate.
    expect(_summary(indoor).first, 'sweet-basil:100:true');
    expect(_summary(indoor), contains('kale:85:true'));
    expect(defaultGrowSetup(SpaceType.windowsill), GrowSetup.indoor);
    for (final t in SpaceType.values.where((t) => t != SpaceType.windowsill)) {
      expect(defaultGrowSetup(t), GrowSetup.outdoor, reason: t.name);
    }
  });

  testWidgets('the list recomputes when the calendar day changes', (
    tester,
  ) async {
    var now = DateTime(2026, 9, 30, 23, 59);
    // Disposed in the body: the midnight timer must be gone before the
    // test binding checks for pending timers.
    final container = _container(clock: () => now, disposeOnTearDown: false);
    final sub = container.listen(recommendationsProvider, (_, _) {});

    await tester.pump();
    expect(container.read(todayProvider), DateTime(2026, 9, 30));
    expect(_summary(sub.read().requireValue), [
      'kale:100:false',
      'sweet-basil:100:false',
      'cherry-tomato:88:false',
      'english-lavender:74:false',
    ]);

    now = DateTime(2026, 10, 1, 0, 0, 1);
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    expect(container.read(todayProvider), DateTime(2026, 10, 1));
    expect(_summary(sub.read().requireValue), [
      'kale:100:true',
      'english-lavender:74:true',
      'sweet-basil:100:false',
      'cherry-tomato:88:false',
    ]);
    container.dispose();
  });

  test('profile, space, and climate updates recompute the list', () async {
    final profiles = StreamController<UserProfile>();
    final spaces = StreamController<Space>();
    addTearDown(profiles.close);
    addTearDown(spaces.close);
    final container = ProviderContainer(
      overrides: [
        catalogProvider.overrideWithValue(
          AsyncData(fx.loadReferencePlants().values.toList()),
        ),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 13, 9)),
        userProfileProvider.overrideWith((ref) => profiles.stream),
        primarySpaceProvider.overrideWith((ref) => spaces.stream),
        climateProvider.overrideWith(_SettableClimate.new),
      ],
    );
    addTearDown(container.dispose);
    Future<List<String>> next() async {
      await Future<void>.delayed(Duration.zero);
      return _summary(await _read(container));
    }

    profiles.add(defaultUserProfile);
    spaces.add(defaultSpace);
    expect(await next(), [
      'kale:100:true',
      'english-lavender:74:true',
      'sweet-basil:100:false',
      'cherry-tomato:88:false',
    ]);

    // Design-only goals: food plants lose 7 points, lavender gains 7.
    profiles.add(fx.profileWith(goals: [Goal.design]));
    expect(await next(), [
      'kale:93:true',
      'english-lavender:81:true',
      'sweet-basil:93:false',
      'cherry-tomato:81:false',
    ]);

    profiles.add(defaultUserProfile);
    spaces.add(
      const Space(
        id: 'w',
        type: SpaceType.windowsill,
        areaSqFt: 4,
        sun: SunLevel.full,
        rainExposed: false,
        inContainerDefault: true,
      ),
    );
    expect((await next()).first, 'sweet-basil:100:true');

    // A mild 65–75 °F climate year-round puts every plant in season.
    spaces.add(defaultSpace);
    (container.read(climateProvider.notifier) as _SettableClimate).set(
      ClimateProfile(
        months: indoorClimateMonths,
        annualExtremeMinF: 60,
        annualPrecipIn: 0,
        annualRhPct: 75,
        zone: '8b',
        zoneSource: ZoneSource.computed,
        computedAt: DateTime.utc(2026, 10, 13),
      ),
    );
    expect(await next(), [
      'kale:100:true',
      'sweet-basil:100:true',
      'cherry-tomato:88:true',
      'english-lavender:74:true',
    ]);
  });
}
