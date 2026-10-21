import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../care/domain/stage.dart';
import '../../catalog/data/catalog_provider.dart';
import '../../garden/data/plantings_provider.dart';
import '../../garden/domain/planting.dart';
import '../../onboarding/data/profile_providers.dart';
import '../../recommendations/application/clock_provider.dart';
import '../data/weather_alert_notifications.dart';
import '../data/weather_provider.dart';
import '../domain/garden_alerts.dart';

/// Active outdoor plantings, as the alert rules read them.
final outdoorPlantingsProvider = FutureProvider<List<OutdoorPlanting>>((
  ref,
) async {
  final plantings = await ref.watch(plantingsProvider.future);
  final plants = await ref.watch(catalogProvider.future);
  final today = ref.watch(todayProvider);
  final byId = {for (final p in plants) p.id: p};
  return [
    for (final pl in plantings)
      if (pl.status == PlantingStatus.active &&
          pl.setup == GrowSetup.outdoor &&
          pl.plantedOn != null)
        if (byId[pl.plantId] case final plant?)
          OutdoorPlanting(
            name: pl.nickname,
            frostTolerance: plant.frostTolerance,
            sprouting:
                stageOf(pl, plant, today).stage == PlantingStage.sprouting,
          ),
  ];
});

/// Garden alerts for today..today+2 from the cached forecast. Empty with no
/// outdoor plantings (the forecast isn't read then) or no forecast: an
/// alert is never invented without data.
final gardenAlertsProvider = FutureProvider<List<GardenAlert>>((ref) async {
  final outdoor = await ref.watch(outdoorPlantingsProvider.future);
  if (outdoor.isEmpty) return const [];
  final profile = await ref.watch(userProfileProvider.future);
  final today = ref.watch(todayProvider);
  final WeatherState weather;
  try {
    weather = await ref.watch(
      weatherProvider(forecastLocation(profile.lat, profile.lon)).future,
    );
  } catch (_) {
    return const [];
  }
  return evaluateAlerts(
    forecast: weather.snapshot.days,
    today: today,
    plantings: outdoor,
  );
});

final weatherAlertSchedulerProvider = Provider<WeatherAlertScheduler>(
  (ref) => WeatherAlertScheduler(ref.watch(notificationServiceProvider)),
);

/// Keeps the frost-eve notifications in step with the alerts. The app root
/// watches it. Each weather refresh, planting change, or profile change
/// (the alerts read the profile) re-evaluates the alerts, which replaces the
/// pending set. Notifications switched off in Settings schedule nothing.
final weatherAlertsSyncProvider = Provider<void>((ref) {
  Future<void> sync(List<GardenAlert> alerts) async {
    try {
      final profile = await ref.read(userProfileProvider.future);
      if (!ref.mounted) return;
      final now = ref.read(clockProvider)();
      await ref
          .read(weatherAlertSchedulerProvider)
          .replace(
            profile.notificationsEnabled
                ? planFrostNotices(alerts, now)
                : const [],
          );
    } on MissingPluginException {
      // No notification plugin on this platform. There is nothing to schedule.
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'notifications',
          context: ErrorDescription('while scheduling weather alerts'),
        ),
      );
    }
  }

  ref.listen(gardenAlertsProvider, (_, next) {
    // Wait for the fresh alerts instead of planning from the previous ones.
    if (next.isLoading) return;
    final alerts = next.value;
    if (alerts != null) unawaited(sync(alerts));
  });
});
