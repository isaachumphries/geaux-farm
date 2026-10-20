import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/weather/domain/weather_format.dart';

void main() {
  final fetched = DateTime(2026, 10, 13, 12);

  test('the offline banner needs data older than exactly 3 hours', () {
    expect(
      showsOfflineBanner(fetched, fetched.add(const Duration(hours: 3))),
      isFalse,
    );
    expect(
      showsOfflineBanner(
        fetched,
        fetched.add(const Duration(hours: 3, minutes: 1)),
      ),
      isTrue,
    );
  });

  test('uvLabel follows the WHO bands on the rounded index', () {
    expect(uvLabel(0), 'Low');
    expect(uvLabel(2.4), 'Low');
    expect(uvLabel(2.5), 'Moderate');
    expect(uvLabel(5.4), 'Moderate');
    expect(uvLabel(5.5), 'High');
    expect(uvLabel(7.4), 'High');
    expect(uvLabel(7.5), 'Very high');
    expect(uvLabel(10.4), 'Very high');
    expect(uvLabel(10.5), 'Extreme');
  });

  test('displayTemp converts at display time only', () {
    expect(displayTemp(92, metric: false), 92);
    expect(displayTemp(92, metric: true), 33);
    expect(displayTemp(32, metric: true), 0);
    expect(displayTemp(-4.4, metric: false), -4);
  });

  test('annualRainText rounds to whole inches or millimetres', () {
    expect(annualRainText(58.18, metric: false), '58 in a year');
    expect(annualRainText(58.18, metric: true), '1478 mm a year');
    expect(annualRainText(58.6, metric: false), '59 in a year');
    expect(annualRainText(58.4, metric: false), '58 in a year');
  });

  test('clockText and daylightText', () {
    expect(clockText('2026-10-13T06:59'), '6:59 AM');
    expect(clockText('2026-10-13T18:41'), '6:41 PM');
    expect(daylightText(41409.47), '11h 30m');
    expect(daylightText(42120), '11h 42m');
    expect(daylightText(59), '0h 1m');
  });

  test('todayOverline and weekdayShort', () {
    expect(todayOverline(DateTime(2026, 10, 7)), 'TODAY · WED, OCT 7');
    expect(weekdayShort(DateTime(2026, 10, 8)), 'Thu');
  });
}
