import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/rain_hint.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';

final _today = DateTime(2026, 5, 10);
final _tomorrow = DateTime(2026, 5, 11);

WeatherDay _wx({double precipIn = 0.5, int? precipProb = 80}) => WeatherDay(
  date: '2026-05-11',
  weatherCode: 61,
  tmaxF: 80,
  tminF: 60,
  precipIn: precipIn,
  precipProb: precipProb,
  uvMax: null,
  sunshineS: 0,
  daylightS: 0,
  et0In: 0.1,
  sunrise: '',
  sunset: '',
);

Map<DateTime, WeatherDay> _days(WeatherDay wx) => {_tomorrow: wx};

Planting _planting({GrowSetup setup = GrowSetup.outdoor}) => Planting(
  id: 'p1',
  plantId: 'kale',
  spaceId: 's1',
  nickname: 'Kale',
  setup: setup,
  inContainer: true,
  startMethod: 'transplant',
  status: PlantingStatus.active,
  createdAt: _today,
  plantedOn: _today,
);

Space _space({bool rainExposed = true}) => Space(
  id: 's1',
  type: SpaceType.balcony,
  areaSqFt: 10,
  sun: SunLevel.full,
  rainExposed: rainExposed,
  inContainerDefault: true,
);

bool _hint({
  Planting? pl,
  Space? s,
  DateTime? due,
  Map<DateTime, WeatherDay>? days,
}) => rainHint(
  pl: pl ?? _planting(),
  s: s ?? _space(),
  due: due ?? _today,
  today: _today,
  days: days ?? _days(_wx()),
);

void main() {
  test('shows the hint at 0.25 in and 70% for an outdoor exposed task', () {
    expect(_hint(days: _days(_wx(precipIn: 0.25, precipProb: 70))), isTrue);
  });

  test('hides the hint just below 0.25 in', () {
    expect(_hint(days: _days(_wx(precipIn: 0.24, precipProb: 70))), isFalse);
  });

  test('hides the hint just below 70%', () {
    expect(_hint(days: _days(_wx(precipIn: 0.25, precipProb: 69))), isFalse);
  });

  test('a null precipitation probability counts as no rain', () {
    expect(_hint(days: _days(_wx(precipIn: 0.5, precipProb: null))), isFalse);
  });

  test('hides the hint for indoor plantings', () {
    expect(_hint(pl: _planting(setup: GrowSetup.indoor)), isFalse);
  });

  test('hides the hint for spaces that are not rain-exposed', () {
    expect(_hint(s: _space(rainExposed: false)), isFalse);
  });

  test('hides the hint when the task is due after tomorrow', () {
    expect(_hint(due: DateTime(2026, 5, 12)), isFalse);
  });

  test('shows the hint for a task already overdue', () {
    expect(_hint(due: DateTime(2026, 5, 8)), isTrue);
  });
}
