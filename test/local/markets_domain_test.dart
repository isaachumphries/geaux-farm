import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/local/domain/distance.dart';
import 'package:geaux_farm/features/local/domain/map_links.dart';

// plan/08 § Markets: distances are haversine miles from the profile
// location, and a row tap opens the platform's maps app.
void main() {
  group('distanceMiles', () {
    test('a point to itself is 0', () {
      expect(distanceMiles(30.45, -91.19, 30.45, -91.19), 0);
    });

    // Expected values computed once from the haversine formula with
    // R = 3958.7613 mi, outside this code. Do not refresh them from the
    // app's own output.
    test('Baton Rouge to New Orleans is 75.2763 mi', () {
      expect(
        distanceMiles(30.45, -91.19, 29.95, -90.07),
        closeTo(75.27634614455094, 1e-9),
      );
    });

    test('Baton Rouge to Lafayette is 51.9843 mi', () {
      expect(
        distanceMiles(30.45, -91.19, 30.22, -92.02),
        closeTo(51.9843087951321, 1e-9),
      );
    });

    test('the measurement is symmetric', () {
      expect(
        distanceMiles(30.45, -91.19, 29.95, -90.07),
        closeTo(distanceMiles(29.95, -90.07, 30.45, -91.19), 1e-12),
      );
    });
  });

  group('marketMapUrl', () {
    test('Android uses the geo: scheme', () {
      expect(
        marketMapUrl(
          platform: MapPlatform.android,
          name: 'Red Stick Farmers Market',
          lat: 30.45,
          lon: -91.19,
        ).toString(),
        'geo:30.45,-91.19?q=Red+Stick+Farmers+Market',
      );
    });

    test('iOS uses Apple Maps', () {
      expect(
        marketMapUrl(
          platform: MapPlatform.ios,
          name: 'Red Stick Farmers Market',
          lat: 30.45,
          lon: -91.19,
        ).toString(),
        'https://maps.apple.com/?q=Red+Stick+Farmers+Market&ll=30.45,-91.19',
      );
    });

    test(
      'a name with an ampersand is encoded, not left to split the query',
      () {
        final url = marketMapUrl(
          platform: MapPlatform.android,
          name: 'Fruits & Roots',
          lat: 30.0,
          lon: -91.0,
        );
        expect(url.toString(), isNot(contains('Roots&')));
        expect(url.queryParameters['q'], 'Fruits & Roots');
      },
    );
  });
}
