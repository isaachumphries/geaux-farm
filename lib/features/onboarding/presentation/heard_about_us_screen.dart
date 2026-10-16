import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../domain/user_profile.dart';
import 'goals_step_screen.dart' show otherTextMaxLength;
import 'onboarding_draft_provider.dart';
import 'onboarding_routes.dart';
import 'onboarding_scaffold.dart';

/// Options in plan/02 order.
const _sources = [
  (HeardFrom.friendFamily, 'Friend or family'),
  (HeardFrom.instagram, 'Instagram'),
  (HeardFrom.tiktok, 'TikTok'),
  (HeardFrom.appStore, 'App Store / Google Play'),
  (HeardFrom.lsuCampus, 'LSU / campus'),
  (HeardFrom.farmersMarket, 'Farmers market'),
  (HeardFrom.other, 'Other'),
];

/// OB-06 Heard about us: one optional, anonymous question. Step dot 5.
/// The answer is sent at OB-07 Finish, never from here.
class HeardAboutUsScreen extends ConsumerStatefulWidget {
  const HeardAboutUsScreen({super.key});

  @override
  ConsumerState<HeardAboutUsScreen> createState() => _HeardAboutUsState();
}

class _HeardAboutUsState extends ConsumerState<HeardAboutUsScreen> {
  late final TextEditingController _other;

  @override
  void initState() {
    super.initState();
    _other = TextEditingController(
      text: ref.read(onboardingDraftProvider).heardOtherText,
    );
  }

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _skip() {
    ref.read(onboardingDraftProvider.notifier).setHeardFrom(null);
    context.push(OnboardingRoutes.summary);
  }

  @override
  Widget build(BuildContext context) {
    final heardFrom = ref.watch(
      onboardingDraftProvider.select((d) => d.heardFrom),
    );
    final notifier = ref.read(onboardingDraftProvider.notifier);
    return OnboardingScaffold(
      route: OnboardingRoutes.source,
      step: 5,
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GeauxButton(
            label: 'Continue',
            onPressed: heardFrom == null
                ? null
                : () => context.push(OnboardingRoutes.summary),
          ),
          const SizedBox(height: AppSpacing.sm),
          GeauxButton(
            label: 'Skip',
            variant: GeauxButtonVariant.text,
            onPressed: _skip,
          ),
        ],
      ),
      child: ListView(
        children: [
          Text(
            'How did you hear about Geaux Farm?',
            style: AppText.h1.copyWith(color: AppColors.soil900),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (source, label) in _sources) ...[
            GeauxSelectCard(
              title: label,
              selected: heardFrom == source,
              onTap: () {
                // Leaving Other drops its text in the draft; match it here.
                if (source != HeardFrom.other) _other.clear();
                notifier.setHeardFrom(source);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (heardFrom == HeardFrom.other)
            GeauxTextField(
              controller: _other,
              maxLength: otherTextMaxLength,
              onChanged: notifier.setHeardOtherText,
            ),
        ],
      ),
    );
  }
}
