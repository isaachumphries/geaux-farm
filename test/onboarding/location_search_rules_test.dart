import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/onboarding/data/open_meteo_geocoding_repository.dart';
import 'package:geaux_farm/features/onboarding/domain/geocoding_repository.dart';
import 'package:geaux_farm/features/onboarding/presentation/location_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';

import '../helpers/onboarding_harness.dart';

// plan/02 § OB-02: debounced 300 ms, minimum 2 characters, and the
// no-results copy. Durations and lengths are literals on purpose, so a
// changed constant in location_screen.dart fails here.

const _noMatches = 'No matches. Try a nearby city or ZIP.';
const _row = 'Baton Rouge, Louisiana, US';

class _Geocoding implements GeocodingRepository {
  _Geocoding({this.empty = false});

  final bool empty;
  final queries = <String>[];

  @override
  Future<List<GeoPlace>> search(String query) async {
    queries.add(query);
    return empty
        ? const []
        : const [
            GeoPlace(
              name: 'Baton Rouge',
              admin1: 'Louisiana',
              countryCode: 'US',
              lat: 30.4515,
              lon: -91.1871,
              timezone: 'America/Chicago',
            ),
          ];
  }
}

Future<_Geocoding> _pump(WidgetTester tester, {bool empty = false}) async {
  final geo = _Geocoding(empty: empty);
  await pumpOnboardingStep(
    tester,
    route: OnboardingRoutes.location,
    screen: const LocationScreen(),
    overrides: [geocodingRepositoryProvider.overrideWithValue(geo)],
  );
  return geo;
}

Future<void> _type(WidgetTester tester, String text) =>
    tester.enterText(find.byType(TextField), text);

void main() {
  testWidgets('exactly 2 characters searches; 1 never does', (tester) async {
    final geo = await _pump(tester);
    await _type(tester, 'B');
    await tester.pump(const Duration(seconds: 2));
    expect(geo.queries, isEmpty);

    await _type(tester, 'Ba');
    await tester.pump(const Duration(milliseconds: 300));
    expect(geo.queries, ['Ba']);
  });

  testWidgets('the search waits exactly 300 ms after the last keystroke', (
    tester,
  ) async {
    final geo = await _pump(tester);
    await _type(tester, 'Baton');
    await tester.pump(const Duration(milliseconds: 299));
    expect(geo.queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(geo.queries, ['Baton']);
    await tester.pump();
    expect(find.text(_row), findsOneWidget);
  });

  testWidgets('dropping below 2 characters cancels the pending search and '
      'clears the results', (tester) async {
    final geo = await _pump(tester);
    await _type(tester, 'Baton');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text(_row), findsOneWidget);

    // 'Bat' is pending when the query drops to 'B'.
    await _type(tester, 'Bat');
    await tester.pump(const Duration(milliseconds: 200));
    await _type(tester, 'B');
    await tester.pump(const Duration(seconds: 2));
    expect(geo.queries, ['Baton']);
    expect(find.text(_row), findsNothing);
    expect(find.text(_noMatches), findsNothing);
  });

  testWidgets('the no-matches copy shows only once a search came back empty', (
    tester,
  ) async {
    await _pump(tester, empty: true);
    expect(find.text(_noMatches), findsNothing);

    await _type(tester, 'Zz');
    await tester.pump(const Duration(milliseconds: 299));
    expect(find.text(_noMatches), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text(_noMatches), findsOneWidget);

    await _type(tester, 'Z');
    await tester.pump();
    expect(find.text(_noMatches), findsNothing);
  });
}
