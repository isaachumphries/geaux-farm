import '../../climate/domain/climate_profile.dart';
import '../../onboarding/domain/space.dart';
import '../../onboarding/domain/user_profile.dart';

/// Score band: great ≥ 80, good 60–79, possible 40–59, indoor < 40
/// ("Tough here", drawn in the indoor color).
enum CompatLevel { great, good, possible, indoor }

/// Everything `scorePlant` needs about the user.
class UserContext {
  const UserContext({
    required this.profile,
    required this.space,
    required this.climate,
  });

  final UserProfile profile;
  final Space space;
  final ClimateProfile climate;
}

class Compatibility {
  const Compatibility({
    required this.score,
    required this.level,
    required this.fits,
    required this.inSeason,
    required this.outdoorViable,
    required this.monthStrip,
  });

  final int score;
  final CompatLevel level;

  /// Keys: climate, light, space, care, goals, experience; each 0–1.
  final Map<String, double> fits;
  final bool inSeason;
  final bool outdoorViable;

  /// 12 entries, index 0 = January.
  final List<bool> monthStrip;
}
