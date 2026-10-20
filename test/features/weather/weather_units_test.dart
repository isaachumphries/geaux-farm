import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/weather/presentation/weather_hero.dart';
import 'package:geaux_farm/features/weather/presentation/week_strip.dart';

import '../../helpers/weather_screen_harness.dart';

Finder _inStrip(String text) =>
    find.descendant(of: find.byType(WeekStrip), matching: find.text(text));
Finder _inHero(String text) =>
    find.descendant(of: find.byType(WeatherHero), matching: find.text(text));

void main() {
  // The fixture's Friday (2026-10-16) is 92.0 °F / 70.5 °F; current 90.4 °F.
  testWidgets('imperial: 92 °F shows as 92', (tester) async {
    await pumpWeatherScreen(tester, height: 2000);
    expect(_inStrip('92°'), findsOneWidget);
    expect(_inStrip('33°'), findsNothing);
    expect(_inHero('90°'), findsOneWidget);
  });

  testWidgets('metric: 92 °F shows as 33, current 90.4 °F as 32', (
    tester,
  ) async {
    await pumpWeatherScreen(tester, profile: metricProfile, height: 2000);
    expect(_inStrip('33°'), findsOneWidget);
    expect(_inStrip('92°'), findsNothing);
    expect(_inStrip('21°'), findsOneWidget); // 70.5 °F
    expect(_inHero('32°'), findsOneWidget);
    expect(_inHero('Clear · H 34° / L 19°'), findsOneWidget); // 93.4 / 66.3
    expect(find.text('1478 mm a year'), findsOneWidget);
    expect(find.text('58 in a year'), findsNothing);
  });
}
