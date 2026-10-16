import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/climate/data/climate_service.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/onboarding/domain/geocoding_repository.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_climate_provider.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_draft_provider.dart';

import '../recommendations/fixtures/baton_rouge.dart' as fx;

class _RecordingService implements ClimateService {
  final calls = <(double, double, String, String?)>[];

  @override
  Future<ClimateProfile> build({
    required double lat,
    required double lon,
    required String countryCode,
    String? postcode,
  }) async {
    calls.add((lat, lon, countryCode, postcode));
    return fx.batonRougeClimate;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('builds for the draft location and again after a city change', () async {
    final service = _RecordingService();
    final container = ProviderContainer(
      overrides: [climateServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final draft = container.read(onboardingDraftProvider.notifier);
    draft.setLocation(
      const GeoPlace(
        name: 'Baton Rouge',
        admin1: 'Louisiana',
        countryCode: 'US',
        postcode: '70801',
        lat: 30.4515,
        lon: -91.1871,
      ),
    );

    final sub = container.listen(onboardingClimateProvider, (_, _) {});
    addTearDown(sub.close);
    expect(
      await container.read(onboardingClimateProvider.future),
      fx.batonRougeClimate,
    );
    expect(service.calls, [(30.45, -91.19, 'US', '70801')]);

    draft.setLocation(
      const GeoPlace(
        name: 'Denver',
        admin1: 'Colorado',
        countryCode: 'US',
        lat: 39.7392,
        lon: -104.9903,
      ),
    );
    await container.read(onboardingClimateProvider.future);
    expect(service.calls.last, (39.74, -104.99, 'US', null));
  });
}
