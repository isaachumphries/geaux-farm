// supabase/seed.sql must only reference plants that exist in the catalog
// (issue #38): Grow this silently skips unknown ids.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Each seed value carries a `-- plant_ids` label, so no SQL parsing is needed.
final _seedPlantIds = RegExp(r"'\{([^}]*)\}',\s*--\s*plant_ids");

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
}
