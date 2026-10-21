import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/weather/presentation/attribution_footer.dart';

import '../../helpers/weather_screen_harness.dart';

void main() {
  const text = 'Weather data by Open-Meteo.com (CC BY 4.0)';

  test('the constants are the exact copy and link from plan/06', () {
    expect(attributionText, text);
    expect(attributionUrl.toString(), 'https://open-meteo.com/');
  });

  testWidgets('default state shows the exact footer; tapping opens the link', (
    tester,
  ) async {
    final rig = await pumpWeatherScreen(tester, height: 2000);
    expect(find.text(text), findsOneWidget);
    expect(rig.opened, isEmpty);

    await tester.tap(find.text(text));
    await tester.pump();
    expect(rig.opened, [Uri.parse('https://open-meteo.com/')]);
  });

  testWidgets('the error state shows it too and it still opens', (
    tester,
  ) async {
    final rig = WeatherRig()..fail = true;
    await pumpWeatherScreen(tester, rig: rig, height: 2000);
    expect(find.text('RETRY'), findsOneWidget);
    expect(find.text(text), findsOneWidget);
    await tester.tap(find.text(text));
    await tester.pump();
    expect(rig.opened, hasLength(1));
  });

  testWidgets('the loading state shows it', (tester) async {
    final gate = Completer<void>();
    final rig = WeatherRig()..hold = gate.future;
    await pumpWeatherScreen(tester, rig: rig, height: 2000);
    expect(find.text(text), findsOneWidget);
    gate.complete();
    await tester.pump();
    await tester.pump();
  });
}
