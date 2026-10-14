import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the user tapped "I'll pick later" on HM-01, which collapses the
/// carousel into the HM-01b slim card. Held in memory until Drift (#43)
/// stores it as `user_profile.first_plant_prompt_dismissed`.
final firstPlantPromptDismissedProvider =
    NotifierProvider<FirstPlantPromptDismissed, bool>(
      FirstPlantPromptDismissed.new,
    );

class FirstPlantPromptDismissed extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;
}
