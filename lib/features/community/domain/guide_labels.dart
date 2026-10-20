import '../../onboarding/domain/space.dart';

/// The fixed tag list (plan/07 § Guide content shape).
const guideTags = [
  'vertical',
  'containers',
  'raised-bed',
  'hydroponic',
  'budget',
  'kids',
  'pollinators',
  'upcycled',
  'indoor',
  'louisiana',
];

/// "Raised bed" for `raised-bed`.
String guideTagLabel(String tag) {
  final words = tag.replaceAll('-', ' ');
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

/// Short space names for the feed's filter chips.
String guideSpaceTypeLabel(SpaceType type) => switch (type) {
  SpaceType.windowsill => 'Windowsill',
  SpaceType.balcony => 'Balcony',
  SpaceType.smallYard => 'Small yard',
  SpaceType.largeYard => 'Large yard',
  SpaceType.communityPlot => 'Community plot',
};

/// Difficulty 1 to 3 as words; anything else reads as the nearest end.
String guideDifficultyLabel(int difficulty) => switch (difficulty) {
  <= 1 => 'Easy',
  2 => 'Medium',
  _ => 'Hard',
};
