// Rain hint conditions not pinned by rain_hint_test.dart (plan/05 § Watering
// model, "Rain hint"): due ≤ tomorrow at its edge, greenhouse setup, and that
// only tomorrow's forecast row is read.
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/rain_hint.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';

final _today = DateTime(2026, 7, 14);
final _tomorrow = DateTime(2026, 7, 15);

WeatherDay _wet(String date) => WeatherDay(
  date: date,
  weatherCode: 63,
  tmaxF: 90,
  tminF: 74,
  precipIn: 0.25,
  precipProb: 70,
  uvMax: null,
  sunshineS: 0,
  daylightS: 0,
  et0In: 0.15,
  sunrise: '',
  sunset: '',
);

Planting _planting(GrowSetup setup) => Planting(
  id: 'p1',
  plantId: 'kale',
  spaceId: 's1',
  nickname: 'Kale',
  setup: setup,
  inContainer: false,
  startMethod: 'transplant',
  status: PlantingStatus.active,
  createdAt: _today,
  plantedOn: _today,
);

final _space = Space(
  id: 's1',
  type: SpaceType.smallYard,
  areaSqFt: 40,
  sun: SunLevel.full,
  rainExposed: true,
  inContainerDefault: false,
);

bool _hint({
  GrowSetup setup = GrowSetup.outdoor,
  DateTime? due,
  DateTime? today,
  Map<DateTime, WeatherDay>? days,
}) => rainHint(
  pl: _planting(setup),
  s: _space,
  due: due ?? _today,
  today: today ?? _today,
  days: days ?? {_tomorrow: _wet('2026-07-15')},
);

void main() {
  test('a task due exactly tomorrow gets the hint (due ≤ tomorrow)', () {
    expect(_hint(due: _tomorrow), isTrue);
  });

  test('a greenhouse planting never gets the hint', () {
    expect(_hint(setup: GrowSetup.greenhouse), isFalse);
  });

  test('no forecast row for tomorrow means no hint', () {
    expect(_hint(days: const {}), isFalse);
  });

  test("rain in today's row does not count; only tomorrow's does", () {
    expect(_hint(days: {_today: _wet('2026-07-14')}), isFalse);
  });

  test('tomorrow is the next calendar day even late at night', () {
    final lateToday = DateTime(2026, 7, 14, 23, 30);
    expect(_hint(today: lateToday, due: _tomorrow), isTrue);
    expect(_hint(today: lateToday, due: DateTime(2026, 7, 16)), isFalse);
  });
}
