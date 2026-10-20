import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/data/profile_providers.dart';
import '../../onboarding/data/profile_writer.dart';

/// Whether the user tapped "I'll pick later" on HM-01, which collapses the
/// carousel into the HM-01b slim card. Read from
/// `user_profile.first_plant_prompt_dismissed` and written back on dismiss.
final firstPlantPromptDismissedProvider =
    NotifierProvider<FirstPlantPromptDismissed, bool>(
      FirstPlantPromptDismissed.new,
    );

class FirstPlantPromptDismissed extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(userProfileProvider).value?.firstPlantPromptDismissed ?? false;

  /// Collapses HM-01 to HM-01b at once, then stores the flag on the profile row.
  Future<void> dismiss() async {
    state = true;
    await ref.read(profileWriterProvider).markFirstPlantPromptDismissed();
  }
}
