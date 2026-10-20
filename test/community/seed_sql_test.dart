// supabase/seed.sql must only reference plants that exist in the catalog
// (issue #38): Grow this silently skips unknown ids.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Each seed value carries a `-- plant_ids` label, so no SQL parsing is needed.
final _seedPlantIds = RegExp(r"'\{([^}]*)\}',\s*--\s*plant_ids");
final _seedTitle = RegExp(r"'([^']+)',\s*--\s*title");
final _pgtapCatalogId = RegExp(r"\('([a-z0-9-]+)'\)[,;]");

const _expectedTitles = [
  '5-gallon bucket cherry tomatoes',
  'Pallet vertical herb wall',
  'Balcony salad box',
  'Windowsill microgreens tray',
  '4×4 square-foot raised bed',
  'Pollinator patch for small yards',
  'Kratky hydroponic lettuce (no pump)',
  'Self-watering bottle planters',
  'Fall greens for Louisiana',
  'Compost bin from a storage tote',
];

Set<String> _catalogIds() {
  final json = jsonDecode(File('assets/plants/plants.json').readAsStringSync());
  final plants = json is List ? json : (json as Map)['plants'] as List;
  return {for (final p in plants) (p as Map)['id'] as String};
}

List<List<String>> _plantIdsPerGuide(String sql) => [
  for (final m in _seedPlantIds.allMatches(sql))
    m.group(1)!.isEmpty ? <String>[] : m.group(1)!.split(','),
];

void main() {
  final seed = File('supabase/seed.sql').readAsStringSync();
  final catalog = _catalogIds();

  test('seed.sql lists the ten plan 07 titles in order', () {
    final titles = [for (final m in _seedTitle.allMatches(seed)) m.group(1)!];
    expect(titles, _expectedTitles);
  });

  test('every plant id in seed.sql exists in plants.json', () {
    final perGuide = _plantIdsPerGuide(seed);
    expect(perGuide, hasLength(10));

    final missing = {
      for (final ids in perGuide)
        for (final id in ids)
          if (!catalog.contains(id)) id,
    };
    expect(
      missing,
      isEmpty,
      reason: 'seed plant ids missing from the catalog: $missing',
    );
  });

  test(
    'seed.sql plant ids are not repeated within a guide and fit the cap',
    () {
      for (final ids in _plantIdsPerGuide(seed)) {
        expect(ids.toSet(), hasLength(ids.length), reason: '$ids');
        expect(ids.length, lessThanOrEqualTo(10));
      }
    },
  );

  test('pgTAP catalog id list matches plants.json', () {
    final pgtap = File('supabase/tests/seed_test.sql').readAsStringSync();
    final ids = {
      for (final m in _pgtapCatalogId.allMatches(pgtap)) m.group(1)!,
    };
    expect(ids, catalog);
  });
}
