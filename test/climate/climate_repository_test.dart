import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/climate/data/climate_repository.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';

ClimateProfile _profile({
  String zone = '8b',
  int? spring = 51,
  int? fall,
  DateTime? at,
}) => ClimateProfile(
  months: [
    for (var m = 1; m <= 12; m++)
      ClimateMonth(
        month: m,
        avgLowF: 40.0 + m,
        avgHighF: 60.0 + m,
        precipIn: m / 2,
        rhPct: 70.0 + m / 10,
        cloudPct: 50.0 - m,
        sunshineHours: 8 + m / 4,
      ),
  ],
  annualExtremeMinF: 19.66,
  annualPrecipIn: 58.18,
  annualRhPct: 75,
  zone: zone,
  zoneSource: ZoneSource.computed,
  lastSpringFrostDoy: spring,
  firstFallFrostDoy: fall,
  computedAt: at ?? DateTime(2026, 10, 7, 9, 30),
);

void main() {
  late AppDatabase db;
  late ClimateRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    repository = ClimateRepository(db);
  });

  test('nothing stored → null', () async {
    expect(await repository.loadProfile(), isNull);
    expect(await repository.loadLocation(), isNull);
  });

  test('saving twice leaves 12 month rows and one meta row', () async {
    await repository.saveProfile(_profile(), lat: 30.45, lon: -91.19);
    await repository.saveProfile(
      _profile(zone: '9a', at: DateTime(2026, 10, 8)),
      lat: 30.46,
      lon: -91.2,
    );

    expect(await db.select(db.climateMonthsTable).get(), hasLength(12));
    final meta = await db.select(db.climateMetaTable).get();
    expect(meta, hasLength(1));
    expect(meta.single.id, 1);
    expect(meta.single.zone, '9a');
    expect(meta.single.computedAt, DateTime(2026, 10, 8));
    expect(await repository.loadLocation(), (lat: 30.46, lon: -91.2));
  });

  test('stores the location rounded to 2 decimals', () async {
    await repository.saveProfile(_profile(), lat: 30.4512, lon: -91.1871);
    expect(await repository.loadLocation(), (lat: 30.45, lon: -91.19));
  });

  test('loadProfile round-trips every field, including null frost', () async {
    final saved = _profile(spring: null, fall: null);
    await repository.saveProfile(saved, lat: 30.45, lon: -91.19);

    final p = (await repository.loadProfile())!;
    expect(p.months, hasLength(12));
    for (var i = 0; i < 12; i++) {
      final a = saved.months[i], b = p.months[i];
      expect(b.month, a.month);
      expect(b.avgLowF, a.avgLowF);
      expect(b.avgHighF, a.avgHighF);
      expect(b.precipIn, a.precipIn);
      expect(b.rhPct, a.rhPct);
      expect(b.cloudPct, a.cloudPct);
      expect(b.sunshineHours, a.sunshineHours);
    }
    expect(p.annualExtremeMinF, saved.annualExtremeMinF);
    expect(p.annualPrecipIn, saved.annualPrecipIn);
    expect(p.annualRhPct, saved.annualRhPct);
    expect(p.zone, saved.zone);
    expect(p.zoneSource, saved.zoneSource);
    expect(p.lastSpringFrostDoy, isNull);
    expect(p.firstFallFrostDoy, isNull);
    expect(p.computedAt, saved.computedAt);
  });

  test('frost days round-trip when set', () async {
    await repository.saveProfile(
      _profile(spring: 51, fall: 330),
      lat: 30.45,
      lon: -91.19,
    );
    final p = (await repository.loadProfile())!;
    expect(p.lastSpringFrostDoy, 51);
    expect(p.firstFallFrostDoy, 330);
  });
}
