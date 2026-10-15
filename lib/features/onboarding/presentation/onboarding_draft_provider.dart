import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/onboarding_draft.dart';

/// Holds the onboarding answers in memory only. A killed app starts again
/// at Welcome with an empty draft (plan/02 § Persistence). Each step issue
/// adds its own setters here.
class OnboardingDraftNotifier extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  /// Back to an empty draft.
  void reset() => state = const OnboardingDraft();
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, OnboardingDraft>(
      OnboardingDraftNotifier.new,
    );
