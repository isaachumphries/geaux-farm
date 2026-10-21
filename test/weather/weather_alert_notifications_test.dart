import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/core/notifications/notification_providers.dart';
import 'package:geaux_farm/core/notifications/notification_service.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/weather/application/garden_alerts_provider.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_alert_notifications.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:geaux_farm/features/weather/domain/garden_alerts.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:timezone/timezone.dart' as tz;

import '../garden/garden_harness.dart';
import '../helpers/file_asset_bundle.dart';
import '../helpers/recording_notification_plugin.dart';

/// Wednesday, Oct 7 2026, 09:00.
final _now = DateTime(2026, 10, 7, 9);

WeatherDay _day(
  int offset, {
  double tmin = 60,
  double tmax = 70,
  double precip = 0,
  double uv = 3,
}) {
  final d = DateTime(2026, 10, 7 + offset);
  final key =
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  return WeatherDay(
    date: key,
    weatherCode: 0,
    tmaxF: tmax,
    tminF: tmin,
    precipIn: precip,
    precipProb: 0,
    uvMax: uv,
    sunshineS: 0,
    daylightS: 0,
    et0In: 0,
    sunrise: '${key}T07:00',
    sunset: '${key}T18:30',
  );
}

/// The fake forecast's `current` block. The cache stores it verbatim and
/// reads it back through `parseCurrent`, so it has to be a complete block.
const _currentJson = <String, Object?>{
  'time': '2026-10-07T09:00',
  'temperature_2m': 60,
  'relative_humidity_2m': 50,
  'cloud_cover': 0,
  'precipitation': 0,
  'weather_code': 0,
  'uv_index': 3,
  'is_day': 1,
};

/// Serves [days] as the forecast; counts fetches.
class _FakeForecast extends OpenMeteoForecastClient {
  _FakeForecast(this.days)
    : super(MockClient((_) async => http.Response('', 500)));

  List<WeatherDay> days;
  int fetches = 0;

  @override
  Future<WeatherSnapshot> fetchForecast(
    double lat,
    double lon, {
    required DateTime fetchedAt,
  }) async {
    fetches++;
    return WeatherSnapshot(
      current: OpenMeteoForecastClient.parseCurrent(_currentJson),
      currentJson: _currentJson,
      days: days,
      fetchedAt: fetchedAt,
    );
  }
}

NotificationService _service(
  RecordingNotificationPlugin plugin,
  AppDatabase db,
) => NotificationService(plugin, db, () async => 'America/Chicago');

FrostNotice _notice(int i, DateTime at) =>
    FrostNotice(id: weatherAlertIdBase + i, at: at, body: 'Frost $i');

void main() {
  group('WeatherAlertScheduler', () {
    test('schedules on the weather channel at 18:00 local', () async {
      final db = openGardenDb();
      final plugin = RecordingNotificationPlugin();
      await WeatherAlertScheduler(_service(plugin, db))
          .replace([_notice(0, DateTime(2026, 10, 8, 18))]);

      final n = plugin.pendingById[weatherAlertIdBase]!;
      expect(n.channelId, 'weather_alerts');
      expect(n.title, 'Weather alerts');
      expect(n.body, 'Frost 0');
      expect(n.payload, 'weather');
      expect(n.scheduledDate.location.name, 'America/Chicago');
      expect(
        n.scheduledDate,
        tz.TZDateTime(tz.getLocation('America/Chicago'), 2026, 10, 8, 18),
      );
    });

    test('a second replace swaps the set and leaves care reminders', () async {
      final db = openGardenDb();
      final plugin = RecordingNotificationPlugin()
        ..seed(29000000, 'care?date=2026-10-08');
      final scheduler = WeatherAlertScheduler(_service(plugin, db));

      await scheduler.replace([
        _notice(0, DateTime(2026, 10, 8, 18)),
        _notice(1, DateTime(2026, 10, 9, 18)),
      ]);
      await scheduler.replace([_notice(0, DateTime(2026, 10, 10, 18))]);

      expect(plugin.pendingById.keys, unorderedEquals([29000000, 1000]));
      expect(plugin.pendingById[1000]!.body, 'Frost 0');
      expect(
        plugin.pendingById[1000]!.scheduledDate.day,
        10,
        reason: 'the new set replaced the old one',
      );
    });

    test('never more than 3 pending', () async {
      final db = openGardenDb();
      final plugin = RecordingNotificationPlugin();
      await WeatherAlertScheduler(_service(plugin, db)).replace([
        for (var i = 0; i < 5; i++) _notice(i, DateTime(2026, 10, 8 + i, 18)),
      ]);
      expect(plugin.pendingById.keys, [1000, 1001, 1002]);
    });

    test('four unordered frost days schedule the soonest three', () async {
      final db = openGardenDb();
      final plugin = RecordingNotificationPlugin();
      final alerts = [
        for (final day in [11, 9, 10, 8])
          GardenAlert(
            type: GardenAlertType.frost,
            day: DateTime(2026, 10, day),
            message: 'Frost $day',
          ),
      ];
      await WeatherAlertScheduler(_service(plugin, db))
          .replace(planFrostNotices(alerts, _now));
      expect(plugin.pendingById.values.map((n) => n.body), [
        'Frost 8',
        'Frost 9',
        'Frost 10',
      ]);
    });
  });

  group('weatherAlertsSyncProvider', () {
    Future<(ProviderContainer, RecordingNotificationPlugin, _FakeForecast)>
    setUpSync({
      required List<WeatherDay> days,
      GrowSetup setup = GrowSetup.outdoor,
      PlantingStatus status = PlantingStatus.active,
      String startMethod = 'transplant',
      DateTime? plantedOn,
      String units = 'imperial',
      bool notificationsEnabled = true,
    }) async {
      final db = openGardenDb();
      await seedSpace(db);
      await seedProfile(db);
      await (db.update(db.userProfileTable)..where((t) => t.id.equals(1)))
          .write(UserProfileTableCompanion(units: Value(units)));
      if (!notificationsEnabled) {
        await (db.update(
          db.userProfileTable,
        )..where((t) => t.id.equals(1))).write(
          const UserProfileTableCompanion(notificationsEnabled: Value(false)),
        );
      }
      // Kale is frost-hard (≤20 °F), so 20 °F frosts it and 21 °F doesn't.
      await seedPlanting(
        db,
        setup: setup,
        status: status,
        startMethod: startMethod,
        plantedOn: plantedOn ?? DateTime(2026, 9, 1),
      );
      final plugin = RecordingNotificationPlugin();
      final forecast = _FakeForecast(days);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          assetBundleProvider.overrideWithValue(FileAssetBundle()),
          clockProvider.overrideWithValue(() => _now),
          weatherClockProvider.overrideWithValue(() => _now),
          forecastClientProvider.overrideWithValue(forecast),
          notificationServiceProvider.overrideWithValue(_service(plugin, db)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(weatherAlertsSyncProvider, (_, _) {});
      await _settle(container);
      return (container, plugin, forecast);
    }

    test('a frost day schedules its notice the evening before', () async {
      final (_, plugin, _) = await setUpSync(
        days: [_day(0), _day(1), _day(2, tmin: 20)],
      );
      final pending = plugin.pendingById.values.where(
        (n) => isWeatherAlertId(n.id),
      );
      expect(pending, hasLength(1));
      expect(pending.single.body, 'Frost Fri: cover or bring in Kale');
      expect(pending.single.scheduledDate.day, 8);
      expect(pending.single.scheduledDate.hour, 18);
    });

    // One setUpSync per test: each builds its own AppDatabase and
    // ProviderContainer, and two of them alive at once make drift warn
    // about a second database on the same executor (#126).
    test('a warm night schedules nothing', () async {
      final (_, warm, _) = await setUpSync(days: [_day(2, tmin: 21)]);
      expect(warm.pendingById.keys.where(isWeatherAlertId), isEmpty);
    });

    test('an indoor planting schedules nothing', () async {
      final (_, indoor, _) = await setUpSync(
        days: [_day(2, tmin: 10)],
        setup: GrowSetup.indoor,
      );
      expect(indoor.pendingById.keys.where(isWeatherAlertId), isEmpty);
    });

    for (final (setup, status) in [
      (GrowSetup.indoor, PlantingStatus.active),
      (GrowSetup.greenhouse, PlantingStatus.active),
      (GrowSetup.outdoor, PlantingStatus.planned),
      (GrowSetup.outdoor, PlantingStatus.harvested),
      (GrowSetup.outdoor, PlantingStatus.removed),
    ]) {
      test('${setup.name}/${status.name} never contributes alerts', () async {
        final (container, plugin, forecast) = await setUpSync(
          days: [_day(0, tmin: 10, tmax: 95, precip: 1, uv: 8)],
          setup: setup,
          status: status,
          startMethod: 'seed',
          plantedOn: DateTime(2026, 10, 7),
        );
        expect(await container.read(gardenAlertsProvider.future), isEmpty);
        expect(plugin.pendingById.keys.where(isWeatherAlertId), isEmpty);
        expect(forecast.fetches, 0);
      });
    }

    test('UV uses the outdoor seed stage, not indoor seedlings', () async {
      final (container, _, _) = await setUpSync(days: [_day(0, uv: 8)]);
      final db = container.read(appDatabaseProvider);
      await seedPlanting(
        db,
        id: 'seedling',
        setup: GrowSetup.indoor,
        startMethod: 'seed',
        plantedOn: DateTime(2026, 10, 7),
      );
      await _settle(container);
      expect(await container.read(gardenAlertsProvider.future), isEmpty);

      await (db.update(
        db.plantingsTable,
      )..where((t) => t.id.equals('seedling'))).write(
        const PlantingsTableCompanion(setup: Value(GrowSetup.outdoor)),
      );
      await _settle(container);
      expect(
        (await container.read(gardenAlertsProvider.future)).single.message,
        'High UV today: shade new seedlings at midday',
      );
    });

    test('metric display does not convert forecast alert thresholds', () async {
      for (final units in ['imperial', 'metric']) {
        final (container, plugin, _) = await setUpSync(
          days: [_day(0, tmax: 95, precip: 1, uv: 8), _day(1, tmin: 20)],
          startMethod: 'seed',
          plantedOn: DateTime(2026, 10, 7),
          units: units,
        );
        expect(
          [
            for (final alert in await container.read(
              gardenAlertsProvider.future,
            ))
              alert.message,
          ],
          [
            'Heat Wed: water early and shade young plants',
            'Heavy rain Wed: check drainage — your watering schedule already '
                'accounts for it',
            'High UV today: shade new seedlings at midday',
            'Frost Thu: cover or bring in Kale',
          ],
          reason: units,
        );
        expect(plugin.pendingById[1000]!.scheduledDate.hour, 18);
      }
    });

    test('removing the last outdoor planting clears frost notices', () async {
      final (container, plugin, _) = await setUpSync(days: [_day(2, tmin: 20)]);
      expect(plugin.pendingById.keys.where(isWeatherAlertId), hasLength(1));
      final db = container.read(appDatabaseProvider);
      await (db.update(
        db.plantingsTable,
      )..where((t) => t.id.equals('p1'))).write(
        const PlantingsTableCompanion(status: Value(PlantingStatus.removed)),
      );
      await _settle(container);
      expect(await container.read(gardenAlertsProvider.future), isEmpty);
      expect(plugin.pendingById.keys.where(isWeatherAlertId), isEmpty);
    });

    test('notifications switched off schedule nothing', () async {
      final (_, plugin, _) = await setUpSync(
        days: [_day(2, tmin: 10)],
        notificationsEnabled: false,
      );
      expect(plugin.pendingById.keys.where(isWeatherAlertId), isEmpty);
    });

    test('switching notifications off clears pending alerts', () async {
      final (container, plugin, _) = await setUpSync(days: [_day(2, tmin: 10)]);
      expect(plugin.pendingById.keys.where(isWeatherAlertId), hasLength(1));

      final db = container.read(appDatabaseProvider);
      await (db.update(
        db.userProfileTable,
      )..where((t) => t.id.equals(1))).write(
        const UserProfileTableCompanion(notificationsEnabled: Value(false)),
      );
      await _settle(container);

      expect(plugin.pendingById.keys.where(isWeatherAlertId), isEmpty);
    });

    test('a weather refresh replaces the pending set', () async {
      final (container, plugin, forecast) = await setUpSync(
        days: [_day(2, tmin: 10)],
      );
      expect(plugin.pendingById.keys.where(isWeatherAlertId), hasLength(1));

      forecast.days = [_day(1, tmin: 10), _day(2, tmin: 60)];
      final location = forecastLocation(30.45, -91.19);
      await container
          .read(weatherProvider(location).notifier)
          .refresh(force: true);
      await _settle(container);

      final pending = plugin.pendingById.values
          .where((n) => isWeatherAlertId(n.id))
          .toList();
      expect(pending, hasLength(1));
      expect(pending.single.body, 'Frost Thu: cover or bring in Kale');
      expect(forecast.fetches, 2);
    });

    test(
      'disposing during profile loading cancels sync without an error',
      () async {
        final profiles = StreamController<UserProfile>();
        addTearDown(profiles.close);
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = previous);
        final container = ProviderContainer(
          overrides: [
            outdoorPlantingsProvider.overrideWith((ref) async => []),
            userProfileProvider.overrideWith((ref) => profiles.stream),
          ],
        );
        container.listen(weatherAlertsSyncProvider, (_, _) {});
        await _settle(container);
        container.dispose();
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(errors, isEmpty);
      },
    );
  });
}

/// Lets Drift streams, the forecast, and the sync's async work finish.
Future<void> _settle(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  await container.read(gardenAlertsProvider.future);
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
