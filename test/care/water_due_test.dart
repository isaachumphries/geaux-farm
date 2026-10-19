import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/care/domain/schedule_math.dart';
import 'package:geaux_farm/features/care/domain/water_due.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';

import '../recommendations/fixtures/baton_rouge.dart';

final _planted = DateTime(2026, 5, 1);

DateTime _day(int offset) => addDays(_planted, offset);

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

WeatherDay _wx(int offset, {required double et0, double precipIn = 0}) =>
    WeatherDay(
      date: _iso(_day(offset)),
      weatherCode: 0,
      tmaxF: 80,
      tminF: 60,
      precipIn: precipIn,
      precipProb: null,
      uvMax: null,
      sunshineS: 0,
      daylightS: 0,
      et0In: et0,
      sunrise: '',
      sunset: '',
    );

Map<DateTime, WeatherDay> _days(List<WeatherDay> rows) => {
  for (final r in rows) DateTime.parse(r.date): r,
};

Plant _kale([Map<String, dynamic> changes = const {}]) =>
    Plant.fromJson({...rawKale(), ...changes});

Planting _planting({
  GrowSetup setup = GrowSetup.outdoor,
  bool inContainer = true,
}) => Planting(
  id: 'p1',
  plantId: 'kale',
  spaceId: 's1',
  nickname: 'Kale',
  setup: setup,
  inContainer: inContainer,
  startMethod: 'transplant',
  status: PlantingStatus.active,
  createdAt: _planted,
  plantedOn: _planted,
);

Space _space({bool rainExposed = true}) => Space(
  id: 's1',
  type: SpaceType.balcony,
  areaSqFt: 10,
  sun: SunLevel.full,
  rainExposed: rainExposed,
  inContainerDefault: true,
);

CareEvent _event(
  CareEventType type,
  int offset, {
  String plantingId = 'p1',
}) => CareEvent(
  id: '$plantingId-${type.name}-$offset',
  plantingId: plantingId,
  type: type,
  at: _day(offset),
);

DateTime _waterDue({
  required List<CareEvent> events,
  required List<WeatherDay> weather,
  GrowSetup setup = GrowSetup.outdoor,
  bool inContainer = true,
  bool rainExposed = true,
  Plant? plant,
  DateTime? today,
}) => waterDue(
  _planting(setup: setup, inContainer: inContainer),
  plant ?? _kale(),
  _space(rainExposed: rainExposed),
  events,
  _days(weather),
  today ?? _planted,
);

void main() {
  final water0 = [_event(CareEventType.water, 0)];

  group('waterDue outdoor soil-moisture model', () {
    test('container kale with no rain is due on day 3 (fixture 1)', () {
      final due = _waterDue(
        events: water0,
        weather: [
          _wx(1, et0: 0.17),
          _wx(2, et0: 0.19),
          _wx(3, et0: 0.17),
        ],
      );
      expect(due, _day(3));
    });

    test('0.5 in rain on day 3 pushes the due date to day 6 (fixture 2)', () {
      final due = _waterDue(
        events: water0,
        weather: [
          _wx(1, et0: 0.17),
          _wx(2, et0: 0.19),
          _wx(3, et0: 0.17, precipIn: 0.5),
          _wx(4, et0: 0.15),
          _wx(5, et0: 0.16),
        ],
      );
      expect(due, _day(6));
    });

    test('rain is ignored when the space is not rain-exposed', () {
      final due = _waterDue(
        events: water0,
        rainExposed: false,
        weather: [
          _wx(1, et0: 0.17),
          _wx(2, et0: 0.19),
          _wx(3, et0: 0.17, precipIn: 0.5),
        ],
      );
      expect(due, _day(3));
    });

    test('container halves the threshold', () {
      final weather = [for (var i = 1; i <= 5; i++) _wx(i, et0: 0.17)];
      expect(_waterDue(events: water0, weather: weather), _day(3));
      expect(
        _waterDue(events: water0, weather: weather, inContainer: false),
        _day(5),
      );
    });

    test('deficit exactly at the threshold counts as due', () {
      // Low need: kc 0.5, threshold 1.0. ET 2.0 gives a deficit of exactly 1.0.
      final due = _waterDue(
        events: water0,
        inContainer: false,
        plant: _kale({
          'water': {
            'need': 'low',
            'everyDaysOutdoor': 3,
            'everyDaysIndoor': 3,
          },
        }),
        weather: [_wx(1, et0: 2.0)],
      );
      expect(due, _day(1));
    });

    test('skip_water on day 2 moves the clock to day 2', () {
      final due = _waterDue(
        events: [
          _event(CareEventType.water, 0),
          _event(CareEventType.skipWater, 2),
        ],
        weather: const [],
      );
      expect(due, _day(5));
    });

    test('events for other plantings are ignored', () {
      final due = _waterDue(
        events: [
          _event(CareEventType.water, 0),
          _event(CareEventType.skipWater, 2, plantingId: 'p2'),
        ],
        weather: [
          _wx(1, et0: 0.17),
          _wx(2, et0: 0.19),
          _wx(3, et0: 0.17),
        ],
      );
      expect(due, _day(3));
    });

    test('no water or skip event means due on the planted day', () {
      expect(_waterDue(events: const [], weather: const []), _day(0));
    });

    test('returns the end of the 3x window when nothing qualifies', () {
      final due = _waterDue(
        events: water0,
        weather: [
          for (var i = 1; i <= 9; i++) _wx(i, et0: 0, precipIn: 1.0),
        ],
      );
      expect(due, _day(9));
    });

    test('a due date before today is returned unchanged', () {
      final due = _waterDue(
        events: water0,
        today: _day(10),
        weather: [
          _wx(1, et0: 0.17),
          _wx(2, et0: 0.19),
          _wx(3, et0: 0.17),
        ],
      );
      expect(due, _day(3));
    });

    test('throws when the plant has no water data', () {
      expect(
        () => _waterDue(
          events: water0,
          weather: const [],
          plant: _kale({'water': null}),
        ),
        throwsArgumentError,
      );
    });
  });

  group('waterDue indoor', () {
    test('uses everyDaysIndoor and ignores weather', () {
      final due = _waterDue(
        events: water0,
        setup: GrowSetup.indoor,
        plant: _kale({
          'water': {
            'need': 'medium',
            'everyDaysOutdoor': 3,
            'everyDaysIndoor': 5,
          },
        }),
        weather: [
          for (var i = 1; i <= 9; i++) _wx(i, et0: 9, precipIn: 9),
        ],
      );
      expect(due, _day(5));
    });
  });
}
