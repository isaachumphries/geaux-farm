import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/weather/presentation/climate_section.dart';

import '../../recommendations/fixtures/baton_rouge.dart' as fx;

ClimateProfile _profile({
  String zone = '8b',
  ZoneSource source = ZoneSource.computed,
  int? spring = 51,
  int? fall,
  double rh = 75,
  List<ClimateMonth>? months,
}) => ClimateProfile(
  months: months ?? fx.batonRougeMonths,
  annualExtremeMinF: 19.66,
  annualPrecipIn: 58.18,
  annualRhPct: rh,
  zone: zone,
  zoneSource: source,
  lastSpringFrostDoy: spring,
  firstFallFrostDoy: fall,
  computedAt: DateTime.utc(2026, 10, 7),
);

Future<void> _pump(
  WidgetTester tester,
  ClimateProfile profile, {
  double lat = 30.45,
  bool metric = false,
}) async {
  tester.view.physicalSize = const Size(360, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ClimateSection(
            profile: profile,
            city: 'Baton Rouge',
            lat: lat,
            metric: metric,
            currentMonth: 10,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('Baton Rouge: 12 points per line series and 12 bars', (
    tester,
  ) async {
    await _pump(tester, fx.batonRougeClimate);

    final line = tester.widget<LineChart>(find.byType(LineChart)).data;
    expect(line.lineBarsData, hasLength(2));
    expect(line.lineBarsData[0].spots, hasLength(12));
    expect(line.lineBarsData[1].spots, hasLength(12));
    expect(line.lineBarsData[0].spots.first.y, 60.6); // Jan high
    expect(line.lineBarsData[1].spots.first.y, 42.9); // Jan low

    final bars = tester.widget<BarChart>(find.byType(BarChart)).data;
    expect(bars.barGroups, hasLength(12));
    expect(bars.barGroups.first.barRods.single.toY, 5.41);

    expect(find.text('Avg high'), findsOneWidget);
    expect(find.text('Avg low'), findsOneWidget);
    expect(find.text('Rain'), findsWidgets);
    expect(
      find.text('Monthly averages from 5 years of Baton Rouge weather.'),
      findsOneWidget,
    );
  });

  testWidgets('metric: the chart carries °C and mm', (tester) async {
    await _pump(tester, fx.batonRougeClimate, metric: true);
    final line = tester.widget<LineChart>(find.byType(LineChart)).data;
    expect(line.lineBarsData[0].spots.first.y, 16); // 60.6 °F
    expect(line.lineBarsData[1].spots.first.y, 6); // 42.9 °F
    final bars = tester.widget<BarChart>(find.byType(BarChart)).data;
    expect(bars.barGroups.first.barRods.single.toY, 137.4); // 5.41 in
    expect(find.text('1478 mm a year'), findsOneWidget);
  });

  testWidgets('computed zone shows Zone 8b and the estimate note', (
    tester,
  ) async {
    await _pump(tester, _profile());
    expect(find.text('Zone 8b'), findsOneWidget);
    expect(find.text('Estimated from 5 years of local data'), findsOneWidget);
    expect(find.text('USDA'), findsNothing);
  });

  testWidgets('usda zone shows USDA and not the estimate note', (tester) async {
    await _pump(tester, _profile(zone: '9a', source: ZoneSource.usda));
    expect(find.text('Zone 9a'), findsOneWidget);
    expect(find.text('USDA'), findsOneWidget);
    expect(find.text('Estimated from 5 years of local data'), findsNothing);
  });

  testWidgets('spring frost day 51 reads Feb 20; null fall is rare', (
    tester,
  ) async {
    await _pump(tester, _profile());
    expect(find.text('Last spring frost ~Feb 20'), findsOneWidget);
    expect(find.text('Fall frost is rare'), findsOneWidget);
  });

  testWidgets('a stored fall frost reads its date', (tester) async {
    await _pump(tester, _profile(fall: 334));
    expect(find.text('First fall frost ~Nov 30'), findsOneWidget);
    expect(find.text('Fall frost is rare'), findsNothing);
  });

  testWidgets('no spring frost reads Frost is rare here', (tester) async {
    await _pump(tester, _profile(spring: null));
    expect(find.text('Frost is rare here'), findsOneWidget);
  });

  testWidgets('lat < 0 hides the frost row entirely', (tester) async {
    await _pump(tester, _profile(), lat: -33.9);
    expect(find.text('Frost'), findsNothing);
    expect(find.textContaining('frost'), findsNothing);
    // The rest of the card is intact.
    expect(find.text('Zone 8b'), findsOneWidget);
    expect(find.text('Humidity'), findsOneWidget);
  });

  testWidgets('humidity label at the 70 and 45 thresholds', (tester) async {
    Future<void> expectLabel(double rh, String label) async {
      await _pump(tester, _profile(rh: rh));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget, reason: '$rh %');
      for (final other in {'Humid', 'Moderate', 'Dry'}..remove(label)) {
        expect(find.text(other), findsNothing, reason: '$rh % is not $other');
      }
    }

    await expectLabel(70, 'Humid');
    await expectLabel(69.9, 'Moderate');
    await expectLabel(45.1, 'Moderate');
    await expectLabel(45, 'Dry');
  });

  testWidgets('humidity detail and annual rain', (tester) async {
    await _pump(tester, fx.batonRougeClimate);
    expect(find.text(' · 75% average'), findsOneWidget);
    expect(find.text('58 in a year'), findsOneWidget);
  });
}
