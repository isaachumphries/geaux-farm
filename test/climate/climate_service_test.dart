import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/climate/data/archive_client.dart';
import 'package:geaux_farm/features/climate/data/climate_repository.dart';
import 'package:geaux_farm/features/climate/data/climate_service.dart';
import 'package:geaux_farm/features/climate/data/phzmap_client.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'baton_rouge_archive.dart';

void main() {
  late AppDatabase db;
  late ClimateRepository repository;
  late List<Uri> requests;
  late http.Response Function(Uri) archive;
  late http.Response Function(Uri) phzmap;
  final now = DateTime(2026, 10, 7, 9);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    repository = ClimateRepository(db);
    requests = [];
    archive = (_) => http.Response(archiveFixtureBody(), 200);
    phzmap = (_) => http.Response('{"zone":"8b"}', 200);
  });

  ClimateService service() {
    final client = AppHttpClient(
      MockClient((request) async {
        requests.add(request.url);
        if (request.url.host == 'phzmapi.org') return phzmap(request.url);
        return archive(request.url);
      }),
    );
    return ClimateService(
      archive: ArchiveClient(client),
      phzmap: PhzmapClient(client),
      repository: repository,
      now: () => now,
    );
  }

  Future<ClimateProfile> build({String countryCode = 'US', String? postcode}) =>
      service().build(
        lat: 30.45,
        lon: -91.19,
        countryCode: countryCode,
        postcode: postcode,
      );

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
          .read<int>('n');

  test('the archive request is the plan/04 URL for the last 5 years', () {
    final uri = ArchiveClient.archiveUri(30.45, -91.19, currentYear: 2026);
    expect(uri.host, 'archive-api.open-meteo.com');
    expect(uri.path, '/v1/archive');
    expect(uri.queryParameters, {
      'latitude': '30.45',
      'longitude': '-91.19',
      'start_date': '2021-01-01',
      'end_date': '2025-12-31',
      'daily':
          'temperature_2m_min,temperature_2m_max,precipitation_sum,'
          'relative_humidity_2m_mean,cloud_cover_mean,sunshine_duration',
      'timezone': 'auto',
      'temperature_unit': 'fahrenheit',
      'precipitation_unit': 'inch',
    });
  });

  test('builds the full Baton Rouge profile', () async {
    final p = await build();

    expect(requests, hasLength(1));
    expect(requests.single.queryParameters['start_date'], '2021-01-01');
    expect(p.months, hasLength(12));
    for (final (m, low, high, precip, rh, cloud, sun) in recordedMonths) {
      final got = p.months[m - 1];
      expect(got.avgLowF, closeTo(low, 0.01));
      expect(got.avgHighF, closeTo(high, 0.01));
      expect(got.precipIn, closeTo(precip, 0.01));
      expect(got.rhPct, closeTo(rh, 0.01));
      expect(got.cloudPct, closeTo(cloud, 0.01));
      expect(got.sunshineHours, closeTo(sun, 0.01));
    }
    expect(p.annualExtremeMinF, closeTo(19.64, 0.01));
    expect(p.zone, '8b');
    expect(p.zoneSource, ZoneSource.computed);
    expect(p.lastSpringFrostDoy, 51);
    expect(p.firstFallFrostDoy, isNull);
    expect(p.computedAt, now);
  });

  test('US ZIP 70803 uses the phzmapi zone', () async {
    final p = await build(postcode: '70803');
    expect(requests.last.toString(), 'https://phzmapi.org/70803.json');
    expect(p.zone, '8b');
    expect(p.zoneSource, ZoneSource.usda);
  });

  test('the phzmapi zone wins over the computed one', () async {
    phzmap = (_) => http.Response('{"zone":"9a"}', 200);
    final p = await build(postcode: '70803');
    expect(p.zone, '9a');
    expect(p.zoneSource, ZoneSource.usda);
  });

  for (final (label, response) in [
    ('throws', () => throw http.ClientException('down')),
    ('returns 404', () => http.Response('nope', 404)),
    ('has no zone', () => http.Response('{"temperature_range":"x"}', 200)),
  ]) {
    test('phzmapi $label → computed zone, no exception', () async {
      phzmap = (_) => response();
      final p = await build(postcode: '70803');
      expect(requests.where((u) => u.host == 'phzmapi.org'), hasLength(1));
      expect(p.zone, '8b');
      expect(p.zoneSource, ZoneSource.computed);
    });
  }

  for (final (country, postcode) in [
    ('CA', '70803'),
    ('US', null),
    ('US', '7080'),
    ('US', '70803-1234'),
  ]) {
    test('$country $postcode: no phzmapi call, computed zone', () async {
      final p = await build(countryCode: country, postcode: postcode);
      expect(requests.where((u) => u.host == 'phzmapi.org'), isEmpty);
      expect(p.zoneSource, ZoneSource.computed);
    });
  }

  for (final (label, response) in [
    ('throws', () => throw http.ClientException('down')),
    ('returns 500', () => http.Response('oops', 500)),
    ('is not JSON', () => http.Response('<html>', 200)),
    ('has no daily block', () => http.Response('{"latitude":1}', 200)),
  ]) {
    test(
      'archive $label → ClimateUnavailableException, nothing stored',
      () async {
        archive = (_) => response();
        await expectLater(build(), throwsA(isA<ClimateUnavailableException>()));
        expect(requests, hasLength(1));
        expect(await count('climate_months'), 0);
        expect(await count('climate_meta'), 0);
      },
    );
  }

  test('a second build replaces the stored rows', () async {
    await build();
    await build(postcode: '70803');
    expect(await count('climate_months'), 12);
    expect(await count('climate_meta'), 1);
    final stored = await repository.loadProfile();
    expect(stored!.zoneSource, ZoneSource.usda);
    expect(await repository.loadLocation(), (lat: 30.45, lon: -91.19));
  });
}
