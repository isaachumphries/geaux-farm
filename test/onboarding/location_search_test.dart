import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/onboarding/data/open_meteo_geocoding_repository.dart';
import 'package:geaux_farm/features/onboarding/domain/geocoding_repository.dart';
import 'package:geaux_farm/features/onboarding/presentation/location_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_draft_provider.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';

import '../helpers/onboarding_harness.dart';

const batonRouge = GeoPlace(
  name: 'Baton Rouge',
  admin1: 'Louisiana',
  countryCode: 'US',
  lat: 30.4515,
  lon: -91.1871,
  postcode: '70801',
  timezone: 'America/Chicago',
);

class FakeGeocoding implements GeocodingRepository {
  FakeGeocoding([this.results = const [batonRouge]]);

  final List<GeoPlace> results;
  final queries = <String>[];
  bool fail = false;

  @override
  Future<List<GeoPlace>> search(String query) async {
    queries.add(query);
    if (fail) throw Exception('offline');
    return results;
  }
}

Future<FakeGeocoding> _pump(WidgetTester tester, [FakeGeocoding? fake]) async {
  final geo = fake ?? FakeGeocoding();
  await pumpOnboardingStep(
    tester,
    route: OnboardingRoutes.location,
    screen: const LocationScreen(),
    overrides: [geocodingRepositoryProvider.overrideWithValue(geo)],
  );
  return geo;
}

void main() {
  testWidgets('shows the plan/02 copy', (tester) async {
    await _pump(tester);
    expect(find.text('Where do you live?'), findsOneWidget);
    expect(
      find.text(
        "We use your city's climate — rainfall, humidity, sunlight, UV and "
        'seasons — to pick plants that will thrive.',
      ),
      findsOneWidget,
    );
    expect(find.text('Search city or ZIP'), findsOneWidget);
    expect(find.text('USE MY CURRENT LOCATION'), findsOneWidget);
  });

  testWidgets('a 1-character query makes no repository call', (tester) async {
    final geo = await _pump(tester);
    await tester.enterText(find.byType(TextField), 'B');
    await tester.pump(const Duration(seconds: 1));
    expect(geo.queries, isEmpty);
  });

  testWidgets('rapid typing makes one call for the last value after 300 ms', (
    tester,
  ) async {
    final geo = await _pump(tester);
    for (final q in ['Ba', 'Bat', 'Bato', 'Baton']) {
      await tester.enterText(find.byType(TextField), q);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(geo.queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 300));
    expect(geo.queries, ['Baton']);
    await tester.pump();
    expect(find.text('Baton Rouge, Louisiana, US'), findsOneWidget);
  });

  testWidgets('zero results shows the empty copy', (tester) async {
    await _pump(tester, FakeGeocoding(const []));
    await tester.enterText(find.byType(TextField), 'Zzzz');
    await tester.pump(locationSearchDebounce);
    await tester.pump();
    expect(find.text('No matches. Try a nearby city or ZIP.'), findsOneWidget);
  });

  testWidgets('a failed search shows Retry', (tester) async {
    final geo = FakeGeocoding()..fail = true;
    await _pump(tester, geo);
    await tester.enterText(find.byType(TextField), 'Baton');
    await tester.pump(locationSearchDebounce);
    await tester.pump();
    expect(find.text('RETRY'), findsOneWidget);
    geo.fail = false;
    await tester.tap(find.text('RETRY'));
    await tester.pump();
    expect(find.text('Baton Rouge, Louisiana, US'), findsOneWidget);
  });

  testWidgets('selecting a result stores 2-decimal coordinates and opens '
      'the climate reveal', (tester) async {
    final geo = FakeGeocoding();
    final h = await pumpOnboardingStep(
      tester,
      route: OnboardingRoutes.location,
      screen: const LocationScreen(),
      overrides: [geocodingRepositoryProvider.overrideWithValue(geo)],
    );
    await tester.enterText(find.byType(TextField), 'Baton');
    await tester.pump(locationSearchDebounce);
    await tester.pump();
    await tester.tap(find.text('Baton Rouge, Louisiana, US'));
    await tester.pumpAndSettle();

    final draft = h.container.read(onboardingDraftProvider);
    expect(draft.city, 'Baton Rouge');
    expect(draft.admin1, 'Louisiana');
    expect(draft.countryCode, 'US');
    expect(draft.postcode, '70801');
    expect(draft.lat, 30.45);
    expect(draft.lon, -91.19);
    expect(draft.timezone, 'America/Chicago');
    expect(find.text(OnboardingRoutes.climate), findsOneWidget);
  });
}
