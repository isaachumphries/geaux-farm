import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';
import 'package:geaux_farm/features/weather/presentation/week_strip.dart';

WeatherDay _day(String date, {int? prob, double max = 92, double min = 74}) =>
    WeatherDay(
      date: date,
      weatherCode: 61,
      tmaxF: max,
      tminF: min,
      precipIn: 0,
      precipProb: prob,
      uvMax: 5,
      sunshineS: 0,
      daylightS: 0,
      et0In: 0,
      sunrise: '${date}T07:00',
      sunset: '${date}T18:00',
    );

Future<void> _pump(
  WidgetTester tester,
  List<WeatherDay> days, {
  bool metric = false,
}) async {
  tester.view.physicalSize = const Size(360, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WeekStrip(days: days, metric: metric),
      ),
    ),
  );
}

Color _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  testWidgets('rain chance turns blue at 50 % and not at 49 %', (tester) async {
    await _pump(tester, [
      _day('2026-10-13', prob: 49),
      _day('2026-10-14', prob: 50),
      _day('2026-10-15', prob: 90),
    ]);
    expect(_color(tester, '49%'), AppColors.soil600);
    expect(_color(tester, '50%'), AppColors.frost);
    expect(_color(tester, '90%'), AppColors.frost);
  });

  testWidgets('a missing chance draws a dash', (tester) async {
    await _pump(tester, [_day('2026-10-13')]);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('highs and lows are rounded; metric shows Celsius', (
    tester,
  ) async {
    await _pump(tester, [_day('2026-10-13', prob: 0, max: 91.6, min: 73.6)]);
    expect(find.text('92°'), findsOneWidget);
    expect(find.text('74°'), findsOneWidget);
    await _pump(tester, [
      _day('2026-10-13', prob: 0, max: 91.6, min: 73.6),
    ], metric: true);
    await tester.pump();
    expect(find.text('33°'), findsOneWidget);
    expect(find.text('23°'), findsOneWidget);
  });

  testWidgets('the first column reads Today, the rest weekday names', (
    tester,
  ) async {
    await _pump(tester, [
      _day('2026-10-13', prob: 0),
      _day('2026-10-14', prob: 0),
    ]);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Wed'), findsOneWidget);
    expect(find.text('Tue'), findsNothing);
  });
}
