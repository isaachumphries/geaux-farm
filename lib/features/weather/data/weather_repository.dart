import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../domain/weather.dart';
import 'forecast_client.dart';

/// How long a daily row is kept after its date passes (plan/06 § Caching
/// and refresh). The row dated exactly today − 30 days is still kept.
const forecastHistory = Duration(days: 30);

/// The on-device forecast cache: Drift `weather_days` (one row per date)
/// and `weather_current` (the raw `current` block, id 1).
///
/// One location's forecast is cached at a time, which is what the schema
/// in plan/09 § Drift schema describes: neither table carries lat/lon, and
/// the app only ever fetches for the profile's location.
class WeatherRepository {
  WeatherRepository(this._db);

  final AppDatabase _db;

  /// Upserts the daily rows, replaces the `current` row, and prunes rows
  /// older than 30 days, in one transaction. [now] stamps `fetched_at`.
  Future<void> saveForecast(WeatherSnapshot payload, DateTime now) {
    return _db.transaction(() async {
      await _db.batch((b) {
        b.insertAllOnConflictUpdate(_db.weatherDaysTable, [
          for (final day in payload.days)
            WeatherDaysTableCompanion.insert(
              date: day.date,
              weatherCode: day.weatherCode,
              tmaxF: day.tmaxF,
              tminF: day.tminF,
              precipIn: day.precipIn,
              precipProb: Value(day.precipProb),
              uvMax: Value(day.uvMax),
              sunshineS: day.sunshineS,
              daylightS: day.daylightS,
              et0In: day.et0In,
              sunrise: day.sunrise,
              sunset: day.sunset,
              fetchedAt: now,
            ),
        ]);
      });
      await _db
          .into(_db.weatherCurrentTable)
          .insertOnConflictUpdate(
            WeatherCurrentTableCompanion.insert(
              id: const Value(1),
              json: jsonEncode(payload.currentJson),
              fetchedAt: now,
            ),
          );
      final cutoff = _dateKey(
        DateTime(now.year, now.month, now.day).subtract(forecastHistory),
      );
      await (_db.delete(
        _db.weatherDaysTable,
      )..where((t) => t.date.isSmallerThanValue(cutoff))).go();
    });
  }

  /// The cached forecast, or null when nothing has been saved yet. Its
  /// `fetchedAt` comes from the `weather_current` row, which every save
  /// replaces.
  Future<WeatherSnapshot?> loadCached() async {
    final current = await (_db.select(
      _db.weatherCurrentTable,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (current == null) return null;
    final currentJson = jsonDecode(current.json) as Map<String, dynamic>;
    final rows = await (_db.select(
      _db.weatherDaysTable,
    )..orderBy([(t) => OrderingTerm.asc(t.date)])).get();
    return WeatherSnapshot(
      current: OpenMeteoForecastClient.parseCurrent(currentJson),
      currentJson: currentJson,
      days: [
        for (final r in rows)
          WeatherDay(
            date: r.date,
            weatherCode: r.weatherCode,
            tmaxF: r.tmaxF,
            tminF: r.tminF,
            precipIn: r.precipIn,
            precipProb: r.precipProb,
            uvMax: r.uvMax,
            sunshineS: r.sunshineS,
            daylightS: r.daylightS,
            et0In: r.et0In,
            sunrise: r.sunrise,
            sunset: r.sunset,
          ),
      ],
      fetchedAt: current.fetchedAt,
    );
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// The forecast cache over the device database.
final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => WeatherRepository(ref.watch(appDatabaseProvider)),
);
