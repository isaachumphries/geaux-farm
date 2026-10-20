// plan/03 § Derived values and § API importer readiness (scorable).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';

/// The kale record (a biennial) with top-level [changes] merged in.
Plant kaleWith(Map<String, dynamic> changes) => Plant.fromJson({
  ...(jsonDecode(
        File('assets/plants/plants.json').readAsStringSync(),
      ) as List).first
      as Map<String, dynamic>,
  ...changes,
});

void main() {
  group('scorable requires every scoring field', () {
    test('the full kale record (biennial, zones null) is scorable', () {
      expect(kaleWith({}).scorable, isTrue);
    });

    final missing = <String, Object?>{
      'sun': null,
      'plantTempF': null,
      'growTempF': null,
      'starts': null,
      'water': null,
      'space': null,
    };
    missing.forEach((field, value) {
      test('false when $field is missing', () {
        expect(kaleWith({field: value}).scorable, isFalse);
      });
    });

    test('false when starts is empty', () {
      expect(kaleWith({'starts': <Object>[]}).scorable, isFalse);
    });

    test('zones is required only for perennials', () {
      expect(kaleWith({'lifecycle': 'annual'}).scorable, isTrue);
      expect(
        kaleWith({
          'lifecycle': 'perennial',
          'zones': {'min': '5a', 'max': '8b'},
        }).scorable,
        isTrue,
      );
    });
  });

  group('time-to-grow label without starts', () {
    test('foliage still reads "Grows year-round"', () {
      expect(
        kaleWith({'maturityKind': 'foliage', 'starts': null}).timeToGrowLabel,
        'Grows year-round',
      );
    });
    for (final kind in ['harvest', 'bloom', 'establish']) {
      test('$kind has no label', () {
        expect(
          kaleWith({'maturityKind': kind, 'starts': null}).timeToGrowLabel,
          isNull,
        );
        expect(
          kaleWith({'maturityKind': kind, 'starts': <Object>[]})
              .timeToGrowLabel,
          isNull,
        );
      });
    }
  });

  group('time-to-grow label uses starts[0] for every kind', () {
    final starts = [
      {'method': 'transplant', 'daysMin': 20, 'daysMax': 59},
      {'method': 'seed', 'daysMin': 70, 'daysMax': 200},
    ];
    final expected = {
      'harvest': 'Harvest in 20–59 days',
      'bloom': 'Blooms in 20–59 days',
      'establish': 'Settles in over ~2 months',
      'foliage': 'Grows year-round',
    };
    expected.forEach((kind, label) {
      test(kind, () {
        expect(
          kaleWith({'maturityKind': kind, 'starts': starts}).timeToGrowLabel,
          label,
        );
      });
    });
  });

  group('zone numeric value', () {
    final cases = {'1a': 1.0, '1b': 1.5, '8a': 8.0, '8b': 8.5, '13b': 13.5};
    cases.forEach((zone, value) {
      test('$zone = $value', () {
        expect(zoneNumericValue(zone), value);
      });
    });
    for (final bad in ['8', 'b', '8A', '108a', 'x8a', '8ab']) {
      test('"$bad" is rejected', () {
        expect(() => zoneNumericValue(bad), throwsFormatException);
      });
    }
    test('a range 9b–11a covers [9.5, 11.0]', () {
      expect(
        kaleWith({
          'lifecycle': 'perennial',
          'zones': {'min': '9b', 'max': '11a'},
        }).zoneNumeric,
        (min: 9.5, max: 11.0),
      );
    });
  });
}
