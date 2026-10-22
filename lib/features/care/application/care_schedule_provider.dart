import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_provider.dart';
import '../../garden/data/plantings_provider.dart';
import '../../onboarding/data/profile_providers.dart';
import '../../recommendations/application/clock_provider.dart';
import '../../weather/data/weather_provider.dart';
import '../../weather/domain/weather.dart';
import '../data/drift_care_schedule_repository.dart';
import '../domain/care_event.dart';
import '../domain/care_schedule.dart';
import '../domain/schedule_math.dart';

final careEventsProvider = StreamProvider<List<CareEvent>>(
  (ref) => ref.watch(careScheduleRepositoryProvider).watchCareEvents(),
);

/// The forecast keyed by local day, as the care rules read it. Shared by the
/// care list and GD-02's next-water chip so both see the same weather.
///
/// Weather is memory-only and may be unavailable. If it fails, this is
/// empty, so [waterDue] falls back to its no-rain estimate.
final careForecastDaysProvider =
    FutureProvider.autoDispose<Map<DateTime, WeatherDay>>((ref) async {
      final profile = await ref.watch(userProfileProvider.future);
      try {
        final weather = await ref.watch(
          weatherProvider(forecastLocation(profile.lat, profile.lon)).future,
        );
        return {
          for (final d in weather.snapshot.days)
            dayOf(DateTime.parse(d.date)): d,
        };
      } catch (_) {
        // Keep the schedule usable offline; see the doc comment above.
        return const {};
      }
    });

/// The care list: this week's tasks plus overdue ones, each placed in free
/// time. Rebuilds when an input stream emits or the local day changes.
///
/// `now` is read once per build, so the "already started" cutoff goes stale
/// across a long-lived provider. The UI should invalidate on app resume.
///
/// Weather is memory-only and may be unavailable. If it fails, the schedule
/// uses an empty forecast, so [waterDue] falls back to its no-rain estimate.
final careScheduleProvider =
    FutureProvider.autoDispose<List<ScheduledCareTask>>((ref) async {
      final plantings = await ref.watch(plantingsProvider.future);
      final spaces = await ref.watch(spacesProvider.future);
      final events = await ref.watch(careEventsProvider.future);
      final profile = await ref.watch(userProfileProvider.future);
      final plants = await ref.watch(catalogProvider.future);
      final days = await ref.watch(careForecastDaysProvider.future);
      final today = ref.watch(todayProvider);
      final now = ref.read(clockProvider)();

      return buildCareSchedule(
        today: today,
        now: now,
        plantings: plantings,
        plantsById: {for (final p in plants) p.id: p},
        spacesById: {for (final s in spaces) s.id: s},
        events: events,
        availability: profile.availability,
        days: days,
      );
    });
