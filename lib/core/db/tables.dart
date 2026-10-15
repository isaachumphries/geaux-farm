import 'package:drift/drift.dart';

import '../../features/climate/domain/climate_profile.dart';
import '../../features/garden/domain/planting.dart';
import '../../features/onboarding/domain/space.dart';
import '../../features/onboarding/domain/user_profile.dart';
import 'converters.dart';

// Schema v1 from plan/09 § Drift schema. Enum columns store the Dart enum
// `name`, except `care_events.type`, which stores snake_case (#33).

@DataClassName('UserProfileRow')
class UserProfileTable extends Table {
  @override
  String get tableName => 'user_profile';

  IntColumn get id => integer()();
  TextColumn get city => text()();
  TextColumn get admin1 => text()();
  TextColumn get countryCode => text()();
  TextColumn get postcode => text().nullable()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get timezone => text()();
  TextColumn get goals => text().map(const GoalsConverter())();
  TextColumn get goalOtherText => text().nullable()();
  TextColumn get experience => textEnum<Experience>()();
  TextColumn get heardFrom => textEnum<HeardFrom>().nullable()();
  TextColumn get heardOtherText => text().nullable()();
  TextColumn get availability => text().map(const AvailabilityConverter())();
  TextColumn get units => text()();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get notificationPermissionAsked =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get firstPlantPromptDismissed =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get onboardingCompletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SpaceRow')
class SpacesTable extends Table {
  @override
  String get tableName => 'spaces';

  TextColumn get id => text()();
  TextColumn get type => textEnum<SpaceType>()();
  IntColumn get areaSqFt => integer()();
  TextColumn get sun => textEnum<SunLevel>()();
  BoolColumn get sunUnsure => boolean()();
  BoolColumn get rainExposed => boolean()();
  BoolColumn get inContainerDefault => boolean()();
  BoolColumn get isPrimary => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ClimateMonthRow')
class ClimateMonthsTable extends Table {
  @override
  String get tableName => 'climate_months';

  IntColumn get month => integer()();
  RealColumn get avgLowF => real()();
  RealColumn get avgHighF => real()();
  RealColumn get precipIn => real()();
  RealColumn get rhPct => real()();
  RealColumn get cloudPct => real()();
  RealColumn get sunshineHours => real()();

  @override
  Set<Column> get primaryKey => {month};
}

@DataClassName('ClimateMetaRow')
class ClimateMetaTable extends Table {
  @override
  String get tableName => 'climate_meta';

  IntColumn get id => integer()();
  RealColumn get annualExtremeMinF => real()();
  RealColumn get annualPrecipIn => real()();
  RealColumn get annualRhPct => real()();
  TextColumn get zone => text()();
  TextColumn get zoneSource => textEnum<ZoneSource>()();
  IntColumn get lastSpringFrostDoy => integer().nullable()();
  IntColumn get firstFallFrostDoy => integer().nullable()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  DateTimeColumn get computedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WeatherDayRow')
class WeatherDaysTable extends Table {
  @override
  String get tableName => 'weather_days';

  TextColumn get date => text()();
  IntColumn get weatherCode => integer()();
  RealColumn get tmaxF => real()();
  RealColumn get tminF => real()();
  RealColumn get precipIn => real()();
  IntColumn get precipProb => integer().nullable()();
  RealColumn get uvMax => real().nullable()();
  RealColumn get sunshineS => real()();
  RealColumn get daylightS => real()();
  RealColumn get et0In => real()();
  TextColumn get sunrise => text()();
  TextColumn get sunset => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date};
}

@DataClassName('WeatherCurrentRow')
class WeatherCurrentTable extends Table {
  @override
  String get tableName => 'weather_current';

  IntColumn get id => integer()();
  TextColumn get json => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlantingRow')
class PlantingsTable extends Table {
  @override
  String get tableName => 'plantings';

  TextColumn get id => text()();
  TextColumn get plantId => text()();
  TextColumn get spaceId => text()();
  TextColumn get nickname => text()();
  TextColumn get setup => textEnum<GrowSetup>()();
  BoolColumn get inContainer => boolean()();
  TextColumn get startMethod => text()();
  DateTimeColumn get plantedOn => dateTime().nullable()();
  TextColumn get status => textEnum<PlantingStatus>()();
  TextColumn get projectId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CareEventRow')
class CareEventsTable extends Table {
  @override
  String get tableName => 'care_events';

  TextColumn get id => text()();
  TextColumn get plantingId =>
      text().references(PlantingsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text().map(const CareEventTypeConverter())();
  DateTimeColumn get at => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get photoPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GuideProjectRow')
class GuideProjectsTable extends Table {
  @override
  String get tableName => 'guide_projects';

  TextColumn get id => text()();
  TextColumn get guideId => text()();
  TextColumn get title => text()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get materialsJson => text()();
  TextColumn get stepsJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
