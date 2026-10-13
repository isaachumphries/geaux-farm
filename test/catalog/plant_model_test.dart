import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';

List<Map<String, dynamic>> _records() =>
    (jsonDecode(File('assets/plants/plants.json').readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

/// A deep copy of the kale record with [edit] applied.
Plant _kaleWith(void Function(Map<String, dynamic> json) edit) {
  final json = jsonDecode(jsonEncode(_records().first)) as Map<String, dynamic>;
  edit(json);
  return Plant.fromJson(json);
}

void main() {
  final plants = {
    for (final r in _records()) r['id'] as String: Plant.fromJson(r),
  };

  group('reference records', () {
    final expected = <String, (MaintenanceLevel, String)>{
      'kale': (MaintenanceLevel.low, 'Harvest in 50–65 days'),
      'cherry-tomato': (MaintenanceLevel.medium, 'Harvest in 55–70 days'),
      'sweet-basil': (MaintenanceLevel.low, 'Harvest in 30–40 days'),
      'english-lavender': (MaintenanceLevel.low, 'Blooms in 60–90 days'),
    };
    expected.forEach((id, value) {
      test(id, () {
        final p = plants[id]!;
        expect(p.maintenanceLevel, value.$1);
        expect(p.timeToGrowLabel, value.$2);
        expect(p.scorable, isTrue);
      });
    });

    test('english-lavender zone numeric is 5.0–8.5', () {
      expect(plants['english-lavender']!.zoneNumeric, (min: 5.0, max: 8.5));
      expect(plants['kale']!.zoneNumeric, isNull);
    });
  });

  group('maintenanceLevel boundaries', () {
    final cases = {
      15: MaintenanceLevel.low,
      16: MaintenanceLevel.medium,
      40: MaintenanceLevel.medium,
      41: MaintenanceLevel.high,
    };
    cases.forEach((minutes, level) {
      test('weeklyMinutes $minutes → ${level.label}', () {
        final p = _kaleWith((j) => j['care']['weeklyMinutes'] = minutes);
        expect(p.maintenanceLevel, level);
      });
    });
  });

  test('zone strings: 8a = 8.0, 8b = 8.5, 10a = 10.0', () {
    expect(zoneNumericValue('8a'), 8.0);
    expect(zoneNumericValue('8b'), 8.5);
    expect(zoneNumericValue('10a'), 10.0);
    expect(() => zoneNumericValue('8c'), throwsFormatException);
  });

  group('timeToGrowLabel', () {
    Plant kind(String k, {int daysMax = 65}) => _kaleWith((j) {
      j['maturityKind'] = k;
      j['starts'][0]['daysMax'] = daysMax;
    });

    test('establish rounds months up', () {
      expect(
        kind('establish', daysMax: 90).timeToGrowLabel,
        'Settles in over ~3 months',
      );
      expect(
        kind('establish', daysMax: 91).timeToGrowLabel,
        'Settles in over ~4 months',
      );
    });
    test('foliage', () {
      expect(kind('foliage').timeToGrowLabel, 'Grows year-round');
    });
    test('bloom and harvest use starts[0]', () {
      expect(
        kind('bloom', daysMax: 80).timeToGrowLabel,
        'Blooms in 50–80 days',
      );
      expect(kind('harvest').timeToGrowLabel, 'Harvest in 50–65 days');
    });
  });

  group('scorable', () {
    test('false when water is missing', () {
      expect(_kaleWith((j) => j.remove('water')).scorable, isFalse);
    });
    test('false when sun is empty', () {
      expect(_kaleWith((j) => j['sun'] = <String>[]).scorable, isFalse);
    });
    test('false for a perennial with zones missing', () {
      expect(_kaleWith((j) => j['lifecycle'] = 'perennial').scorable, isFalse);
    });
  });

  group('fromJson errors name the record id', () {
    test('missing required field', () {
      expect(
        () => _kaleWith((j) => j.remove('difficulty')),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('kale'), contains('difficulty')),
          ),
        ),
      );
    });
    test('wrong-typed field', () {
      expect(
        () => _kaleWith((j) => j['difficulty'] = '1'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('kale'),
          ),
        ),
      );
    });
    test('unknown sun value', () {
      expect(
        () => _kaleWith((j) => j['sun'] = ['bright']),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('kale'),
          ),
        ),
      );
    });
  });
}
