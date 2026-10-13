import '../../onboarding/domain/space.dart';

/// Catalog model for one `plants.json` record (plan/03 § Field reference).
///
/// The six scoring inputs (`sun`, `plantTempF`, `growTempF`, `starts`,
/// `water`, `space`) and `zones` may be absent so an importer can add
/// partial records; such plants are not [scorable]. Every other field is
/// required, and any present field with the wrong type or value throws a
/// [FormatException] naming the record id.
class Plant {
  const Plant({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.category,
    required this.purposes,
    required this.lifecycle,
    required this.seasonTags,
    required this.difficulty,
    required this.sun,
    required this.zones,
    required this.plantTempF,
    required this.growTempF,
    required this.frostTolerance,
    required this.humidity,
    required this.starts,
    required this.productiveDays,
    required this.maturityKind,
    required this.space,
    required this.water,
    required this.care,
    required this.tips,
    required this.image,
    required this.source,
  });

  final String id;
  final String commonName;
  final String scientificName;
  final PlantCategory category;
  final List<PlantPurpose> purposes;
  final Lifecycle lifecycle;
  final List<SeasonTag> seasonTags;

  /// 1 easy, 2 moderate, 3 challenging.
  final int difficulty;
  final List<SunLevel>? sun;
  final ZoneRange? zones;

  /// Monthly mean temperature (°F) suitable for planting.
  final TempRange? plantTempF;

  /// `min` is compared to the monthly average low, `max` to the average high.
  final TempRange? growTempF;
  final FrostTolerance frostTolerance;
  final Humidity humidity;

  /// First entry is the recommended start.
  final List<PlantStart>? starts;
  final int productiveDays;
  final MaturityKind maturityKind;
  final PlantSpace? space;
  final PlantWater? water;
  final PlantCare care;
  final List<String> tips;
  final PlantImage image;
  final String source;

  /// From `care.weeklyMinutes`: Low ≤ 15, Medium ≤ 40, otherwise High.
  MaintenanceLevel get maintenanceLevel {
    final m = care.weeklyMinutes;
    if (m <= 15) return MaintenanceLevel.low;
    if (m <= 40) return MaintenanceLevel.medium;
    return MaintenanceLevel.high;
  }

  /// Time-to-grow label from `starts[0]` and [maturityKind]; null when the
  /// record has no starts.
  String? get timeToGrowLabel {
    final s = starts;
    if (s == null || s.isEmpty) {
      return maturityKind == MaturityKind.foliage ? 'Grows year-round' : null;
    }
    final first = s.first;
    return switch (maturityKind) {
      MaturityKind.harvest =>
        'Harvest in ${first.daysMin}–${first.daysMax} days',
      MaturityKind.bloom => 'Blooms in ${first.daysMin}–${first.daysMax} days',
      MaturityKind.establish =>
        'Settles in over ~${(first.daysMax / 30).ceil()} months',
      MaturityKind.foliage => 'Grows year-round',
    };
  }

  /// Numeric hardiness range, e.g. 5a–8b → (min: 5.0, max: 8.5).
  ({double min, double max})? get zoneNumeric {
    final z = zones;
    if (z == null) return null;
    return (min: zoneNumericValue(z.min), max: zoneNumericValue(z.max));
  }

  /// Whether the record carries every input `scorePlant` needs.
  bool get scorable =>
      (sun?.isNotEmpty ?? false) &&
      plantTempF != null &&
      growTempF != null &&
      (starts?.isNotEmpty ?? false) &&
      water != null &&
      space != null &&
      (lifecycle != Lifecycle.perennial || zones != null);

  factory Plant.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final label = id is String ? id : '<missing id>';
    try {
      return Plant(
        id: _req<String>(json, 'id'),
        commonName: _req<String>(json, 'commonName'),
        scientificName: _req<String>(json, 'scientificName'),
        category: _enum(PlantCategory.values, _req<String>(json, 'category')),
        purposes: _reqList<String>(
          json,
          'purposes',
        ).map((v) => _enum(PlantPurpose.values, v)).toList(),
        lifecycle: _enum(Lifecycle.values, _req<String>(json, 'lifecycle')),
        seasonTags: _reqList<String>(
          json,
          'seasonTags',
        ).map((v) => _enum(SeasonTag.values, v)).toList(),
        difficulty: _req<int>(json, 'difficulty'),
        sun: _optList<String>(
          json,
          'sun',
        )?.map((v) => SunLevel.values.byName(v)).toList(),
        zones: _opt<Map<String, dynamic>>(json, 'zones')?.let(
          (m) => ZoneRange(_req<String>(m, 'min'), _req<String>(m, 'max')),
        ),
        plantTempF: _opt<Map<String, dynamic>>(
          json,
          'plantTempF',
        )?.let(TempRange._fromJson),
        growTempF: _opt<Map<String, dynamic>>(
          json,
          'growTempF',
        )?.let(TempRange._fromJson),
        frostTolerance: _enum(
          FrostTolerance.values,
          _req<String>(json, 'frostTolerance'),
        ),
        humidity: _enum(Humidity.values, _req<String>(json, 'humidity')),
        starts: _optList<Map<String, dynamic>>(json, 'starts')
            ?.map(
              (m) => PlantStart(
                method: _enum(StartMethod.values, _req<String>(m, 'method')),
                daysMin: _req<int>(m, 'daysMin'),
                daysMax: _req<int>(m, 'daysMax'),
              ),
            )
            .toList(),
        productiveDays: _req<int>(json, 'productiveDays'),
        maturityKind: _enum(
          MaturityKind.values,
          _req<String>(json, 'maturityKind'),
        ),
        space: _opt<Map<String, dynamic>>(json, 'space')?.let(
          (m) => PlantSpace(
            sqFtPerPlant: _req<num>(m, 'sqFtPerPlant').toDouble(),
            containerOk: _req<bool>(m, 'containerOk'),
            minContainerGal: _opt<num>(m, 'minContainerGal')?.toDouble(),
            indoorOk: _req<bool>(m, 'indoorOk'),
          ),
        ),
        water: _opt<Map<String, dynamic>>(json, 'water')?.let(
          (m) => PlantWater(
            need: _enum(WaterNeed.values, _req<String>(m, 'need')),
            everyDaysOutdoor: _req<int>(m, 'everyDaysOutdoor'),
            everyDaysIndoor: _req<int>(m, 'everyDaysIndoor'),
          ),
        ),
        care: _req<Map<String, dynamic>>(json, 'care').let(
          (m) => PlantCare(
            dailyMinutes: _req<int>(m, 'dailyMinutes'),
            weeklyMinutes: _req<int>(m, 'weeklyMinutes'),
            tasks: _reqList<Map<String, dynamic>>(m, 'tasks')
                .map(
                  (t) => CareTask(
                    type: _enum(TaskType.values, _req<String>(t, 'type')),
                    everyDays: _req<int>(t, 'everyDays'),
                    note: _req<String>(t, 'note'),
                  ),
                )
                .toList(),
          ),
        ),
        tips: _reqList<String>(json, 'tips'),
        image: _req<Map<String, dynamic>>(json, 'image').let(
          (m) => PlantImage(
            asset: _req<String>(m, 'asset'),
            credit: _req<String>(m, 'credit'),
            license: _req<String>(m, 'license'),
            sourceUrl: _opt<String>(m, 'sourceUrl'),
          ),
        ),
        source: _req<String>(json, 'source'),
      );
    } on FormatException catch (e) {
      throw FormatException('Plant "$label": ${e.message}');
    } on ArgumentError catch (e) {
      throw FormatException('Plant "$label": ${e.message}');
    }
  }
}

/// "8a" = 8.0, "8b" = 8.5 (plan/03 § Derived values).
double zoneNumericValue(String zone) {
  final m = RegExp(r'^(\d{1,2})([ab])$').firstMatch(zone);
  if (m == null) throw FormatException('Bad zone', zone);
  return int.parse(m[1]!) + (m[2] == 'b' ? 0.5 : 0.0);
}

enum MaintenanceLevel {
  low('Low'),
  medium('Medium'),
  high('High');

  const MaintenanceLevel(this.label);
  final String label;
}

/// A string-backed catalog enum; [json] is the value in `plants.json`.
abstract interface class JsonEnum {
  String get json;
}

enum PlantCategory implements JsonEnum {
  vegetable('vegetable'),
  herb('herb'),
  fruit('fruit'),
  flower('flower'),
  shrub('shrub'),
  houseplant('houseplant');

  const PlantCategory(this.json);
  @override
  final String json;
}

enum PlantPurpose implements JsonEnum {
  food('food'),
  design('design');

  const PlantPurpose(this.json);
  @override
  final String json;
}

/// Scoring treats biennial like annual.
enum Lifecycle implements JsonEnum {
  annual('annual'),
  biennial('biennial'),
  perennial('perennial');

  const Lifecycle(this.json);
  @override
  final String json;
}

enum SeasonTag implements JsonEnum {
  coolSeason('cool-season'),
  warmSeason('warm-season'),
  yearRound('year-round'),
  evergreen('evergreen'),
  deciduous('deciduous'),
  perennial('perennial'),
  winterInterest('winter-interest');

  const SeasonTag(this.json);
  @override
  final String json;
}

enum FrostTolerance implements JsonEnum {
  none('none'),
  light('light'),
  hard('hard');

  const FrostTolerance(this.json);
  @override
  final String json;
}

enum Humidity implements JsonEnum {
  low('low'),
  any('any'),
  high('high');

  const Humidity(this.json);
  @override
  final String json;
}

enum StartMethod implements JsonEnum {
  seed('seed'),
  transplant('transplant'),
  cutting('cutting');

  const StartMethod(this.json);
  @override
  final String json;
}

enum MaturityKind implements JsonEnum {
  harvest('harvest'),
  bloom('bloom'),
  establish('establish'),
  foliage('foliage');

  const MaturityKind(this.json);
  @override
  final String json;
}

enum WaterNeed implements JsonEnum {
  low('low'),
  medium('medium'),
  high('high');

  const WaterNeed(this.json);
  @override
  final String json;
}

enum TaskType implements JsonEnum {
  fertilize('fertilize'),
  prune('prune'),
  harvest('harvest'),
  other('other');

  const TaskType(this.json);
  @override
  final String json;
}

class TempRange {
  const TempRange(this.min, this.max);

  static TempRange _fromJson(Map<String, dynamic> m) =>
      TempRange(_req<num>(m, 'min').toDouble(), _req<num>(m, 'max').toDouble());

  final double min;
  final double max;
}

/// Hardiness zone range such as 5a–8b.
class ZoneRange {
  const ZoneRange(this.min, this.max);

  final String min;
  final String max;
}

class PlantStart {
  const PlantStart({
    required this.method,
    required this.daysMin,
    required this.daysMax,
  });

  final StartMethod method;
  final int daysMin;
  final int daysMax;
}

class PlantSpace {
  const PlantSpace({
    required this.sqFtPerPlant,
    required this.containerOk,
    required this.minContainerGal,
    required this.indoorOk,
  });

  final double sqFtPerPlant;
  final bool containerOk;

  /// Non-null exactly when [containerOk].
  final double? minContainerGal;
  final bool indoorOk;
}

class PlantWater {
  const PlantWater({
    required this.need,
    required this.everyDaysOutdoor,
    required this.everyDaysIndoor,
  });

  final WaterNeed need;
  final int everyDaysOutdoor;
  final int everyDaysIndoor;
}

class CareTask {
  const CareTask({
    required this.type,
    required this.everyDays,
    required this.note,
  });

  final TaskType type;
  final int everyDays;
  final String note;
}

class PlantCare {
  const PlantCare({
    required this.dailyMinutes,
    required this.weeklyMinutes,
    required this.tasks,
  });

  final int dailyMinutes;
  final int weeklyMinutes;
  final List<CareTask> tasks;
}

class PlantImage {
  const PlantImage({
    required this.asset,
    required this.credit,
    required this.license,
    required this.sourceUrl,
  });

  final String asset;
  final String credit;
  final String license;
  final String? sourceUrl;
}

T _req<T>(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is T) return v;
  throw FormatException(v == null ? 'missing "$key"' : '"$key" is not a $T');
}

T? _opt<T>(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v == null || v is T) return v as T?;
  throw FormatException('"$key" is not a $T');
}

List<T> _reqList<T>(Map<String, dynamic> m, String key) =>
    _req<List<dynamic>>(m, key).map((e) => _elem<T>(key, e)).toList();

List<T>? _optList<T>(Map<String, dynamic> m, String key) =>
    _opt<List<dynamic>>(m, key)?.map((e) => _elem<T>(key, e)).toList();

T _elem<T>(String key, Object? e) {
  if (e is T) return e;
  throw FormatException('"$key" has an entry that is not a $T');
}

E _enum<E extends JsonEnum>(List<E> values, String json) => values.firstWhere(
  (v) => v.json == json,
  orElse: () => throw FormatException('unknown value "$json"'),
);

extension<T extends Object> on T {
  R let<R>(R Function(T) f) => f(this);
}
