import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';
import 'package:geaux_farm/features/home/presentation/home_first_run_screen.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/plant_card.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('an onboarded app opens on Home and fills the carousel from the '
      'bundled catalog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: appOverrides(profile: onboardedProfile),
        child: const GeauxFarmApp(),
      ),
    );
    // One frame for the profile stream, one for the router.
    await tester.pump();
    await tester.pump();
    expect(find.text('Geaux Farm'), findsNothing);
    expect(find.text('Pick your first plant'), findsOneWidget);

    // plants.json comes from the real asset bundle.
    for (var i = 0; i < 20 && find.byType(PlantCard).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
    final ids = tester
        .widgetList<PlantCard>(find.byType(PlantCard))
        .map((c) => c.plant.plant.id);
    // The catalog grows with each batch, so check that every card is a bundled
    // record rather than naming the four reference plants.
    final catalogIds = {
      for (final r in jsonDecode(
        File('assets/plants/plants.json').readAsStringSync(),
      ) as List)
        (r as Map<String, dynamic>)['id'] as String,
    };
    expect(ids.toList(), hasLength(homeCarouselCount));
    expect(ids.toSet(), hasLength(homeCarouselCount));
    expect(catalogIds, containsAll(ids));

    await tester.pumpWidget(const SizedBox());
  });
}
