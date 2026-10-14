import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/recommendations/domain/season_line.dart';

import 'fixtures/baton_rouge.dart';

/// Twelve months whose meanF is [meanF].
List<ClimateMonth> flat(double meanF) => [
  for (var m = 1; m <= 12; m++)
    ClimateMonth(
      month: m,
      avgLowF: meanF,
      avgHighF: meanF,
      precipIn: 0,
      rhPct: 50,
      cloudPct: 0,
      sunshineHours: 0,
    ),
];

String line({
  double latitude = 30.45,
  List<ClimateMonth> months = batonRougeMonths,
  required DateTime today,
}) => seasonLine(
  city: 'Baton Rouge',
  latitude: latitude,
  months: months,
  today: today,
);

void main() {
  test('Baton Rouge 2026-10-07', () {
    // (71.85 + 62.35 + 58.00) / 3 = 64.07.
    expect(
      line(today: DateTime(2026, 10, 7)),
      'Fall · Cool-season planting in Baton Rouge',
    );
  });

  test('Baton Rouge 2026-10-13', () {
    expect(
      line(today: DateTime(2026, 10, 13)),
      'Fall · Cool-season planting in Baton Rouge',
    );
  });

  group('phrase boundaries', () {
    final cases = {
      39.9: 'Indoor growing season',
      40.0: 'Cool-season planting',
      64.9: 'Cool-season planting',
      65.0: 'Warm-season planting',
    };
    cases.forEach((mean, phrase) {
      test('$mean → $phrase', () {
        expect(seasonPhrase(mean), phrase);
        expect(
          line(months: flat(mean), today: DateTime(2026, 7, 1)),
          'Summer · $phrase in Baton Rouge',
        );
      });
    });
  });

  test('uses the current and next two months, not just the current', () {
    // September alone is 79.75 (warm); Sep–Nov averages 71.32 (warm);
    // October alone is 71.85 but Oct–Dec averages 64.07 (cool).
    expect(
      line(today: DateTime(2026, 9, 1)),
      'Fall · Warm-season planting in Baton Rouge',
    );
  });

  test('southern hemisphere shifts the season by 6 months', () {
    expect(
      line(latitude: -33.9, today: DateTime(2026, 10, 7)),
      startsWith('Spring · '),
    );
    expect(
      line(latitude: -33.9, today: DateTime(2026, 1, 7)),
      startsWith('Summer · '),
    );
    expect(
      line(latitude: -33.9, today: DateTime(2026, 7, 7)),
      startsWith('Winter · '),
    );
  });

  test('Dec–Feb is winter and the mean wraps past December', () {
    // Dec, Jan, Feb: (58.00 + 51.75 + 56.70) / 3 = 55.48.
    expect(
      line(today: DateTime(2026, 12, 1)),
      'Winter · Cool-season planting in Baton Rouge',
    );
    expect(line(today: DateTime(2027, 1, 31)), startsWith('Winter · '));
    expect(line(today: DateTime(2027, 2, 28)), startsWith('Winter · '));
    expect(line(today: DateTime(2027, 3, 1)), startsWith('Spring · '));
    expect(line(today: DateTime(2026, 11, 30)), startsWith('Fall · '));
  });

  test('wrap reads January after December', () {
    // Only Jan is cold: Nov–Jan mean (20 + 20 + 20)/3 under wrap; a
    // non-wrapping index would throw or read the wrong months.
    final months = flat(80);
    months[10] = flat(20)[10];
    months[11] = flat(20)[11];
    months[0] = flat(20)[0];
    expect(
      line(months: months, today: DateTime(2026, 11, 1)),
      'Fall · Indoor growing season in Baton Rouge',
    );
  });
}
