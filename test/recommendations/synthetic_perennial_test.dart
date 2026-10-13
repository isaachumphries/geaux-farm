import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/recommendations/domain/score_plant.dart';

import 'fixtures/baton_rouge.dart';

/// Kale record reshaped into a perennial with [zones] and [humidity].
Plant perennial({
  required String min,
  required String max,
  String humidity = 'any',
}) {
  final json =
      (jsonDecode(
            File('assets/plants/plants.json').readAsStringSync(),
          ) as List).first
          as Map<String, dynamic>;
  return Plant.fromJson({
    ...json,
    'lifecycle': 'perennial',
    'zones': {'min': min, 'max': max},
    'growTempF': {'min': 55, 'max': 95},
    'humidity': humidity,
  });
}

void main() {
  final tropical = perennial(min: '10a', max: '12b');

  test('outdoor at 8b, zones 10a–12b: climate 0 and indoorOnly', () {
    final c = scorePlant(
      tropical,
      workedExample,
      GrowSetup.outdoor,
      workedExampleDate,
    );
    expect(c.fits['climate'], 0);
    expect(c.outdoorViable, isFalse);
    // Card state indoorOnly = outdoor setup and not outdoorViable.
  });

  test('indoor at 8b: climate 1 (55 ≤ 65 and 95 ≥ 75)', () {
    final c = scorePlant(
      tropical,
      workedExample,
      GrowSetup.indoor,
      workedExampleDate,
    );
    expect(c.fits['climate'], 1);
    expect(c.outdoorViable, isFalse);
  });

  test('zone distance: inside 1, ≤ 1.0 outside 0.5, beyond 0', () {
    double fit(String min, String max) => scorePlant(
      perennial(min: min, max: max),
      workedExample,
      GrowSetup.outdoor,
      workedExampleDate,
    ).fits['climate']!;
    expect(fit('8b', '9a'), 1);
    expect(fit('9b', '11a'), 0.5); // 9.5 − 8.5 = 1.0
    expect(fit('10a', '11a'), 0); // 1.5 below
    expect(fit('5a', '7b'), 0.5); // 8.5 − 7.5 = 1.0
    expect(fit('5a', '7a'), 0); // 1.5 above
  });

  test('high-humidity plant loses ×0.8 indoors (RH 40 < 45)', () {
    final humid = perennial(min: '8a', max: '9a', humidity: 'high');
    expect(
      scorePlant(
        humid,
        workedExample,
        GrowSetup.indoor,
        workedExampleDate,
      ).fits['climate'],
      closeTo(0.8, 1e-9),
    );
    // Outdoors RH 75 ≥ 45: no penalty.
    expect(
      scorePlant(
        humid,
        workedExample,
        GrowSetup.outdoor,
        workedExampleDate,
      ).fits['climate'],
      1,
    );
  });
}
