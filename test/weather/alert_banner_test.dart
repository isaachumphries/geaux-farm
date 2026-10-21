import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:geaux_farm/features/weather/domain/garden_alerts.dart';
import 'package:geaux_farm/features/weather/presentation/alert_banner.dart';
import 'package:material_symbols_icons/symbols.dart';

Future<void> _pump(WidgetTester tester, Widget banner) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Center(child: banner)),
  ),
);

GardenAlert _alert(GardenAlertType type, String message) =>
    GardenAlert(type: type, day: DateTime(2026, 10, 7), message: message);

void main() {
  const cases = [
    (
      GardenAlertType.frost,
      AlertBannerType.frost,
      'Frost Thu: cover or bring in Basil, Kale',
      Symbols.ac_unit_rounded,
    ),
    (
      GardenAlertType.heat,
      AlertBannerType.heat,
      'Heat Wed: water early and shade young plants',
      Symbols.thermostat_rounded,
    ),
    (
      GardenAlertType.rain,
      AlertBannerType.rain,
      'Heavy rain Wed: check drainage — your watering schedule already '
          'accounts for it',
      Symbols.rainy_rounded,
    ),
    (
      GardenAlertType.uv,
      AlertBannerType.uv,
      'High UV today: shade new seedlings at midday',
      Symbols.wb_sunny_rounded,
    ),
  ];

  for (final (alertType, bannerType, copy, icon) in cases) {
    testWidgets('${bannerType.name} shows its exact copy', (tester) async {
      await _pump(tester, AlertBanner.alert(_alert(alertType, copy)));

      expect(find.text(copy), findsOneWidget);
      expect(
        tester.widget<AlertBanner>(find.byType(AlertBanner)).type,
        bannerType,
      );
      expect(find.byIcon(icon), findsOneWidget);
      expect(find.byType(GeauxAlertBanner), findsOneWidget);
    });
  }

  testWidgets('offline shows "Showing saved weather"', (tester) async {
    await _pump(tester, const AlertBanner.offline());

    expect(find.text('Showing saved weather'), findsOneWidget);
    expect(
      tester.widget<AlertBanner>(find.byType(AlertBanner)).type,
      AlertBannerType.offline,
    );
    expect(find.byIcon(Symbols.cloud_off_rounded), findsOneWidget);
  });

  testWidgets('each alert type has its own accent', (tester) async {
    final accents = <Color>{};
    for (final (alertType, _, copy, _) in cases) {
      await _pump(tester, AlertBanner.alert(_alert(alertType, copy)));
      final banner = tester.widget<GeauxAlertBanner>(
        find.byType(GeauxAlertBanner),
      );
      accents.add(banner.accent);
    }
    expect(accents, hasLength(4));
  });
}
