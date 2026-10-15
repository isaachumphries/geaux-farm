import 'space.dart';
import 'user_profile.dart';

const _unset = Object();

/// The in-memory onboarding answers (plan/02 § Persistence). Each step
/// fills its own fields; nothing is written to Drift until OB-07 Finish.
class OnboardingDraft {
  const OnboardingDraft({
    this.city,
    this.admin1,
    this.countryCode,
    this.postcode,
    this.lat,
    this.lon,
    this.timezone,
    this.spaceType,
    this.areaSqFt,
    this.sun,
    this.sunUnsure = false,
    this.rainExposed,
    this.goals = const {},
    this.goalOtherText,
    this.experience,
    this.availability = const [0, 0, 0, 0, 0, 0, 0],
    this.heardFrom,
    this.heardOtherText,
  });

  // OB-02 Location (#61).
  final String? city;
  final String? admin1;
  final String? countryCode;
  final String? postcode;

  /// Rounded to 2 decimals.
  final double? lat;
  final double? lon;
  final String? timezone;

  // OB-03 Space (#66).
  final SpaceType? spaceType;
  final int? areaSqFt;
  final SunLevel? sun;
  final bool sunUnsure;
  final bool? rainExposed;

  // OB-04 Goals (#66).
  final Set<Goal> goals;
  final String? goalOtherText;
  final Experience? experience;

  /// OB-05 (#67): 7 bitmasks, Mon..Sun; bit i = block i. All zero until
  /// the user paints the grid.
  final List<int> availability;

  // OB-06 Heard about us (#56).
  final HeardFrom? heardFrom;
  final String? heardOtherText;

  /// A copy with the given fields replaced. Nullable fields can be cleared
  /// by passing null explicitly.
  OnboardingDraft copyWith({
    Object? city = _unset,
    Object? admin1 = _unset,
    Object? countryCode = _unset,
    Object? postcode = _unset,
    Object? lat = _unset,
    Object? lon = _unset,
    Object? timezone = _unset,
    Object? spaceType = _unset,
    Object? areaSqFt = _unset,
    Object? sun = _unset,
    bool? sunUnsure,
    Object? rainExposed = _unset,
    Set<Goal>? goals,
    Object? goalOtherText = _unset,
    Object? experience = _unset,
    List<int>? availability,
    Object? heardFrom = _unset,
    Object? heardOtherText = _unset,
  }) {
    T? pick<T>(Object? value, T? current) =>
        identical(value, _unset) ? current : value as T?;
    return OnboardingDraft(
      city: pick(city, this.city),
      admin1: pick(admin1, this.admin1),
      countryCode: pick(countryCode, this.countryCode),
      postcode: pick(postcode, this.postcode),
      lat: pick(lat, this.lat),
      lon: pick(lon, this.lon),
      timezone: pick(timezone, this.timezone),
      spaceType: pick(spaceType, this.spaceType),
      areaSqFt: pick(areaSqFt, this.areaSqFt),
      sun: pick(sun, this.sun),
      sunUnsure: sunUnsure ?? this.sunUnsure,
      rainExposed: pick(rainExposed, this.rainExposed),
      goals: goals ?? this.goals,
      goalOtherText: pick(goalOtherText, this.goalOtherText),
      experience: pick(experience, this.experience),
      availability: availability ?? this.availability,
      heardFrom: pick(heardFrom, this.heardFrom),
      heardOtherText: pick(heardOtherText, this.heardOtherText),
    );
  }
}
