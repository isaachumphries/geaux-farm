import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';

void main() {
  group('WMO condition mapping', () {
    final cases = <(int, bool, String, String)>[
      (0, true, 'Clear', 'clear_day'),
      (0, false, 'Clear', 'clear_night'),
      (1, true, 'Partly cloudy', 'partly_cloudy_day'),
      (2, false, 'Partly cloudy', 'partly_cloudy_day'),
      (3, true, 'Overcast', 'cloud'),
      (45, true, 'Fog', 'foggy'),
      (48, true, 'Fog', 'foggy'),
      (51, true, 'Drizzle', 'rainy_light'),
      (57, true, 'Drizzle', 'rainy_light'),
      (61, true, 'Rain', 'rainy'),
      (67, true, 'Rain', 'rainy'),
      (71, true, 'Snow', 'weather_snowy'),
      (77, true, 'Snow', 'weather_snowy'),
      (80, true, 'Rain', 'rainy'),
      (82, true, 'Rain', 'rainy'),
      (85, true, 'Snow', 'weather_snowy'),
      (86, true, 'Snow', 'weather_snowy'),
      (95, true, 'Thunderstorm', 'thunderstorm'),
      (99, true, 'Thunderstorm', 'thunderstorm'),
      // Unlisted codes, including ones just outside listed ranges.
      (4, true, 'Overcast', 'cloud'),
      (50, true, 'Overcast', 'cloud'),
      (58, true, 'Overcast', 'cloud'),
      (68, true, 'Overcast', 'cloud'),
      (83, true, 'Overcast', 'cloud'),
      (100, true, 'Overcast', 'cloud'),
    ];
    for (final (code, isDay, label, icon) in cases) {
      test('code $code ${isDay ? 'day' : 'night'} → $label / $icon', () {
        final c = WeatherCondition.of(code, isDay: isDay);
        expect(c.label, label);
        expect(c.iconName, icon);
      });
    }
  });
}
