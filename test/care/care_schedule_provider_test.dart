import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/application/care_schedule_provider.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/care/domain/care_schedule.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';
import 'package:geaux_farm/features/garden/data/plantings_provider.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/care_fixtures.dart';

/// Planting feed the re-emit test can push to after the first read. Each new
/// listener gets the current list first, then every [emit].
class _PlantingFeed {
  _PlantingFeed(this._plantings);

  final _controller = StreamController<List<Planting>>.broadcast();
  List<Planting> _plantings;

  void emit(List<Planting> next) {
    _plantings = next;
    _controller.add(next);
  }

  Future<void> close() => _controller.close();

  Stream<List<Planting>> watch() async* {
    yield _plantings;
    yield* _controller.stream;
  }
}

/// Free all week at fixed coordinates, so slots are predictable. Only the
/// coordinates and availability reach the schedule; the rest copies the
/// default profile so the fixture needs no enum imports.
UserProfile _profile() => UserProfile(
  city: defaultUserProfile.city,
  admin1: defaultUserProfile.admin1,
  countryCode: defaultUserProfile.countryCode,
  lat: 40.0,
  lon: -90.0,
  timezone: defaultUserProfile.timezone,
  goals: defaultUserProfile.goals,
  experience: defaultUserProfile.experience,
  availability: careAllFree,
);

/// Every source the schedule reads is faked, so no database or network runs.
/// The clock is fixed at [now], and weather fails so water takes the no-rain
/// fallback.
List<Override> _overrides({
  required Stream<List<Planting>> plantings,
  required DateTime now,
}) => [
  plantingsProvider.overrideWith((ref) => plantings),
  spacesProvider.overrideWith((ref) => Stream.value([careSpace()])),
  userProfileProvider.overrideWith((ref) => Stream.value(_profile())),
  careEventsProvider.overrideWith((ref) => Stream.value(const <CareEvent>[])),
  catalogProvider.overrideWith((ref) async => [carePlant()]),
  clockProvider.overrideWithValue(() => now),
  forecastClientProvider.overrideWithValue(
    OpenMeteoForecastClient(MockClient((_) async => http.Response('', 500))),
  ),
];

/// Reads the schedule once for [plantings], with the clock fixed at [now].
Future<List<ScheduledCareTask>> _readSchedule(
  List<Planting> plantings, {
  required DateTime now,
}) async {
  final container = ProviderContainer(
    overrides: _overrides(plantings: Stream.value(plantings), now: now),
  );
  addTearDown(container.dispose);
  final sub = container.listen(careScheduleProvider, (_, _) {});
  addTearDown(sub.close);
  return container.read(careScheduleProvider.future);
}

void main() {
  test('re-emits when the planting stream changes', () async {
    final feed = _PlantingFeed([carePlanting(nickname: 'Kale')]);
    addTearDown(feed.close);
    final container = ProviderContainer(
      overrides: _overrides(
        plantings: feed.watch(),
        now: DateTime(2026, 5, 1, 7),
      ),
    );
    addTearDown(container.dispose);
    // Keep the auto-dispose provider alive so the second read sees the
    // re-emitted state rather than a fresh rebuild.
    final sub = container.listen(careScheduleProvider, (_, _) {});
    addTearDown(sub.close);

    final first = await container.read(careScheduleProvider.future);
    expect(first, isNotEmpty);
    expect(first.every((t) => t.nickname == 'Kale'), isTrue);

    feed.emit([
      carePlanting(nickname: 'Kale'),
      carePlanting(id: 'p2', nickname: 'Basil'),
    ]);
    await Future<void>.delayed(Duration.zero);

    final second = await container.read(careScheduleProvider.future);
    expect(second.map((t) => t.nickname).toSet(), {'Kale', 'Basil'});
  });

  // The window starts Apr 30, so the May 1 due date is day 2 of the window.
  test('one water task due on day 2 is scheduled inside the window', () async {
    final tasks = await _readSchedule([
      carePlanting(),
    ], now: DateTime(2026, 4, 30, 7));
    expect(tasks, hasLength(1));
    final task = tasks.single;
    expect(task.kind, CareTaskKind.water);
    expect(task.due, DateTime(2026, 5, 1));
    expect(task.overdue, isFalse);
    expect(task.slot.start, DateTime(2026, 5, 1, 6));
    expect(task.slot.outsideFreeTimes, isFalse);
  });

  test('a planted but planned planting produces no tasks', () async {
    final tasks = await _readSchedule([
      carePlanting(status: PlantingStatus.planned),
    ], now: DateTime(2026, 5, 1, 7));
    expect(tasks, isEmpty);
  });

  test('a task due yesterday is returned flagged overdue', () async {
    final tasks = await _readSchedule([
      carePlanting(),
    ], now: DateTime(2026, 5, 2, 7));
    expect(tasks, hasLength(1));
    expect(tasks.single.due, DateTime(2026, 5, 1));
    expect(tasks.single.overdue, isTrue);
    expect(tasks.single.slot.start, DateTime(2026, 5, 2, 8));
  });
}
