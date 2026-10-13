import '../../catalog/domain/plant.dart';
import '../../climate/domain/climate_profile.dart';

/// Months a planting started now occupies: `min(12, ceil((starts[0].daysMax
/// + productiveDays) / 30))`.
int seasonWindowMonths(Plant p) =>
    ((p.starts!.first.daysMax + p.productiveDays) / 30).ceil().clamp(1, 12);

/// Whether month [m] (0-based index into [months]) suits growing [p]: the
/// average low is ≥ `growTempF.min` and the average high ≤ `growTempF.max`.
bool growMonthOk(Plant p, List<ClimateMonth> months, int index) {
  final c = months[index % 12];
  final g = p.growTempF!;
  return c.avgLowF >= g.min && c.avgHighF <= g.max;
}

/// plan/04 § In-season rule. [months] is indexed 0 = January; [month] is
/// 1–12. Planting is in season when the month's mean temperature is inside
/// `plantTempF` and every month of the growing window passes [growMonthOk].
bool inSeason(Plant p, List<ClimateMonth> months, int month) {
  final mean = months[month - 1].meanF;
  final plant = p.plantTempF!;
  if (mean < plant.min || mean > plant.max) return false;
  final n = seasonWindowMonths(p);
  for (var k = 0; k < n; k++) {
    if (!growMonthOk(p, months, month - 1 + k)) return false;
  }
  return true;
}
