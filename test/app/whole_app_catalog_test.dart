import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';

import '../helpers/app_harness.dart';

/// Regression for the red "Find my first plant" test (#21).
///
/// The app root starts care reminders at launch, which reads the catalog.
/// The real `rootBundle` completes loads only on the real event loop and
/// caches the in-flight future per key for the whole test process. A whole-app
/// test that ended before its load finished left a future whose continuations
/// belonged to a dead fake-async zone, and the next whole-app test in the file
/// waited on it forever (`pumpAndSettle timed out`).
///
/// `appOverrides` therefore reads the catalog from a file-backed bundle, which
/// also decodes the string on the calling isolate (see `FileAssetBundle`).
void main() {
  testWidgets('a whole-app test that abandons a rootBundle load', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: appOverrides(
          profile: onboardedProfile,
          assetBundle: rootBundle,
        ),
        child: const GeauxFarmApp(),
      ),
    );
    // Not pumpAndSettle: plants.json is over 50 KB, so the framework decodes
    // it on an isolate that fake-async cannot wait on, and the loading state
    // keeps scheduling frames. Pump a bounded time instead.
    await tester.pump(const Duration(seconds: 1));

    // The test ends here with the load still in flight, as the real tests did.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GeauxFarmApp)),
    );
    expect(container.read(catalogProvider).isLoading, isTrue);
  });

  testWidgets('the next whole-app test still gets the catalog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: appOverrides(profile: onboardedProfile),
        child: const GeauxFarmApp(),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GeauxFarmApp)),
    );
    expect(container.read(catalogProvider).hasValue, isTrue);
  });
}
