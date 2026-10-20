import 'weather.dart';

/// Material Symbols Rounded name for a WMO weather code (plan/06 § Condition
/// icons). Codes the plan does not list fall back to `cloud`.
String iconFor(int weatherCode, {required bool isDay}) =>
    WeatherCondition.of(weatherCode, isDay: isDay).iconName;
