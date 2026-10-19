import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';

/// Material Symbols per [WeatherCondition.iconName]. Shared by WeatherMini
/// and WX-01 so both draw the same glyph set.
const weatherIcons = <String, IconData>{
  'clear_day': Symbols.clear_day_rounded,
  'clear_night': Symbols.clear_night_rounded,
  'partly_cloudy_day': Symbols.partly_cloudy_day_rounded,
  'cloud': Symbols.cloud_rounded,
  'foggy': Symbols.foggy_rounded,
  'rainy_light': Symbols.rainy_light_rounded,
  'rainy': Symbols.rainy_rounded,
  'weather_snowy': Symbols.weather_snowy_rounded,
  'thunderstorm': Symbols.thunderstorm_rounded,
};

/// Tint per condition: gold for sun, tiger purple for night, frost blue for
/// rain and storms, soil for everything else.
Color weatherIconColor(String iconName) => switch (iconName) {
  'clear_day' || 'partly_cloudy_day' => AppColors.geauxGold,
  'clear_night' => AppColors.tigerPurple,
  'rainy_light' || 'rainy' || 'thunderstorm' => AppColors.frost,
  _ => AppColors.soil600,
};
