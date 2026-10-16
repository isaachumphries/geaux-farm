import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../recommendations/application/clock_provider.dart';
import '../data/default_profile.dart';
import '../data/profile_writer.dart';
import '../domain/user_profile.dart';
import 'onboarding_routes.dart';

/// Stand-in for an onboarding step whose screen is not built yet (#60–#69).
/// Continue moves to the next step, so the flow can be walked end to end.
/// On the last step it saves [defaultUserProfile] and [defaultSpace] as
/// onboarded, and the router's redirect lets Home open. Each step's issue
/// replaces its stand-in.
class OnboardingPlaceholder extends ConsumerStatefulWidget {
  const OnboardingPlaceholder({
    super.key,
    required this.title,
    required this.route,
  });

  final String title;
  final String route;

  @override
  ConsumerState<OnboardingPlaceholder> createState() =>
      _OnboardingPlaceholderState();
}

class _OnboardingPlaceholderState extends ConsumerState<OnboardingPlaceholder> {
  bool _saving = false;

  String? get _next {
    final i = OnboardingRoutes.ordered.indexOf(widget.route);
    return i >= 0 && i < OnboardingRoutes.ordered.length - 1
        ? OnboardingRoutes.ordered[i + 1]
        : null;
  }

  Future<void> _continue() async {
    final next = _next;
    if (next != null) {
      context.push(next);
      return;
    }
    setState(() => _saving = true);
    final d = defaultUserProfile;
    await ref
        .read(profileWriterProvider)
        .save(
          UserProfile(
            city: d.city,
            admin1: d.admin1,
            countryCode: d.countryCode,
            postcode: d.postcode,
            lat: d.lat,
            lon: d.lon,
            timezone: d.timezone,
            goals: d.goals,
            experience: d.experience,
            availability: d.availability,
            onboardingCompletedAt: ref.read(clockProvider)(),
          ),
          defaultSpace,
        );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                _next == null
                    ? 'This step is not built yet. Finish uses the default '
                          'Baton Rouge profile.'
                    : 'This step is not built yet.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.soil600),
              ),
              const Spacer(),
              GeauxButton(
                label: _next == null ? 'Finish' : 'Continue',
                onPressed: _saving ? null : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
