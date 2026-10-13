import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/plant.dart';
import 'catalog_repository.dart';

/// The bundle the catalog is read from; tests override it with a fake.
final assetBundleProvider = Provider<AssetBundle>((ref) => rootBundle);

/// The curated plant catalog. Kept alive, so `plants.json` is read once per
/// app start (plan/09 § State management).
final catalogProvider = FutureProvider<List<Plant>>(
  (ref) => loadPlants(ref.watch(assetBundleProvider)),
);
