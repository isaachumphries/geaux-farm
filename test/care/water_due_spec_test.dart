// Watering model spec conformance (plan/05 § Watering model): the kc and
// threshold table, the container factor, the fallback rate, the zero floor,
// the 3·everyDaysOutdoor search cap, the indoor/greenhouse interval, and how
// L (last water or skip) is chosen.
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/care/domain/schedule_math.dart';
import 'package:geaux_farm/features/care/domain/water_due.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';

import '../recommendations/fixtures/baton_rouge.dart';

final _l = DateTime(2026, 6, 1);

DateTime _day(int offset) => addDays(_l, offset);

WeatherDay _wx(int offset, {required double et0, double precipIn = 0}) {
  final d = _day(offset);
  return WeatherDay(
    date:
        '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}',
    weatherCode: 0,
    tmaxF: 85,
    tminF: 65,
    precipIn: precipIn,
    precipProb: null,
    uvMax: null,
    sunshineS: 0,
    daylightS: 0,
    et0In: et0,
    sunrise: '',
    sunset: '',
  );
}

Map<DateTime, WeatherDay> _days(List<WeatherDay> rows) => {
  for (final r in rows) DateTime.parse(r.date): r,
};

Plant _plant(String need, {int outdoor = 3, int indoor = 4}) => Plant.fromJson({
  ...rawKale(),
  'water': {
    'need': need,
    'everyDaysOutdoor': outdoor,
    'everyDaysIndoor': indoor,
  },
});

Planting _planting({
  GrowSetup setup = GrowSetup.outdoor,
  bool inContainer = false,
  bool planted = true,
}) => Planting(
  id: 'p1',
  plantId: 'kale',
  spaceId: 's1',
  nickname: 'Kale',
  setup: setup,
  inContainer: inContainer,
  startMethod: 'transplant',
  status: PlantingStatus.active,
  createdAt: _l,
  plantedOn: planted ? _l : null,
);

final _space = Space(
  id: 's1',
  type: SpaceType.smallYard,
  areaSqFt: 40,
  sun: SunLevel.full,
  rainExposed: true,
  inContainerDefault: false,
);

CareEvent _event(CareEventType type, DateTime at) =>
    CareEvent(id: '${type.name}-$at', plantingId: 'p1', type: type, at: at);

final _watered = [_event(CareEventType.water, _l)];

List<double> _trace(
  Plant p,
  List<WeatherDay> weather, {
  bool inContainer = false,
}) => deficitTrace(
  _planting(inContainer: inContainer),
  p,
  _space,
  _l,
  _days(weather),
);

DateTime _due(
  Plant p,
  List<WeatherDay> weather, {
  bool inContainer = false,
  GrowSetup setup = GrowSetup.outdoor,
  List<CareEvent>? events,
}) => waterDue(
  _planting(setup: setup, inContainer: inContainer),
  p,
  _space,
  events ?? _watered,
  _days(weather),
  _l,
);

void main() {
  // plan/05 § Watering model, need table.
  const table = {
    'low': (kc: 0.5, threshold: 1.0),
    'medium': (kc: 0.8, threshold: 0.6),
    'high': (kc: 1.05, threshold: 0.4),
  };

  group('kc by water need', () {
    for (final MapEntry(key: need, value: row) in table.entries) {
      test('$need uses kc ${row.kc}: one day of ET0 1.0 adds ${row.kc}', () {
        final trace = _trace(_plant(need), [_wx(1, et0: 1.0)]);
        expect(trace.first, closeTo(row.kc, 1e-9));
      });
    }
  });

  group('threshold by water need, x0.5 in a container', () {
    for (final MapEntry(key: need, value: row) in table.entries) {
      for (final container in [false, true]) {
        final t = row.threshold * (container ? 0.5 : 1.0);
        final where = container ? 'in a container' : 'in the ground';

        test('$need $where is due the day the deficit reaches $t', () {
          final due = _due(_plant(need), [
            _wx(1, et0: t / row.kc),
          ], inContainer: container);
          expect(due, _day(1));
        });

        test('$need $where is not due 1e-6 in below $t', () {
          // Day 2 has no data, so the fallback rate pushes it over.
          final due = _due(_plant(need), [
            _wx(1, et0: (t - 1e-6) / row.kc),
          ], inContainer: container);
          expect(due, _day(2));
        });
      }
    }
  });

  test('fallback adds threshold / everyDaysOutdoor per missing day', () {
    // High need in a container: threshold 0.4 x 0.5 = 0.2, n = 4 -> 0.05/day.
    final trace = _trace(_plant('high', outdoor: 4), [], inContainer: true);
    expect(trace, hasLength(4));
    for (var i = 0; i < 4; i++) {
      expect(trace[i], closeTo(0.05 * (i + 1), 1e-9), reason: 'day ${i + 1}');
    }
  });

  test('a missing day between weather days uses the fallback rate', () {
    // Medium, in the ground: threshold 0.6, fallback 0.2. Day 2 is missing.
    final trace = _trace(_plant('medium'), [
      _wx(1, et0: 0.1),
      _wx(3, et0: 0.1),
      _wx(4, et0: 0.5),
    ]);
    expect(trace, hasLength(4));
    expect(trace[0], closeTo(0.08, 1e-9));
    expect(trace[1], closeTo(0.28, 1e-9));
    expect(trace[2], closeTo(0.36, 1e-9));
    expect(trace[3], closeTo(0.76, 1e-9));
  });

  test('rain larger than the deficit floors it at 0, not below', () {
    // Medium, in the ground (kc 0.8, threshold 0.6). Day 2 effective rain
    // 0.8 wipes the 0.136 deficit; day 3 restarts from 0, not from -0.528.
    final trace = _trace(_plant('medium'), [
      _wx(1, et0: 0.17),
      _wx(2, et0: 0.17, precipIn: 1.0),
      _wx(3, et0: 0.17),
      _wx(4, et0: 0.17),
      _wx(5, et0: 0.17),
      _wx(6, et0: 0.17),
    ]);
    expect(trace[1], 0);
    expect(trace[2], closeTo(0.136, 1e-9));
    // Days 3-6 add 0.136 each (0.544), day 7 falls back (+0.2) and is due.
    expect(trace, hasLength(7));
  });

  test('search stops at L + 3 x everyDaysOutdoor', () {
    // n = 2: six days that never reach the threshold, then a day that would.
    final weather = [
      for (var i = 1; i <= 6; i++) _wx(i, et0: 0),
      _wx(7, et0: 10),
    ];
    final p = _plant('medium', outdoor: 2);
    expect(_trace(p, weather), hasLength(6));
    expect(_due(p, weather), _day(6));
  });

  group('indoor and greenhouse: due = L + everyDaysIndoor', () {
    final hot = [for (var i = 1; i <= 9; i++) _wx(i, et0: 5)];

    for (final setup in [GrowSetup.indoor, GrowSetup.greenhouse]) {
      test('${setup.name} ignores the deficit model', () {
        final p = _plant('high', outdoor: 2, indoor: 6);
        expect(_due(p, hot), _day(1));
        expect(_due(p, hot, setup: setup), _day(6));
      });
    }

    test('indoor with no water or skip event is due on planted_on', () {
      expect(
        _due(_plant('low'), hot, setup: GrowSetup.indoor, events: const []),
        _l,
      );
    });
  });

  group('L is the latest water or skip_water day', () {
    final p = _plant('medium', indoor: 5);

    test('the latest event wins regardless of list order', () {
      final events = [
        _event(CareEventType.water, _day(4)),
        _event(CareEventType.skipWater, _day(2)),
      ];
      expect(_due(p, [], setup: GrowSetup.indoor, events: events), _day(9));
    });

    test('fertilize, prune, harvest and note events do not reset L', () {
      final events = [
        _event(CareEventType.water, _l),
        for (final t in [
          CareEventType.fertilize,
          CareEventType.prune,
          CareEventType.harvest,
          CareEventType.note,
        ])
          _event(t, _day(3)),
      ];
      expect(_due(p, [], setup: GrowSetup.indoor, events: events), _day(5));
    });
  });

  group('error paths', () {
    test('waterDue throws StateError when the planting has no date', () {
      expect(
        () => waterDue(
          _planting(planted: false),
          _plant('low'),
          _space,
          _watered,
          const {},
          _l,
        ),
        throwsStateError,
      );
    });

    test('deficitTrace throws ArgumentError when the plant has no water', () {
      expect(
        () => deficitTrace(
          _planting(),
          Plant.fromJson({...rawKale(), 'water': null}),
          _space,
          _l,
          const {},
        ),
        throwsArgumentError,
      );
    });
  });
}
