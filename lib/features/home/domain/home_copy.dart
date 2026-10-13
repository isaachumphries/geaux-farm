import 'package:intl/intl.dart';

import '../../onboarding/domain/space.dart';

/// Home header greeting for the local time [now]: "Good morning!" before
/// 12:00, "Good afternoon!" before 17:00, then "Good evening!".
String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning!';
  if (now.hour < 17) return 'Good afternoon!';
  return 'Good evening!';
}

/// Overline date above the greeting, e.g. "WEDNESDAY, OCT 7".
String homeDateLine(DateTime today) =>
    DateFormat('EEEE, MMM d', 'en_US').format(today).toUpperCase();

/// How Home names a space in running text ("your balcony").
String spaceNoun(SpaceType type) => switch (type) {
  SpaceType.windowsill => 'windowsill',
  SpaceType.balcony => 'balcony',
  SpaceType.smallYard => 'yard bed',
  SpaceType.largeYard => 'yard',
  SpaceType.communityPlot => 'community plot',
};

/// HM-01 subline under "Pick your first plant".
String topMatchesLine(SpaceType type, String city) =>
    'Top matches for your ${spaceNoun(type)} in $city';

/// HM-01b slim-card subline from the recommended plants' names, in list
/// order: "{A}, {B} and {n−2} more fit your {space}.", "{A} and {B} fit
/// …", or "{A} fits …". Null when nothing is recommended.
String? slimCardLine(List<String> names, SpaceType type) {
  final space = 'your ${spaceNoun(type)}.';
  return switch (names.length) {
    0 => null,
    1 => '${names[0]} fits $space',
    2 => '${names[0]} and ${names[1]} fit $space',
    final n => '${names[0]}, ${names[1]} and ${n - 2} more fit $space',
  };
}
