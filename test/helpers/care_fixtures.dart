import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/care/domain/schedule_math.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';

import '../recommendations/fixtures/baton_rouge.dart';

/// Friday 2026-05-01: the planting date in every care fixture.
final carePlanted = DateTime(2026, 5, 1);

/// Every block of every day free.
final careAllFree = Availability(List.filled(7, 255));

/// Free blocks by weekday (1 = Monday). Block b is 06:00 + 2h × b.
Availability careFree(Map<int, List<int>> blocksByWeekday) {
  final days = List<int>.filled(7, 0);
  blocksByWeekday.forEach((weekday, blocks) {
    for (final b in blocks) {
      days[weekday - 1] |= 1 << b;
    }
  });
  return Availability(days);
}

/// Reference kale with its care tasks replaced by [tasks].
Plant carePlant({List<Map<String, Object>> tasks = const []}) =>
    Plant.fromJson({
      ...rawKale(),
      'care': {'dailyMinutes': 5, 'weeklyMinutes': 10, 'tasks': tasks},
    });

Planting carePlanting({
  String id = 'p1',
  String nickname = 'Kale',
  PlantingStatus status = PlantingStatus.active,
  bool planted = true,
}) => Planting(
  id: id,
  plantId: 'kale',
  spaceId: 's1',
  nickname: nickname,
  setup: GrowSetup.outdoor,
  inContainer: true,
  startMethod: 'transplant',
  status: status,
  createdAt: carePlanted,
  plantedOn: planted ? carePlanted : null,
);

Space careSpace() => Space(
  id: 's1',
  type: SpaceType.balcony,
  areaSqFt: 10,
  sun: SunLevel.full,
  sunUnsure: false,
  rainExposed: true,
  inContainerDefault: true,
  isPrimary: true,
);

/// Fourteen hot, dry days from planting: water comes due within a day or two.
Map<DateTime, WeatherDay> careHotWeather() {
  final rows = <DateTime, WeatherDay>{};
  for (var i = 0; i < 14; i++) {
    final day = addDays(carePlanted, i);
    rows[day] = WeatherDay(
      date: _iso(day),
      weatherCode: 0,
      tmaxF: 90,
      tminF: 70,
      precipIn: 0,
      precipProb: null,
      uvMax: null,
      sunshineS: 0,
      daylightS: 0,
      et0In: 2.0,
      sunrise: '',
      sunset: '',
    );
  }
  return rows;
}

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
