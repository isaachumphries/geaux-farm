import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/care_reminders.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/weather/domain/garden_alerts.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';

/// Wednesday, Oct 7 2026.
final _today = DateTime(2026, 10, 7);

/// A mild day [offset] days from today, with the given extremes.
WeatherDay _day(
  int offset, {
  double tmin = 60,
  double tmax = 80,
  double precip = 0,
  double? uv = 3,
}) {
  final d = DateTime(_today.year, _today.month, _today.day + offset);
  final key =
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  return WeatherDay(
    date: key,
    weatherCode: 0,
    tmaxF: tmax,
    tminF: tmin,
    precipIn: precip,
    precipProb: 0,
    uvMax: uv,
    sunshineS: 0,
    daylightS: 0,
    et0In: 0,
    sunrise: '${key}T07:00',
    sunset: '${key}T18:30',
  );
}

OutdoorPlanting _plant(
  String name, [
  FrostTolerance tol = FrostTolerance.none,
  bool sprouting = false,
]) => OutdoorPlanting(name: name, frostTolerance: tol, sprouting: sprouting);

List<GardenAlert> _eval(
  List<WeatherDay> days, {
  List<OutdoorPlanting>? plantings,
}) => evaluateAlerts(
  forecast: days,
  today: _today,
  plantings: plantings ?? [_plant('Kale')],
);

List<GardenAlertType> _types(List<GardenAlert> alerts) => [
  for (final a in alerts) a.type,
];

void main() {
  group('thresholds fire at the boundary, not one unit past it', () {
    final frostCases = [
      (FrostTolerance.none, 34.0, true),
      (FrostTolerance.none, 35.0, false),
      (FrostTolerance.light, 28.0, true),
      (FrostTolerance.light, 29.0, false),
      (FrostTolerance.hard, 20.0, true),
      (FrostTolerance.hard, 21.0, false),
    ];
    for (final (tol, tmin, fires) in frostCases) {
      test('frost ${tol.name} at $tmin °F: ${fires ? 'yes' : 'no'}', () {
        final alerts = _eval(
          [_day(0, tmin: tmin)],
          plantings: [_plant('Kale', tol)],
        );
        expect(_types(alerts), fires ? [GardenAlertType.frost] : isEmpty);
      });
    }

    for (final (tmax, fires) in [(95.0, true), (94.0, false)]) {
      test('heat at $tmax °F: ${fires ? 'yes' : 'no'}', () {
        expect(
          _types(_eval([_day(0, tmax: tmax)])),
          fires ? [GardenAlertType.heat] : isEmpty,
        );
      });
    }

    for (final (precip, fires) in [(1.00, true), (0.99, false)]) {
      test('rain at $precip in: ${fires ? 'yes' : 'no'}', () {
        expect(
          _types(_eval([_day(0, precip: precip)])),
          fires ? [GardenAlertType.rain] : isEmpty,
        );
      });
    }

    for (final (uv, fires) in [(8.0, true), (7.9, false)]) {
      test('UV $uv with a sprouting planting: ${fires ? 'yes' : 'no'}', () {
        final alerts = _eval(
          [_day(0, uv: uv)],
          plantings: [_plant('Kale', FrostTolerance.none, true)],
        );
        expect(_types(alerts), fires ? [GardenAlertType.uv] : isEmpty);
      });
    }
  });

  group('copy', () {
    test('frost names every planting whose threshold is met', () {
      final alerts = _eval(
        [_day(1, tmin: 27)],
        plantings: [
          _plant('Basil', FrostTolerance.none),
          _plant('Kale', FrostTolerance.hard),
          _plant('Big Lettuce', FrostTolerance.light),
        ],
      );
      expect(
        alerts.single.message,
        'Frost Thu: cover or bring in Basil, Big Lettuce',
      );
      expect(alerts.single.day, DateTime(2026, 10, 8));
    });

    test('heat, rain, and UV use the plan/06 copy', () {
      final alerts = _eval(
        [_day(0, tmax: 99, precip: 2, uv: 10)],
        plantings: [_plant('Kale', FrostTolerance.none, true)],
      );
      expect(
        [for (final a in alerts) a.message],
        [
          'Heat Wed: water early and shade young plants',
          'Heavy rain Wed: check drainage — your watering schedule already '
              'accounts for it',
          'High UV today: shade new seedlings at midday',
        ],
      );
    });
  });

  group('window and preconditions', () {
    test('today..today+2 count; today+3 and yesterday are ignored', () {
      final alerts = _eval([
        _day(-1, tmax: 100),
        _day(0, tmax: 100),
        _day(1, tmax: 100),
        _day(2, tmax: 100),
        _day(3, tmax: 100),
      ]);
      expect(
        [for (final a in alerts) a.day],
        [DateTime(2026, 10, 7), DateTime(2026, 10, 8), DateTime(2026, 10, 9)],
      );
    });

    test('results come in day order whatever the row order', () {
      final alerts = _eval([_day(2, tmax: 100), _day(0, tmax: 100)]);
      expect(alerts.first.day, DateTime(2026, 10, 7));
    });

    test('no active outdoor plantings → no alerts', () {
      expect(
        _eval([_day(0, tmin: 10, tmax: 100, precip: 3, uv: 11)], plantings: []),
        isEmpty,
      );
    });

    test('UV needs a sprouting planting', () {
      expect(_eval([_day(0, uv: 11)]), isEmpty);
    });

    test('UV only counts today', () {
      final alerts = _eval(
        [_day(1, uv: 11)],
        plantings: [_plant('Kale', FrostTolerance.none, true)],
      );
      expect(alerts, isEmpty);
    });

    test('a day with no UV reading raises no UV alert', () {
      final alerts = _eval(
        [_day(0, uv: null)],
        plantings: [_plant('Kale', FrostTolerance.none, true)],
      );
      expect(alerts, isEmpty);
    });
  });

  group('frost-eve notices', () {
    GardenAlert frost(int offset) => GardenAlert(
      type: GardenAlertType.frost,
      day: DateTime(2026, 10, 7 + offset),
      message: 'Frost day+$offset',
    );

    test('fire at 18:00 the evening before the frost day', () {
      final notices = planFrostNotices([frost(2)], DateTime(2026, 10, 7, 9));
      expect(notices.single.at, DateTime(2026, 10, 8, 18));
      expect(notices.single.body, 'Frost day+2');
      expect(notices.single.id, weatherAlertIdBase);
    });

    test('an evening already past is not scheduled', () {
      // Frost tomorrow: tonight 18:00 has passed at 18:00 sharp and later.
      expect(planFrostNotices([frost(1)], DateTime(2026, 10, 7, 18)), isEmpty);
      expect(
        planFrostNotices([frost(1)], DateTime(2026, 10, 7, 17, 59)),
        hasLength(1),
      );
      // Frost today: last night's 18:00 is gone.
      expect(planFrostNotices([frost(0)], DateTime(2026, 10, 7, 9)), isEmpty);
    });

    test('four frost days keep the three soonest', () {
      final notices = planFrostNotices([
        frost(4),
        frost(2),
        frost(3),
        frost(1),
      ], DateTime(2026, 10, 7, 9));
      expect(
        [for (final n in notices) n.body],
        ['Frost day+1', 'Frost day+2', 'Frost day+3'],
      );
      expect([for (final n in notices) n.id], [1000, 1001, 1002]);
    });

    test('only frost alerts become notices', () {
      final heat = GardenAlert(
        type: GardenAlertType.heat,
        day: DateTime(2026, 10, 9),
        message: 'Heat Fri',
      );
      expect(planFrostNotices([heat], DateTime(2026, 10, 7, 9)), isEmpty);
    });

    test('the reserved ids never meet a care reminder id', () {
      for (var i = 0; i < weatherAlertBudget; i++) {
        expect(isWeatherAlertId(weatherAlertIdBase + i), isTrue);
      }
      expect(isWeatherAlertId(weatherAlertIdBase - 1), isFalse);
      expect(
        isWeatherAlertId(weatherAlertIdBase + weatherAlertBudget),
        isFalse,
      );
      // Care ids are minutes since the epoch of a future slot.
      expect(
        isWeatherAlertId(careReminderId(DateTime.utc(2026, 10, 7, 8))),
        isFalse,
      );
      expect(
        careReminderId(DateTime.utc(2000)),
        greaterThan(weatherAlertIdBase + weatherAlertBudget),
      );
    });
  });
}
