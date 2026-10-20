// Validation for assets/plants/plants.json (plan/03 § Validation rules).
//
// `strictCatalog` stays false until the catalog is complete: #52 sets it to
// true, which turns on the "credit/license not TBD" and "every seed id
// present" checks.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';

const bool strictCatalog = false;

final _kebab = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

const _seedIds = [
  'cherry-tomato',
  'bell-pepper',
  'jalapeno',
  'okra',
  'eggplant',
  'cucumber',
  'zucchini',
  'bush-bean',
  'sweet-potato',
  'lettuce',
  'spinach',
  'kale',
  'collard-greens',
  'swiss-chard',
  'radish',
  'snap-pea',
  'carrot',
  'broccoli',
  'microgreens',
  'sweet-basil',
  'mint',
  'rosemary',
  'thyme',
  'oregano',
  'parsley',
  'cilantro',
  'dill',
  'chives',
  'sage',
  'green-onion',
  'strawberry',
  'rabbiteye-blueberry',
  'meyer-lemon',
  'fig',
  'satsuma',
  'marigold',
  'zinnia',
  'sunflower',
  'nasturtium',
  'petunia',
  'pansy',
  'snapdragon',
  'cosmos',
  'english-lavender',
  'purple-coneflower',
  'black-eyed-susan',
  'boxwood',
  'azalea',
  'gardenia',
  'bigleaf-hydrangea',
  'camellia',
  'knock-out-rose',
  'dwarf-yaupon-holly',
  'indian-hawthorn',
  'pothos',
  'snake-plant',
  'peace-lily',
  'spider-plant',
  'zz-plant',
  'aloe-vera',
];

/// Every per-record rule from plan/03 that does not need the bundle.
/// Returns the list of violations (empty when valid).
List<String> validateRecord(Map<String, dynamic> json) {
  final Plant p;
  try {
    p = Plant.fromJson(json);
  } on FormatException catch (e) {
    return ['parse: ${e.message}'];
  }
  final errors = <String>[];
  void range(String name, num min, num max) {
    if (min > max) errors.add('$name min > max');
  }

  if (!_kebab.hasMatch(p.id)) errors.add('id not kebab-case');
  if (p.commonName.isEmpty || p.scientificName.isEmpty) {
    errors.add('empty name');
  }
  if (p.purposes.isEmpty) errors.add('purposes empty');
  if (p.seasonTags.isEmpty || p.seasonTags.length > 2) {
    errors.add('seasonTags must have 1–2 values');
  }
  if (![1, 2, 3].contains(p.difficulty)) errors.add('difficulty not 1–3');
  if (p.sun == null || p.sun!.isEmpty) errors.add('sun empty');
  if (p.plantTempF case final r?) range('plantTempF', r.min, r.max);
  if (p.growTempF case final r?) range('growTempF', r.min, r.max);
  if (p.zoneNumeric case final z?) range('zones', z.min, z.max);
  if ((p.zones != null) != (p.lifecycle == Lifecycle.perennial)) {
    errors.add('zones present iff perennial');
  }
  if (p.starts == null || p.starts!.isEmpty) errors.add('starts empty');
  for (final s in p.starts ?? const <PlantStart>[]) {
    range('starts', s.daysMin, s.daysMax);
  }
  if (p.productiveDays < 0) errors.add('productiveDays < 0');
  if (p.space case final s?) {
    if (s.sqFtPerPlant <= 0) errors.add('sqFtPerPlant ≤ 0');
    if ((s.minContainerGal != null) != s.containerOk) {
      errors.add('minContainerGal present iff containerOk');
    }
  }
  if (p.water case final w?) {
    if (w.everyDaysOutdoor < 1 || w.everyDaysIndoor < 1) {
      errors.add('water everyDays < 1');
    }
  }
  if (p.tips.length < 2 || p.tips.length > 4) errors.add('tips not 2–4');
  if (p.tips.any((t) => t.length > 140)) errors.add('tip over 140 chars');
  if (p.source != 'curated') errors.add('source not curated');
  return errors;
}

void main() {
  final records = (jsonDecode(
    File('assets/plants/plants.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> kaleWith(void Function(Map<String, dynamic>) edit) {
    final copy = jsonDecode(jsonEncode(records.first)) as Map<String, dynamic>;
    edit(copy);
    return copy;
  }

  test('contains the four reference records', () {
    final ids = records.map((r) => r['id']);
    expect(
      ids,
      containsAll(['kale', 'cherry-tomato', 'sweet-basil', 'english-lavender']),
    );
  });

  test('ids are unique and kebab-case', () {
    final ids = records.map((r) => r['id'] as String).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, everyElement(matches(_kebab)));
  });

  test('every record passes validation', () {
    for (final r in records) {
      expect(validateRecord(r), isEmpty, reason: r['id'] as String);
    }
  });

  test('every record derives scorable', () {
    for (final r in records) {
      expect(Plant.fromJson(r).scorable, isTrue, reason: r['id'] as String);
    }
  });

  test('zones is non-null exactly for perennial records', () {
    for (final r in records) {
      expect(
        r['zones'] != null,
        r['lifecycle'] == 'perennial',
        reason: r['id'] as String,
      );
    }
  });

  test('every record is containerOk with a minContainerGal', () {
    for (final r in records) {
      expect(r['space']['containerOk'], isTrue);
      expect(r['space']['minContainerGal'], isNotNull);
    }
  });

  test('starts is non-empty for every record', () {
    for (final r in records) {
      expect(r['starts'], isNotEmpty);
    }
  });

  group('validator rejects bad fixtures', () {
    final cases = <String, void Function(Map<String, dynamic>)>{
      'category tree': (j) => j['category'] = 'tree',
      'growTempF 90–50': (j) => j['growTempF'] = {'min': 90, 'max': 50},
      'plantTempF 80–40': (j) => j['plantTempF'] = {'min': 80, 'max': 40},
      'starts daysMin > daysMax': (j) => j['starts'][0]['daysMin'] = 99,
      'zones 8b–5a': (j) => j
        ..['lifecycle'] = 'perennial'
        ..['zones'] = {'min': '8b', 'max': '5a'},
      'zones on an annual': (j) => j['zones'] = {'min': '5a', 'max': '8b'},
      'perennial without zones': (j) => j['lifecycle'] = 'perennial',
      'containerOk without minContainerGal': (j) =>
          j['space']['minContainerGal'] = null,
      'minContainerGal without containerOk': (j) =>
          j['space']['containerOk'] = false,
      'empty starts': (j) => j['starts'] = <Object>[],
      'id with uppercase': (j) => j['id'] = 'Kale',
      'three seasonTags': (j) =>
          j['seasonTags'] = ['cool-season', 'evergreen', 'perennial'],
    };
    cases.forEach((name, edit) {
      test(name, () => expect(validateRecord(kaleWith(edit)), isNotEmpty));
    });
  });

  test('every image.asset file exists', () {
    for (final r in records) {
      final asset = r['image']['asset'] as String;
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });

  test('strict: credits are filled and every seed id is present', () {
    for (final r in records) {
      expect(r['image']['credit'], isNot('TBD'), reason: r['id'] as String);
      expect(r['image']['license'], isNot('TBD'), reason: r['id'] as String);
    }
    expect(records.map((r) => r['id']), containsAll(_seedIds));
  }, skip: strictCatalog ? false : 'strictCatalog is false until #52');

  test('non-strict mode tolerates a short seed list', () {
    expect(strictCatalog, isFalse);
    expect(records.length, lessThan(_seedIds.length));
    for (final r in records) {
      expect(validateRecord(r), isEmpty);
    }
  });
}
