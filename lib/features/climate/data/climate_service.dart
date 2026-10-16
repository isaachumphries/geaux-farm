import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/db/app_database.dart';
import '../../../core/http.dart';
import '../domain/climate_normals.dart';
import '../domain/climate_profile.dart';
import '../domain/frost_dates.dart';
import '../domain/zone_calculator.dart';
import 'archive_client.dart';
import 'climate_repository.dart';
import 'phzmap_client.dart';

/// Builds the climate profile for a location and stores it (plan/04
/// § Climate profile): one archive request, at most one phzmapi request,
/// then a single Drift transaction. No retries.
class ClimateService {
  ClimateService({
    required this.archive,
    required this.phzmap,
    required this.repository,
    required this.now,
  });

  final ArchiveClient archive;
  final PhzmapClient phzmap;
  final ClimateRepository repository;
  final DateTime Function() now;

  static final _usZip = RegExp(r'^\d{5}$');

  /// Throws [ClimateUnavailableException] when the archive fails; nothing
  /// is stored then. A phzmapi failure falls back to the computed zone.
  Future<ClimateProfile> build({
    required double lat,
    required double lon,
    required String countryCode,
    String? postcode,
  }) async {
    final at = now();
    final rows = await archive.fetchDaily(lat, lon, currentYear: at.year);

    final List<ClimateMonth> months;
    final AnnualClimate annual;
    try {
      months = monthlyNormals(rows);
      annual = annualValues(rows, months);
    } on FormatException catch (e) {
      throw ClimateUnavailableException('Incomplete archive: ${e.message}');
    }

    var zone = computeZone(annual.extremeMinF);
    var zoneSource = ZoneSource.computed;
    if (countryCode == 'US' && postcode != null && _usZip.hasMatch(postcode)) {
      try {
        zone = await phzmap.fetchZone(postcode);
        zoneSource = ZoneSource.usda;
      } on Object {
        // Any phzmapi failure keeps the computed zone.
      }
    }

    final frost = frostDates(rows, lat);
    final profile = ClimateProfile(
      months: months,
      annualExtremeMinF: annual.extremeMinF,
      annualPrecipIn: annual.precipIn,
      annualRhPct: annual.rhPct,
      zone: zone,
      zoneSource: zoneSource,
      lastSpringFrostDoy: frost.lastSpringFrostDoy,
      firstFallFrostDoy: frost.firstFallFrostDoy,
      computedAt: at,
    );
    await repository.saveProfile(profile, lat: lat, lon: lon);
    return profile;
  }
}

final climateRepositoryProvider = Provider<ClimateRepository>(
  (ref) => ClimateRepository(ref.watch(appDatabaseProvider)),
);

final climateServiceProvider = Provider<ClimateService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  final appHttp = AppHttpClient(client);
  return ClimateService(
    archive: ArchiveClient(appHttp),
    phzmap: PhzmapClient(appHttp),
    repository: ref.watch(climateRepositoryProvider),
    now: DateTime.now,
  );
});
