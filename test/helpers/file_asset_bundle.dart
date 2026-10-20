import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';

/// An [AssetBundle] that reads the repo's `assets/` directory with
/// synchronous file reads, so every load resolves without a real event-loop
/// turn.
///
/// Why: the real `rootBundle` loads through the engine and completes only on
/// the real event loop, and it caches the in-flight future per key for the
/// whole test process. A test that starts a load inside its fake-async zone
/// and ends first leaves a future whose continuations belong to a dead zone.
/// The next test in the same file awaits that future forever.
///
/// [loadString] decodes on the calling isolate. The framework's own
/// [AssetBundle.loadString] hands payloads of 50 KB or more to an isolate
/// (`compute`), which fake-async cannot wait on, so `plants.json` (over 50 KB
/// since catalog batch 1) never finished loading under `pumpAndSettle`.
/// Production keeps the off-thread decode.
class FileAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) {
    final bytes = File(key).readAsBytesSync();
    return Future.value(ByteData.sublistView(Uint8List.fromList(bytes)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      Future.value(utf8.decode(File(key).readAsBytesSync()));

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async => parser(await loadString(key));
}

/// Feeds the catalog from [FileAssetBundle] instead of `rootBundle`.
Override fileAssetBundleOverride() =>
    assetBundleProvider.overrideWithValue(FileAssetBundle());
