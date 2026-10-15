import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/climate_profile.dart';

/// Reads and writes the stored climate profile (Drift `climate_months` and
/// `climate_meta`).
class ClimateRepository {
  ClimateRepository(this._db);

  final AppDatabase _db;

  /// Replaces the 12 month rows and the meta row (id 1) in one
  /// transaction. [lat] and [lon] are the location the profile was built
  /// for, rounded to 2 decimals.
  Future<void> saveProfile(
    ClimateProfile profile, {
    required double lat,
    required double lon,
  }) {
    return _db.transaction(() async {
      await _db.delete(_db.climateMonthsTable).go();
      await _db.batch((b) {
        b.insertAll(_db.climateMonthsTable, [
          for (final m in profile.months)
            ClimateMonthsTableCompanion.insert(
              month: Value(m.month),
              avgLowF: m.avgLowF,
              avgHighF: m.avgHighF,
              precipIn: m.precipIn,
              rhPct: m.rhPct,
              cloudPct: m.cloudPct,
              sunshineHours: m.sunshineHours,
            ),
        ]);
      });
      await _db
          .into(_db.climateMetaTable)
          .insertOnConflictUpdate(
            ClimateMetaTableCompanion.insert(
              id: const Value(1),
              annualExtremeMinF: profile.annualExtremeMinF,
              annualPrecipIn: profile.annualPrecipIn,
              annualRhPct: profile.annualRhPct,
              zone: profile.zone,
              zoneSource: profile.zoneSource,
              lastSpringFrostDoy: Value(profile.lastSpringFrostDoy),
              firstFallFrostDoy: Value(profile.firstFallFrostDoy),
              lat: _round2(lat),
              lon: _round2(lon),
              computedAt: profile.computedAt,
            ),
          );
    });
  }

  /// The stored profile, or null when none has been built.
  Future<ClimateProfile?> loadProfile() async {
    final meta = await _loadMeta();
    if (meta == null) return null;
    final months = await (_db.select(
      _db.climateMonthsTable,
    )..orderBy([(t) => OrderingTerm.asc(t.month)])).get();
    if (months.length != 12) return null;
    return ClimateProfile(
      months: [
        for (final m in months)
          ClimateMonth(
            month: m.month,
            avgLowF: m.avgLowF,
            avgHighF: m.avgHighF,
            precipIn: m.precipIn,
            rhPct: m.rhPct,
            cloudPct: m.cloudPct,
            sunshineHours: m.sunshineHours,
          ),
      ],
      annualExtremeMinF: meta.annualExtremeMinF,
      annualPrecipIn: meta.annualPrecipIn,
      annualRhPct: meta.annualRhPct,
      zone: meta.zone,
      zoneSource: meta.zoneSource,
      lastSpringFrostDoy: meta.lastSpringFrostDoy,
      firstFallFrostDoy: meta.firstFallFrostDoy,
      computedAt: meta.computedAt,
    );
  }

  /// The location the stored profile was built for, or null when none has
  /// been built.
  Future<({double lat, double lon})?> loadLocation() async {
    final meta = await _loadMeta();
    return meta == null ? null : (lat: meta.lat, lon: meta.lon);
  }

  Future<ClimateMetaRow?> _loadMeta() => (_db.select(
    _db.climateMetaTable,
  )..where((t) => t.id.equals(1))).getSingleOrNull();
}

double _round2(double v) => (v * 100).round() / 100;
