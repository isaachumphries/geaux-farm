import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/climate/data/archive_client.dart';
import 'package:geaux_farm/features/climate/data/climate_repository.dart';
import 'package:geaux_farm/features/climate/data/climate_service.dart';
import 'package:geaux_farm/features/climate/data/phzmap_client.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'baton_rouge_archive.dart';

/// Records saves instead of writing Drift, so the service can run on the
/// fake clock of `testWidgets`.
class _RecordingRepository extends Fake implements ClimateRepository {
  final saved = <ClimateProfile>[];

  @override
  Future<void> saveProfile(
    ClimateProfile profile, {
    required double lat,
    required double lon,
  }) async => saved.add(profile);
}

/// The Baton Rouge archive with [keep] deciding which days stay.
String _archiveWhere(bool Function(DateTime day) keep) {
  final json = jsonDecode(archiveFixtureBody()) as Map<String, dynamic>;
  final daily = json['daily'] as Map<String, dynamic>;
  final time = (daily['time'] as List).cast<String>();
  final kept = [
    for (var i = 0; i < time.length; i++)
      if (keep(DateTime.parse(time[i]))) i,
  ];
  json['daily'] = {
    for (final MapEntry(:key, :value) in daily.entries)
      key: [for (final i in kept) (value as List)[i]],
  };
  return jsonEncode(json);
}

/// plan/04 § Climate profile steps 1, 4 and 6: archive failures throw
/// `ClimateUnavailableException` and store nothing; any phzmapi failure
/// falls back to the computed zone (`annualExtremeMinF + 60`).
void main() {
  late _RecordingRepository repository;
  late List<Uri> requests;
  late Future<http.Response> Function() archive;
  late Future<http.Response> Function() phzmap;

  setUp(() {
    repository = _RecordingRepository();
    requests = [];
    archive = () async => http.Response(archiveFixtureBody(), 200);
    phzmap = () async => http.Response('{"zone":"9a"}', 200);
  });

  Future<ClimateProfile> build({
    String countryCode = 'US',
    String? postcode = '70803',
  }) {
    final client = AppHttpClient(
      MockClient((request) {
        requests.add(request.url);
        return request.url.host == 'phzmapi.org' ? phzmap() : archive();
      }),
    );
    return ClimateService(
      archive: ArchiveClient(client),
      phzmap: PhzmapClient(client),
      repository: repository,
      now: () => DateTime(2026, 10, 7, 9),
    ).build(
      lat: 30.45,
      lon: -91.19,
      countryCode: countryCode,
      postcode: postcode,
    );
  }

  Iterable<Uri> phzmapCalls() => requests.where((u) => u.host == 'phzmapi.org');

  group('archive failure → ClimateUnavailableException, nothing saved', () {
    for (final (label, body) in [
      ('a month with no rows', () => _archiveWhere((d) => d.month != 6)),
      ('no rows at all', () => _archiveWhere((_) => false)),
      (
        'daily arrays of different lengths',
        () => archiveFixtureBody().replaceFirst(
          '"temperature_2m_min":[',
          '"temperature_2m_min":[50.0,',
        ),
      ),
    ]) {
      test(label, () async {
        archive = () async => http.Response(body(), 200);
        await expectLater(build(), throwsA(isA<ClimateUnavailableException>()));
        expect(repository.saved, isEmpty);
        expect(phzmapCalls(), isEmpty);
      });
    }

    test('HTTP 429 is sent once, never retried', () async {
      archive = () async => http.Response('{"error":true}', 429);
      await expectLater(build(), throwsA(isA<ClimateUnavailableException>()));
      expect(requests, hasLength(1));
      expect(repository.saved, isEmpty);
    });
  });

  group('phzmapi failure → computed zone 8b from 19.64 °F', () {
    for (final (label, response) in [
      ('a non-JSON body', () => http.Response('<html>', 200)),
      ('a JSON array', () => http.Response('[]', 200)),
      ('an empty zone', () => http.Response('{"zone":""}', 200)),
      ('a numeric zone', () => http.Response('{"zone":8}', 200)),
      ('HTTP 500', () => http.Response('{"zone":"9a"}', 500)),
    ]) {
      test(label, () async {
        phzmap = () async => response();
        final p = await build();
        expect(phzmapCalls(), hasLength(1));
        expect(p.zone, '8b');
        expect(p.zoneSource, ZoneSource.computed);
        expect(repository.saved.single.zoneSource, ZoneSource.computed);
      });
    }

    testWidgets('a lookup that hangs past the 15 s timeout', (tester) async {
      phzmap = () => Completer<http.Response>().future;
      ClimateProfile? profile;
      unawaited(build().then((p) => profile = p));

      await tester.pump(const Duration(seconds: 14));
      expect(profile, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(profile?.zone, '8b');
      expect(profile?.zoneSource, ZoneSource.computed);
      expect(phzmapCalls(), hasLength(1));
    });
  });

  group('phzmapi only for countryCode US with a 5-digit postcode', () {
    test('US 70803 → the phzmapi zone, source usda', () async {
      final p = await build();
      expect(phzmapCalls().single.path, '/70803.json');
      expect(p.zone, '9a');
      expect(p.zoneSource, ZoneSource.usda);
    });

    for (final (country, postcode) in [
      ('US', '070803'),
      ('US', '7080A'),
      ('US', ' 70803'),
      ('US', ''),
      ('PR', '00901'),
      ('DE', '10115'),
    ]) {
      test('$country "$postcode" → no lookup, computed 8b', () async {
        final p = await build(countryCode: country, postcode: postcode);
        expect(phzmapCalls(), isEmpty);
        expect(p.zone, '8b');
        expect(p.zoneSource, ZoneSource.computed);
      });
    }
  });
}
