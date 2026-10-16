/// Onboarding routes in flow order (plan/02 § Flow overview).
abstract final class OnboardingRoutes {
  static const welcome = '/onboarding/welcome';
  static const location = '/onboarding/location';
  static const climate = '/onboarding/climate';
  static const space = '/onboarding/space';
  static const goals = '/onboarding/goals';
  static const time = '/onboarding/time';
  static const source = '/onboarding/source';
  static const summary = '/onboarding/summary';

  static const ordered = [
    welcome,
    location,
    climate,
    space,
    goals,
    time,
    source,
    summary,
  ];

  /// The step before [route], or null for Welcome.
  static String? previous(String route) {
    final i = ordered.indexOf(route);
    return i > 0 ? ordered[i - 1] : null;
  }
}

/// StepProgress labels: Location, Space, Goals, Availability (Time) and
/// Heard about us (Source) are dots 1–5. Welcome, the climate reveal and
/// the summary have no dot.
const onboardingStepLabels = ['Location', 'Space', 'Goals', 'Time', 'Source'];
