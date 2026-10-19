import 'dart:math' show max;

import '../../catalog/domain/plant.dart';
import '../../garden/domain/planting.dart';
import '../../onboarding/domain/space.dart';
import '../../weather/domain/weather.dart';
import 'care_event.dart';
import 'schedule_math.dart';

/// Float tolerance for the threshold test. n daily steps of `threshold / n`
/// can sum just under `threshold`.
const _eps = 1e-9;

/// Next watering date for [pl] from the soil-moisture deficit model
/// (plan/05 § Watering model; #17 spec).
///
/// [days] is keyed by local calendar day. A day with no entry falls back to
/// `threshold / everyDaysOutdoor` with no rain. [today] is part of the frozen
/// signature. A due date before [today] is returned unchanged; the caller
/// decides the overdue state.
///
/// A planting with no `water` or `skip_water` event is due on its planted day.
DateTime waterDue(
  Planting pl,
  Plant p,
  Space s,
  List<CareEvent> events,
  Map<DateTime, WeatherDay> days,
  DateTime today,
) {
  final water = p.water;
  if (water == null) {
    throw ArgumentError.value(p.id, 'p', 'has no water data');
  }
  final planted = pl.plantedOn;
  if (planted == null) {
    throw StateError('Planting ${pl.id} has no planted date');
  }
  final last = lastEventDay(
    pl.id,
    events,
    (e) => e.type == CareEventType.water || e.type == CareEventType.skipWater,
  );
  if (last == null) return dayOf(planted);

  if (pl.setup != GrowSetup.outdoor) {
    return addDays(last, water.everyDaysIndoor);
  }

  return addDays(last, deficitTrace(pl, p, s, last, days).length);
}

/// Soil-water deficit after each day past [last], one entry per day.
///
/// Stops at the first day whose deficit reaches the threshold; that day is the
/// last entry. Otherwise the trace covers `3 * everyDaysOutdoor` days. The due
/// date is therefore `last + trace.length`. A day missing from [days] uses the
/// no-rain fallback.
///
/// Exposed so the fixture tests can check the per-day deficits directly.
List<double> deficitTrace(
  Planting pl,
  Plant p,
  Space s,
  DateTime last,
  Map<DateTime, WeatherDay> days,
) {
  final water = p.water;
  if (water == null) {
    throw ArgumentError.value(p.id, 'p', 'has no water data');
  }
  final n = water.everyDaysOutdoor;
  final threshold = _threshold(water.need) * (pl.inContainer ? 0.5 : 1.0);
  final kc = _kc(water.need);
  final fallbackPerDay = threshold / n;
  final window = 3 * n;

  final trace = <double>[];
  var deficit = 0.0;
  for (var i = 1; i <= window; i++) {
    final wx = days[addDays(last, i)];
    if (wx == null) {
      deficit = max(0.0, deficit + fallbackPerDay);
    } else {
      final effRain = s.rainExposed ? 0.8 * wx.precipIn : 0.0;
      deficit = max(0.0, deficit + kc * wx.et0In - effRain);
    }
    trace.add(deficit);
    if (deficit >= threshold - _eps) break;
  }
  return trace;
}

double _threshold(WaterNeed need) => switch (need) {
  WaterNeed.low => 1.0,
  WaterNeed.medium => 0.6,
  WaterNeed.high => 0.4,
};

double _kc(WaterNeed need) => switch (need) {
  WaterNeed.low => 0.5,
  WaterNeed.medium => 0.8,
  WaterNeed.high => 1.05,
};
