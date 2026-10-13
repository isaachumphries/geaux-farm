/// Forecast domain types (pure Dart). Values stay in °F and inches exactly
/// as Open-Meteo returns them; display conversion happens in the UI.
library;

/// The `current` block of the forecast response.
class WeatherCurrent {
  const WeatherCurrent({
    required this.temperatureF,
    required this.relativeHumidity,
    required this.cloudCover,
    required this.precipitationIn,
    required this.weatherCode,
    required this.uvIndex,
    required this.isDay,
    required this.time,
  });

  final double temperatureF;
  final int relativeHumidity;
  final int cloudCover;
  final double precipitationIn;
  final int weatherCode;
  final double uvIndex;
  final bool isDay;

  /// Local wall-clock time at the location (`timezone=auto`).
  final DateTime time;

  WeatherCondition get condition =>
      WeatherCondition.of(weatherCode, isDay: isDay);
}

/// One daily row; mirrors the Drift `weather_days` table (plan/09).
class WeatherDay {
  const WeatherDay({
    required this.date,
    required this.weatherCode,
    required this.tmaxF,
    required this.tminF,
    required this.precipIn,
    required this.precipProb,
    required this.uvMax,
    required this.sunshineS,
    required this.daylightS,
    required this.et0In,
    required this.sunrise,
    required this.sunset,
  });

  /// Local date, `yyyy-MM-dd` (the table's primary key).
  final String date;
  final int weatherCode;
  final double tmaxF;
  final double tminF;
  final double precipIn;
  final int? precipProb;
  final double? uvMax;
  final double sunshineS;
  final double daylightS;
  final double et0In;

  /// Local ISO time strings, e.g. `2026-10-13T07:05`.
  final String sunrise;
  final String sunset;
}

/// One successful forecast fetch.
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.current,
    required this.days,
    required this.fetchedAt,
  });

  final WeatherCurrent current;
  final List<WeatherDay> days;
  final DateTime fetchedAt;
}

/// Label and Material Symbols Rounded icon name for a WMO weather code
/// (plan/06 § Condition icons).
class WeatherCondition {
  const WeatherCondition._(this.label, this.iconName);

  final String label;
  final String iconName;

  static const _clearDay = WeatherCondition._('Clear', 'clear_day');
  static const _clearNight = WeatherCondition._('Clear', 'clear_night');
  static const _partlyCloudy = WeatherCondition._(
    'Partly cloudy',
    'partly_cloudy_day',
  );
  static const _overcast = WeatherCondition._('Overcast', 'cloud');
  static const _fog = WeatherCondition._('Fog', 'foggy');
  static const _drizzle = WeatherCondition._('Drizzle', 'rainy_light');
  static const _rain = WeatherCondition._('Rain', 'rainy');
  static const _snow = WeatherCondition._('Snow', 'weather_snowy');
  static const _thunder = WeatherCondition._('Thunderstorm', 'thunderstorm');

  /// Codes the plan does not list fall back to Overcast / `cloud`.
  static WeatherCondition of(int code, {required bool isDay}) {
    if (code == 0) return isDay ? _clearDay : _clearNight;
    if (code == 1 || code == 2) return _partlyCloudy;
    if (code == 3) return _overcast;
    if (code == 45 || code == 48) return _fog;
    if (code >= 51 && code <= 57) return _drizzle;
    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return _rain;
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) return _snow;
    if (code >= 95 && code <= 99) return _thunder;
    return _overcast;
  }
}

/// Maximum age of a snapshot before app start/resume triggers a refetch.
const staleAfter = Duration(minutes: 60);

/// True when the snapshot is more than 60 minutes old (exactly 60 is fresh).
bool isStale(DateTime fetchedAt, DateTime now) =>
    now.difference(fetchedAt) > staleAfter;

/// The row whose date equals [todayLocal]'s calendar date, if present.
WeatherDay? todayRow(List<WeatherDay> days, DateTime todayLocal) {
  final key =
      '${todayLocal.year.toString().padLeft(4, '0')}-'
      '${todayLocal.month.toString().padLeft(2, '0')}-'
      '${todayLocal.day.toString().padLeft(2, '0')}';
  for (final day in days) {
    if (day.date == key) return day;
  }
  return null;
}
