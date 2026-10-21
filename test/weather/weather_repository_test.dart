import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_repository.dart';
import 'package:geaux_farm/features/weather/domain/weather.dart';

import '../helpers/in_memory_database.dart';

// plan/06 § Caching and refresh: the 14 daily rows are upserted by date,
// `current` is replaced as raw JSON in row 1, and rows older than 30 days
// are pruned after every save.
void main() {
  final fixture = jsonDecode(
    File('test/fixtures/open_meteo/forecast_baton_rouge.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final now = DateTime(2026, 10, 13, 17, 20);

  late ProviderContainer container;
  late AppDatabase db;
  late WeatherRepository repo;

  setUp(() {
    container = ProviderContainer(overrides: [inMemoryDatabaseOverride()]);
    addTearDown(container.dispose);
    db = container.read(appDatabaseProvider);
    repo = container.read(weatherRepositoryProvider);
  });

  WeatherSnapshot payload({DateTime? fetchedAt}) =>
      OpenMeteoForecastClient.parseForecast(
        fixture,
        fetchedAt: fetchedAt ?? now,
      );

  Future<List<String>> dates() async {
    final rows = await (db.select(
      db.weatherDaysTable,
    )..orderBy([(t) => OrderingTerm.asc(t.date)])).get();
    return [for (final r in rows) r.date];
  }

  /// A bare daily row for [date], used to seed data the prune should see.
  Future<void> seedDay(String date) => db
      .into(db.weatherDaysTable)
      .insert(
        WeatherDaysTableCompanion.insert(
          date: date,
          weatherCode: 3,
          tmaxF: 80,
          tminF: 60,
          precipIn: 0,
          sunshineS: 0,
          daylightS: 0,
          et0In: 0,
          sunrise: '${date}T07:00',
          sunset: '${date}T19:00',
          fetchedAt: now.subtract(const Duration(days: 31)),
        ),
      );

  test('a save writes the 14 daily rows', () async {
    await repo.saveForecast(payload(), now);
    expect(await dates(), hasLength(14));
    expect((await dates()).first, '2026-10-06');
    expect((await dates()).last, '2026-10-19');
  });

  test('saving the same payload twice upserts, leaving 14 rows', () async {
    await repo.saveForecast(payload(), now);
    final later = now.add(const Duration(hours: 2));
    await repo.saveForecast(payload(fetchedAt: later), later);
    expect(await dates(), hasLength(14));
    final row = await (db.select(
      db.weatherDaysTable,
    )..where((t) => t.date.equals('2026-10-13'))).getSingle();
    expect(row.fetchedAt, later);
  });

  test('the prune drops today − 31 days and keeps today − 30', () async {
    await seedDay('2026-09-12'); // today − 31
    await seedDay('2026-09-13'); // today − 30
    await repo.saveForecast(payload(), now);
    final kept = await dates();
    expect(kept, contains('2026-09-13'));
    expect(kept, isNot(contains('2026-09-12')));
    expect(kept, hasLength(15));
  });

  test(
    'weather_current holds one row, id 1, with the raw current block',
    () async {
      await repo.saveForecast(payload(), now);
      final rows = await db.select(db.weatherCurrentTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 1);
      expect(rows.single.fetchedAt, now);
      expect(jsonDecode(rows.single.json), fixture['current']);
    },
  );

  test('a second save replaces weather_current', () async {
    await repo.saveForecast(payload(), now);
    final later = now.add(const Duration(hours: 2));
    await repo.saveForecast(payload(fetchedAt: later), later);
    final rows = await db.select(db.weatherCurrentTable).get();
    expect(rows, hasLength(1));
    expect(rows.single.fetchedAt, later);
  });

  test('loadCached returns null before anything is saved', () async {
    expect(await repo.loadCached(), isNull);
  });

  test('loadCached reads back the saved forecast', () async {
    final saved = await repo.saveForecast(payload(), now).then((_) {
      return repo.loadCached();
    });
    final cached = saved!;
    expect(cached.fetchedAt, now);
    expect(cached.days, hasLength(14));
    expect(cached.currentJson, fixture['current']);

    final source = payload();
    expect(cached.current.temperatureF, source.current.temperatureF);
    expect(cached.current.weatherCode, source.current.weatherCode);
    expect(cached.current.isDay, source.current.isDay);
    expect(cached.current.time, source.current.time);

    final today = cached.days.firstWhere((d) => d.date == '2026-10-13');
    final sourceToday = source.days.firstWhere((d) => d.date == '2026-10-13');
    expect(today.tmaxF, sourceToday.tmaxF);
    expect(today.tminF, sourceToday.tminF);
    expect(today.precipIn, sourceToday.precipIn);
    expect(today.precipProb, sourceToday.precipProb);
    expect(today.uvMax, sourceToday.uvMax);
    expect(today.et0In, sourceToday.et0In);
    expect(today.sunrise, sourceToday.sunrise);
    expect(today.sunset, sourceToday.sunset);
  });
}
