import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/climate/domain/climate_normals.dart';
import 'package:geaux_farm/features/climate/domain/frost_dates.dart';

import 'baton_rouge_archive.dart';

/// A warm row (no frost) on [d], or a frost row when [frost] is set.
DailyClimateRow _day(DateTime d, {bool frost = false}) =>
    DailyClimateRow(date: d, minF: frost ? 32 : 50);

/// Every day of [year], with frost on [frostDays].
List<DailyClimateRow> _year(int year, Set<DateTime> frostDays) => [
  for (
    var d = DateTime(year);
    d.year == year;
    d = DateTime(d.year, d.month, d.day + 1)
  )
    _day(d, frost: frostDays.contains(d)),
];

void main() {
  test('Baton Rouge fixture: spring 51 (Feb 20), fall null', () {
    final f = frostDates(archiveFixtureRows(), 30.45);
    expect(f.lastSpringFrostDoy, 51);
    // Fall frost only in 2022 and 2025: rare.
    expect(f.firstFallFrostDoy, isNull);
  });

  test('event in 2 of 5 years → null; 3 of 5 → median', () {
    final twoYears = [
      ..._year(2021, {DateTime(2021, 3, 1), DateTime(2021, 11, 10)}),
      ..._year(2022, {DateTime(2022, 3, 5), DateTime(2022, 11, 20)}),
      ..._year(2023, {DateTime(2023, 3, 10)}),
      ..._year(2024, {}),
      ..._year(2025, {}),
    ];
    final f = frostDates(twoYears, 30);
    // Spring in 3 years: day 60, 64, 69 → median 64.
    expect(f.lastSpringFrostDoy, 64);
    expect(f.firstFallFrostDoy, isNull);
  });

  test('the latest spring frost and earliest fall frost count per year', () {
    final rows = [
      for (var y = 2021; y <= 2023; y++)
        ..._year(y, {
          DateTime(y, 1, 5),
          DateTime(y, 2, 1),
          DateTime(y, 7, 31),
          DateTime(y, 8, 1),
          DateTime(y, 12, 31),
        }),
    ];
    final f = frostDates(rows, 45);
    expect(f.lastSpringFrostDoy, 212); // Jul 31 in a common year
    expect(f.firstFallFrostDoy, 213); // Aug 1
  });

  test('an even count uses the rounded mean of the two middle days', () {
    final rows = [
      ..._year(2021, {DateTime(2021, 2, 1)}), // 32
      ..._year(2022, {DateTime(2022, 2, 2)}), // 33
      ..._year(2023, {DateTime(2023, 2, 4)}), // 35
      ..._year(2024, {DateTime(2024, 2, 10)}), // 41
      ..._year(2025, {}),
    ];
    // Middle values 33 and 35 → 34.
    expect(frostDates(rows, 30).lastSpringFrostDoy, 34);
  });

  test('a minimum just above 32 °F is not frost', () {
    final rows = [
      for (var y = 2021; y <= 2025; y++)
        for (
          var d = DateTime(y);
          d.year == y;
          d = DateTime(d.year, d.month, d.day + 1)
        )
          DailyClimateRow(date: d, minF: 32.1),
    ];
    final f = frostDates(rows, 30);
    expect(f.lastSpringFrostDoy, isNull);
    expect(f.firstFallFrostDoy, isNull);
  });

  test('southern hemisphere: both null', () {
    final f = frostDates(archiveFixtureRows(), -10);
    expect(f.lastSpringFrostDoy, isNull);
    expect(f.firstFallFrostDoy, isNull);
  });
}
