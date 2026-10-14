import '../../climate/domain/climate_profile.dart';

/// Home season line, e.g. "Fall · Cool-season planting in Baton Rouge"
/// (plan/04 § Season line). [months] is indexed 0 = January.
String seasonLine({
  required String city,
  required double latitude,
  required List<ClimateMonth> months,
  required DateTime today,
}) {
  final index = today.month - 1;
  final seasonIndex = latitude < 0 ? (index + 6) % 12 : index;
  final mean =
      (months[index].meanF +
          months[(index + 1) % 12].meanF +
          months[(index + 2) % 12].meanF) /
      3;
  return '${_seasons[seasonIndex]} · ${seasonPhrase(mean)} in $city';
}

/// Phrase for the three-month mean temperature.
String seasonPhrase(double meanF) {
  if (meanF < 40) return 'Indoor growing season';
  if (meanF < 65) return 'Cool-season planting';
  return 'Warm-season planting';
}

const _seasons = [
  'Winter',
  'Winter',
  'Spring',
  'Spring',
  'Spring',
  'Summer',
  'Summer',
  'Summer',
  'Fall',
  'Fall',
  'Fall',
  'Winter',
];
