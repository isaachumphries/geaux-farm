import '../../garden/domain/planting.dart';
import '../../onboarding/domain/space.dart';
import '../../weather/domain/weather.dart';
import 'schedule_math.dart';

/// Copy shown on a care row when a skip is suggested for tomorrow's rain.
const rainSkipCopy = 'Rain expected tomorrow — consider skipping';

/// Whether a water task due on [due] should carry the rain-skip hint.
///
/// Only outdoor plantings in a rain-exposed space qualify. The task must be
/// due by tomorrow, and tomorrow's forecast must show at least 0.25 in of
/// precipitation with at least 70% probability. A missing probability counts
/// as no rain. See plan/05, watering model, "Rain hint".
bool rainHint({
  required Planting pl,
  required Space s,
  required DateTime due,
  required DateTime today,
  required Map<DateTime, WeatherDay> days,
}) {
  if (pl.setup != GrowSetup.outdoor || !s.rainExposed) return false;
  final tomorrow = addDays(dayOf(today), 1);
  if (dayOf(due).isAfter(tomorrow)) return false;
  final wx = days[tomorrow];
  if (wx == null) return false;
  return wx.precipIn >= 0.25 && (wx.precipProb ?? 0) >= 70;
}
