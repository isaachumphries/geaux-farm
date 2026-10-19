import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/application/care_schedule_provider.dart';
import 'package:geaux_farm/features/care/data/drift_care_schedule_repository.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/care/domain/care_schedule.dart';
import 'package:geaux_farm/features/care/domain/care_schedule_repository.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/care_fixtures.dart';

/// Fake repository whose planting stream can be pushed to after the first read.
class _FakeCareRepo implements CareScheduleRepository {
  _FakeCareRepo(this._plantings);

  final _controller = StreamController<List<Planting>>.broadcast();
  List<Planting> _plantings;

  void emit(List<Planting> next) {
    _plantings = next;
    _controller.add(next);
  }

  Future<void> close() => _controller.close();

  @override
  Stream<List<Planting>> watchPlantings() async* {
    yield _plantings;
    yield* _controller.stream;
  }

  @override
  Stream<List<Space>> watchSpaces() => Stream.value([careSpace()]);

  @override
  Stream<List<CareEvent>> watchCareEvents() => Stream.value(const []);

  @override
  Stream<Availability> watchAvailability() => Stream.value(careAllFree);

  @override
  Stream<(double, double)> watchLocation() => Stream.value((40.0, -90.0));
}

/// Reads the schedule once for [plantings], with the clock fixed at [now].
/// Weather fails on purpose, so water uses waterDue's no-rain fallback.
Future<List<ScheduledCareTask>> _readSchedule(
  List<Planting> plantings, {
  required DateTime now,
}) async {
  final repo = _FakeCareRepo(plantings);
  addTearDown(repo.close);
  final container = ProviderContainer(
    overrides: [
      careScheduleRepositoryProvider.overrideWithValue(repo),
      catalogProvider.overrideWith((ref) async => [carePlant()]),
      clockProvider.overrideWithValue(() => now),
      forecastClientProvider.overrideWithValue(
        OpenMeteoForecastClient(
          MockClient((_) async => http.Response('', 500)),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  final sub = container.listen(careScheduleProvider, (_, _) {});
  addTearDown(sub.close);
  return container.read(careScheduleProvider.future);
}

void main() {
  test('re-emits when the planting stream changes', () async {
    final repo = _FakeCareRepo([carePlanting(nickname: 'Kale')]);
    addTearDown(repo.close);
    final container = ProviderContainer(
      overrides: [
        careScheduleRepositoryProvider.overrideWithValue(repo),
        catalogProvider.overrideWith((ref) async => [carePlant()]),
        clockProvider.overrideWithValue(() => DateTime(2026, 5, 1, 7)),
        forecastClientProvider.overrideWithValue(
          OpenMeteoForecastClient(
            MockClient((_) async => http.Response('', 500)),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Keep the auto-dispose provider alive so the second read sees the
    // re-emitted state rather than a fresh rebuild.
    final sub = container.listen(careScheduleProvider, (_, _) {});
    addTearDown(sub.close);

    final first = await container.read(careScheduleProvider.future);
    expect(first, isNotEmpty);
    expect(first.every((t) => t.nickname == 'Kale'), isTrue);

    repo.emit([
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
