import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import 'onboarding_routes.dart';

/// OB-01 Welcome: the first screen of a fresh install. No back button and
/// no StepProgress.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const _WelcomeArt(),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Grow something at home.',
                textAlign: TextAlign.center,
                style: AppText.display.copyWith(color: AppColors.soil900),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Tell us about your space and we'll match you with plants "
                'that thrive where you live.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.soil600),
              ),
              const Spacer(),
              GeauxButton(
                label: 'Get started',
                onPressed: () => context.push(OnboardingRoutes.location),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Takes about 2 minutes. No account needed.',
                textAlign: TextAlign.center,
                style: AppText.bodySm.copyWith(color: AppColors.soil600),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three ledge tiles (plant, sprout, water) in the OB-01 tile tokens.
class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt();

  static const double _tile = 72;
  static const double _icon = 36;

  @override
  Widget build(BuildContext context) {
    Widget tile(Color fill, Color ledge, IconData icon, Color iconColor) =>
        SizedBox.square(
          dimension: _tile,
          child: GeauxCard(
            padding: EdgeInsets.zero,
            color: fill,
            borderColor: null,
            ledgeColor: ledge,
            child: Center(
              child: Icon(icon, size: _icon, color: iconColor, fill: 1),
            ),
          ),
        );
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          tile(
            AppColors.tileSoil,
            AppColors.tileSoilLedge,
            Symbols.potted_plant_rounded,
            AppColors.tileSoilLedge,
          ),
          const SizedBox(width: AppSpacing.md),
          tile(
            AppColors.leaf700,
            AppColors.leafLedge,
            Symbols.eco_rounded,
            AppColors.white,
          ),
          const SizedBox(width: AppSpacing.md),
          tile(
            AppColors.tileSky,
            AppColors.tileSkyLedge,
            Symbols.water_drop_rounded,
            AppColors.tileSkyLedge,
          ),
        ],
      ),
    );
  }
}
