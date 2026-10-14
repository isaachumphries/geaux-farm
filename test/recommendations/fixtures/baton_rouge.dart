// Baton Rouge, LA climate (Open-Meteo archive 2021–2025) and the
// worked-example user from plan/04 § Fixture and worked example.
import 'dart:convert';
import 'dart:io';

import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';

/// Index 0 = January.
const batonRougeMonths = <ClimateMonth>[
  ClimateMonth(
    month: 1,
    avgLowF: 42.9,
    avgHighF: 60.6,
    precipIn: 5.41,
    rhPct: 75,
    cloudPct: 0,
    sunshineHours: 0,
  ),
  ClimateMonth(
    month: 2,
    avgLowF: 47.5,
    avgHighF: 65.9,
    precipIn: 3.96,
    rhPct: 77,
    cloudPct: 0,
    sunshineHours: 0,
  ),
  ClimateMonth(
    month: 3,
    avgLowF: 54.3,
    avgHighF: 72.3,
    precipIn: 5.60,
    rhPct: 75,
    cloudPct: 0,
    sunshineHours: 0,
  ),
  ClimateMonth(
    month: 4,
    avgLowF: 60.6,
    avgHighF: 77.9,
    precipIn: 5.37,
    rhPct: 74,
    cloudPct: 0,
    sunshineHours: 0,
  ),
  ClimateMonth(
    month: 5,
    avgLowF: 68.7,
    avgHighF: 84.8,
    precipIn: 6.37,
    rhPct: 77,
    cloudPct: 0,
    sunshineHours: 0,
  ),
  ClimateMonth(
    month: 6,
    avgLowF: 74.4,
    avgHighF: 90.0,
    precipIn: 4.42,
    rhPct: 77,
    cloudPct: 0,
    sunshineHours: 0,
  ),
  ClimateMonth(
    month: 7,
    avgLowF: 76.6,
    avgHighF: 90.7,
    precipIn: 5.36,
    rhPct: 80,
    cloudPct: 0,
    sunshineHours: 0,
  ),
  ClimateMonth(
    month: 8,
    avgLowF: 76.6,
    avgHighF: 92.1,
    precipIn: 5.21,
    rhPct: 74,
    cloudPct: 0,
    sunshineHours: 0,
  ),
  ClimateMonth(
    month: 9,
    avgLowF: 71.6,
    avgHighF: 87.9,
    precipIn: 5.37,
    rhPct: 73,
    cloudPct: 0,
    sunshineHours: 0,
  ),
  ClimateMonth(
    month: 10,
    avgLowF: 62.6,
    avgHighF: 81.1,
    precipIn: 2.12,
    rhPct: 69,
    cloudPct: 0,
    sunshineHours: 0,
  ),
  ClimateMonth(
    month: 11,
    avgLowF: 53.7,
    avgHighF: 71.0,
    precipIn: 3.48,
    rhPct: 75,
    cloudPct: 0,
    sunshineHours: 0,
  ),
  ClimateMonth(
    month: 12,
    avgLowF: 49.7,
    avgHighF: 66.3,
    precipIn: 5.51,
    rhPct: 79,
    cloudPct: 0,
    sunshineHours: 0,
  ),
];

final batonRougeClimate = ClimateProfile(
  months: batonRougeMonths,
  annualExtremeMinF: 19.66,
  annualPrecipIn: 58.18,
  annualRhPct: 75,
  zone: '8b',
  zoneSource: ZoneSource.computed,
  // Feb 20 median last spring frost; no fall frost.
  lastSpringFrostDoy: 51,
  firstFallFrostDoy: null,
  computedAt: DateTime.utc(2026, 10, 7),
);

const workedExampleProfile = UserProfile(
  city: 'Baton Rouge',
  admin1: 'Louisiana',
  countryCode: 'US',
  lat: 30.45,
  lon: -91.19,
  timezone: 'America/Chicago',
  goals: [Goal.food, Goal.hobby],
  experience: Experience.beginner,
  availability: Availability([64, 0, 64, 0, 0, 2, 2]),
);

Space balcony(int areaSqFt) => Space(
  id: 'balcony',
  type: SpaceType.balcony,
  areaSqFt: areaSqFt,
  sun: SunLevel.partial,
  rainExposed: true,
  inContainerDefault: true,
);

/// plan/04 worked example: balcony 32 sq ft.
final workedExample = UserContext(
  profile: workedExampleProfile,
  space: balcony(32),
  climate: batonRougeClimate,
);

/// The app's default user until onboarding lands: balcony 18 sq ft.
final defaultUser = UserContext(
  profile: workedExampleProfile,
  space: balcony(18),
  climate: batonRougeClimate,
);

final workedExampleDate = DateTime(2026, 10, 7);

/// The four plan/03 reference records, keyed by id, in file order.
Map<String, Plant> loadReferencePlants() => {
  for (final r in jsonDecode(
    File('assets/plants/plants.json').readAsStringSync(),
  ) as List)
    r['id'] as String: Plant.fromJson(r as Map<String, dynamic>),
};

/// [workedExampleProfile] with selected answers replaced.
UserProfile profileWith({
  Availability? availability,
  List<Goal>? goals,
  Experience? experience,
}) => UserProfile(
  city: workedExampleProfile.city,
  admin1: workedExampleProfile.admin1,
  countryCode: workedExampleProfile.countryCode,
  lat: workedExampleProfile.lat,
  lon: workedExampleProfile.lon,
  timezone: workedExampleProfile.timezone,
  goals: goals ?? workedExampleProfile.goals,
  experience: experience ?? workedExampleProfile.experience,
  availability: availability ?? workedExampleProfile.availability,
);

/// The raw kale JSON record, for building variants.
Map<String, dynamic> rawKale() =>
    (jsonDecode(
          File('assets/plants/plants.json').readAsStringSync(),
        ) as List).first
        as Map<String, dynamic>;
