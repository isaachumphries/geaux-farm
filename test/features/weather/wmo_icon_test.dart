import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/weather/domain/wmo_icon.dart';

void main() {
  test('clear sky uses the day or night glyph', () {
    expect(iconFor(0, isDay: true), 'clear_day');
    expect(iconFor(0, isDay: false), 'clear_night');
  });

  test('mainly clear and partly cloudy use the partly cloudy glyph', () {
    for (final code in [1, 2]) {
      expect(iconFor(code, isDay: true), 'partly_cloudy_day', reason: '$code');
      expect(iconFor(code, isDay: false), 'partly_cloudy_day', reason: '$code');
    }
  });

  test('overcast uses the cloud glyph', () {
    expect(iconFor(3, isDay: true), 'cloud');
  });

  test('fog and depositing rime fog use the foggy glyph', () {
    for (final code in [45, 48]) {
      expect(iconFor(code, isDay: true), 'foggy', reason: '$code');
    }
  });

  test('drizzle codes 51 to 57 use the light rain glyph', () {
    for (final code in [51, 53, 55, 56, 57]) {
      expect(iconFor(code, isDay: true), 'rainy_light', reason: '$code');
    }
  });

  test('rain codes 61 to 67 and showers 80 to 82 use the rain glyph', () {
    for (final code in [61, 63, 65, 66, 67, 80, 81, 82]) {
      expect(iconFor(code, isDay: true), 'rainy', reason: '$code');
    }
  });

  test('snow codes 71 to 77 and snow showers 85 to 86 use the snow glyph', () {
    for (final code in [71, 73, 75, 77, 85, 86]) {
      expect(iconFor(code, isDay: true), 'weather_snowy', reason: '$code');
    }
  });

  test('thunderstorm codes 95 to 99 use the thunderstorm glyph', () {
    for (final code in [95, 96, 99]) {
      expect(iconFor(code, isDay: true), 'thunderstorm', reason: '$code');
    }
  });

  test('codes the plan does not list fall back to cloud', () {
    for (final code in [4, 50, 58, 68, 78, 84, 87, 100, -1]) {
      expect(iconFor(code, isDay: true), 'cloud', reason: '$code');
      expect(iconFor(code, isDay: false), 'cloud', reason: '$code');
    }
  });
}
