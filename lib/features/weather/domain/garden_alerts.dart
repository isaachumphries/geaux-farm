import 'package:intl/intl.dart';

import '../../catalog/domain/plant.dart';
import 'weather.dart';

/// The garden alert kinds plan/06 § Garden alerts defines.
enum GardenAlertType { frost, heat, rain, uv }

/// An active outdoor planting, reduced to what the alert rules read.
class OutdoorPlanting {
  const OutdoorPlanting({
    required this.name,
    required this.frostTolerance,
    required this.sprouting,
  });

  /// Nickname shown in the frost copy.
  final String name;
  final FrostTolerance frostTolerance;

  /// Whether the planting's stage today is Sprouting (the UV rule).
  final bool sprouting;
}

/// One alert for one day, with its banner copy.
class GardenAlert {
  const GardenAlert({
    required this.type,
    required this.day,
    required this.message,
  });

  final GardenAlertType type;

  /// Local calendar date the alert is about (midnight).
  final DateTime day;
  final String message;
}

/// Frost thresholds in °F by tolerance, inclusive (`min ≤ threshold`).
const frostThresholdF = {
  FrostTolerance.none: 34.0,
  FrostTolerance.light: 28.0,
  FrostTolerance.hard: 20.0,
};

const heatThresholdF = 95.0;
const heavyRainThresholdIn = 1.0;
const highUvThreshold = 8.0;

/// Days evaluated after today (today, today+1, today+2).
const _windowDays = 2;

/// Alerts for [forecast] over today..today+2 (plan/06 § Garden alerts).
/// Empty when there are no active outdoor [plantings]. Ordered by day, then
/// frost, heat, rain, UV. Pure: [today] is the user's local date.
List<GardenAlert> evaluateAlerts({
  required List<WeatherDay> forecast,
  required DateTime today,
  required List<OutdoorPlanting> plantings,
}) {
  if (plantings.isEmpty) return const [];
  final start = DateTime(today.year, today.month, today.day);
  final end = DateTime(start.year, start.month, start.day + _windowDays);

  final days = [
    for (final row in forecast)
      if (_dayOf(row) case final day?
          when !day.isBefore(start) && !day.isAfter(end))
        (day, row),
  ]..sort((a, b) => a.$1.compareTo(b.$1));

  final alerts = <GardenAlert>[];
  for (final (day, row) in days) {
    final weekday = DateFormat('EEE', 'en_US').format(day);
    final frosted = [
      for (final p in plantings)
        if (row.tminF <= frostThresholdF[p.frostTolerance]!) p.name,
    ];
    if (frosted.isNotEmpty) {
      alerts.add(
        GardenAlert(
          type: GardenAlertType.frost,
          day: day,
          message: 'Frost $weekday: cover or bring in ${frosted.join(', ')}',
        ),
      );
    }
    if (row.tmaxF >= heatThresholdF) {
      alerts.add(
        GardenAlert(
          type: GardenAlertType.heat,
          day: day,
          message: 'Heat $weekday: water early and shade young plants',
        ),
      );
    }
    if (row.precipIn >= heavyRainThresholdIn) {
      alerts.add(
        GardenAlert(
          type: GardenAlertType.rain,
          day: day,
          message:
              'Heavy rain $weekday: check drainage — your watering '
              'schedule already accounts for it',
        ),
      );
    }
    final uv = row.uvMax;
    if (day == start &&
        uv != null &&
        uv >= highUvThreshold &&
        plantings.any((p) => p.sprouting)) {
      alerts.add(
        GardenAlert(
          type: GardenAlertType.uv,
          day: day,
          message: 'High UV today: shade new seedlings at midday',
        ),
      );
    }
  }
  return alerts;
}

/// Parses a `yyyy-MM-dd` row date as a local date; null when malformed.
DateTime? _dayOf(WeatherDay row) {
  final parsed = DateTime.tryParse(row.date);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// First notification id reserved for weather alerts. Care reminder ids are
/// the UTC minute of a future slot (#21), tens of millions since 2026, so
/// this low block can never collide with them.
const weatherAlertIdBase = 1000;

/// Most weather alert notifications pending at once (plan/06).
const weatherAlertBudget = 3;

/// Whether [id] is in the reserved weather alert block.
bool isWeatherAlertId(int id) =>
    id >= weatherAlertIdBase && id < weatherAlertIdBase + weatherAlertBudget;

/// A frost-eve notification to schedule.
class FrostNotice {
  const FrostNotice({required this.id, required this.at, required this.body});

  final int id;

  /// Local wall-clock time it fires: 18:00 the evening before the frost.
  final DateTime at;
  final String body;
}

/// Frost-eve notices for [alerts]: 18:00 local on the day before each frost
/// day, skipping times not after [now], keeping the [weatherAlertBudget]
/// soonest. Ids run up from [weatherAlertIdBase] in time order.
List<FrostNotice> planFrostNotices(List<GardenAlert> alerts, DateTime now) {
  final frosts = alerts.where((a) => a.type == GardenAlertType.frost).toList()
    ..sort((a, b) => a.day.compareTo(b.day));
  final notices = <FrostNotice>[];
  for (final alert in frosts) {
    if (notices.length == weatherAlertBudget) break;
    final d = alert.day;
    final at = DateTime(d.year, d.month, d.day - 1, 18);
    if (!at.isAfter(now)) continue;
    notices.add(
      FrostNotice(
        id: weatherAlertIdBase + notices.length,
        at: at,
        body: alert.message,
      ),
    );
  }
  return notices;
}
