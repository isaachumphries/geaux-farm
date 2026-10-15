import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/plant_card.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('the app opens on Home and fills the carousel from the '
      'bundled catalog', (tester) async {
    final forecast = File('test/fixtures/open_meteo/forecast_baton_rouge.json')
        .readAsStringSync();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The profile streams read Drift; feed them the defaults instead.
          userProfileProvider.overrideWith(
            (ref) => Stream.value(defaultUserProfile),
          ),
          primarySpaceProvider.overrideWith(
            (ref) => Stream.value(defaultSpace),
          ),
          // Home's weather card must not reach Open-Meteo from a test.
          forecastClientProvider.overrideWithValue(
            OpenMeteoForecastClient(
              MockClient((_) async => http.Response(forecast, 200)),
            ),
          ),
        ],
        child: const GeauxFarmApp(),
      ),
    );
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
    expect(
      ids,
      unorderedEquals([
        'kale',
        'cherry-tomato',
        'sweet-basil',
        'english-lavender',
      ]),
    );

    await tester.pumpWidget(const SizedBox());
  });
}
