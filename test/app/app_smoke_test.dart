import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';
import 'package:geaux_farm/app/notification_wiring.dart';
import 'package:geaux_farm/features/care/application/care_reminders.dart';
import 'package:geaux_farm/features/home/presentation/home_first_run_screen.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/plant_card.dart';
import 'package:geaux_farm/features/weather/application/garden_alerts_provider.dart';
import 'package:geaux_farm/features/weather/application/weather_resume.dart';

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

    // plants.json is read from assets/ by the harness bundle.
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

  testWidgets('the root keeps the notification and weather syncs alive', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: appOverrides(profile: onboardedProfile),
        child: const GeauxFarmApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GeauxFarmApp)),
    );

    // Only the app root watches these, so nothing else would build them.
    expect(container.exists(notificationStartupProvider), isTrue);
    expect(container.exists(careRemindersSyncProvider), isTrue);
    expect(container.exists(weatherResumeRefreshProvider), isTrue);
    expect(container.exists(weatherAlertsSyncProvider), isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
