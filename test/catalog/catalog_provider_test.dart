import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';
import 'package:geaux_farm/features/catalog/data/catalog_repository.dart';

/// Serves [plantsJson] at [plantsAssetKey] and counts every read.
class _CountingBundle extends AssetBundle {
  _CountingBundle(this.plantsJson);

  final String plantsJson;
  int reads = 0;

  @override
  Future<ByteData> load(String key) async {
    if (key != plantsAssetKey) throw StateError('no asset $key');
    reads++;
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(plantsJson)));
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async => parser(await loadString(key));
}

List<Map<String, dynamic>> _records() =>
    (jsonDecode(File(plantsAssetKey).readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

void main() {
  test('catalogProvider reads the bundle once and returns the four '
      'reference plants', () async {
    final bundle = _CountingBundle(File(plantsAssetKey).readAsStringSync());
    final container = ProviderContainer(
      overrides: [assetBundleProvider.overrideWithValue(bundle)],
    );
    addTearDown(container.dispose);

    final first = await container.read(catalogProvider.future);
    final second = await container.read(catalogProvider.future);

    expect(first.map((p) => p.id), [
      'kale',
      'cherry-tomato',
      'sweet-basil',
      'english-lavender',
    ]);
    expect(identical(first, second), isTrue);
    expect(bundle.reads, 1);
  });

  test('a record with an unknown enum value fails with its id', () {
    final records = _records();
    records[2] = {...records[2], 'id': 'bad-basil', 'category': 'tree'};

    expect(
      loadPlants(_CountingBundle(jsonEncode(records))),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('bad-basil'),
        ),
      ),
    );
  });

  test('a record missing a required field fails with its id', () {
    final records = _records();
    records[1] = {...records[1], 'id': 'no-care'}..remove('care');

    expect(
      loadPlants(_CountingBundle(jsonEncode(records))),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('no-care'), contains('care')),
        ),
      ),
    );
  });

  test('a file that is not a JSON array is rejected', () {
    expect(
      loadPlants(_CountingBundle('{"id": "kale"}')),
      throwsFormatException,
    );
  });
}
