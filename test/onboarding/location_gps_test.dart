import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/onboarding/data/device_locator.dart';
import 'package:geaux_farm/features/onboarding/data/open_meteo_geocoding_repository.dart';
import 'package:geaux_farm/features/onboarding/domain/geocoding_repository.dart';
import 'package:geaux_farm/features/onboarding/presentation/location_screen.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_draft_provider.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_routes.dart';

import '../helpers/onboarding_harness.dart';
import 'location_search_test.dart' show FakeGeocoding;

class _FakeLocator implements DeviceLocator {
  _FakeLocator(this.result);

  final GeoPlace? result;

  @override
  Future<GeoPlace> locate() async {
    final place = result;
    if (place == null) {
      throw const LocationUnavailableException('Permission denied');
    }
    return place;
  }
}

void main() {
  testWidgets('permission denied shows the snackbar and keeps search usable', (
    tester,
  ) async {
    final geo = FakeGeocoding();
    await pumpOnboardingStep(
      tester,
      route: OnboardingRoutes.location,
      screen: const LocationScreen(),
      overrides: [
        geocodingRepositoryProvider.overrideWithValue(geo),
        deviceLocatorProvider.overrideWithValue(_FakeLocator(null)),
      ],
    );
    await tester.tap(find.text('USE MY CURRENT LOCATION'));
    await tester.pump();
    expect(
      find.text('Location is off — search for your city instead.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Baton');
    await tester.pump(locationSearchDebounce);
    await tester.pump();
    expect(geo.queries, ['Baton']);
    expect(find.text('Baton Rouge, Louisiana, US'), findsOneWidget);
  });

  testWidgets('permission granted fills the draft and opens the reveal', (
    tester,
  ) async {
    final h = await pumpOnboardingStep(
      tester,
      route: OnboardingRoutes.location,
      screen: const LocationScreen(),
      overrides: [
        deviceLocatorProvider.overrideWithValue(
          _FakeLocator(
            const GeoPlace(
              name: 'Baton Rouge',
              admin1: 'Louisiana',
              countryCode: 'US',
              postcode: '70803',
              lat: 30.41234,
              lon: -91.17891,
              timezone: 'America/Chicago',
            ),
          ),
        ),
      ],
    );
    await tester.tap(find.text('USE MY CURRENT LOCATION'));
    await tester.pumpAndSettle();

    final draft = h.container.read(onboardingDraftProvider);
    expect(draft.city, 'Baton Rouge');
    expect(draft.admin1, 'Louisiana');
    expect(draft.countryCode, 'US');
    expect(draft.postcode, '70803');
    expect(draft.timezone, 'America/Chicago');
    expect(draft.lat, 30.41);
    expect(draft.lon, -91.18);
    expect(find.text(OnboardingRoutes.climate), findsOneWidget);
  });
}
