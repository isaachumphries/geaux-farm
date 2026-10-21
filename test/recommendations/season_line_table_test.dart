// plan/04 § Season line: the full month → season table and the 6-month
// shift for lat < 0.
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/recommendations/domain/season_line.dart';

import 'fixtures/baton_rouge.dart';

String season(int month, {double latitude = 30.45}) => seasonLine(
  city: 'X',
  latitude: latitude,
  months: batonRougeMonths,
  today: DateTime(2026, month, 15),
).split(' · ').first;

void main() {
  const northern = [
    'Winter', 'Winter', 'Spring', 'Spring', 'Spring', 'Summer', //
    'Summer', 'Summer', 'Fall', 'Fall', 'Fall', 'Winter',
  ];

  test('northern hemisphere: Dec–Feb, Mar–May, Jun–Aug, Sep–Nov', () {
    expect([for (var m = 1; m <= 12; m++) season(m)], northern);
  });

  test('southern hemisphere shifts every month by 6', () {
    expect(
      [for (var m = 1; m <= 12; m++) season(m, latitude: -0.01)],
      [for (var m = 1; m <= 12; m++) northern[(m + 5) % 12]],
    );
  });

  test('the equator (lat 0) is not shifted', () {
    expect(season(1, latitude: 0), 'Winter');
    expect(season(7, latitude: 0), 'Summer');
  });

  test('the shift moves the season label, not the climate months', () {
    // Southern July still averages Jul–Sep from the given months.
    expect(
      seasonLine(
        city: 'X',
        latitude: -33.9,
        months: batonRougeMonths,
        today: DateTime(2026, 7, 1),
      ),
      'Winter · Warm-season planting in X',
    );
  });
}
