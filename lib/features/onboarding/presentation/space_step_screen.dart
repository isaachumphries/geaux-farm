import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../domain/space.dart';
import '../domain/space_rules.dart';
import 'onboarding_draft_provider.dart';
import 'onboarding_routes.dart';
import 'onboarding_scaffold.dart';

/// Space type options in plan/02 order: title, subtitle, icon.
const _spaceOptions = [
  (
    SpaceType.windowsill,
    'Windowsill / indoors',
    'A sunny window or indoor shelf',
    Symbols.window_rounded,
  ),
  (
    SpaceType.balcony,
    'Balcony or patio',
    'Pots and containers outside',
    Symbols.balcony_rounded,
  ),
  (
    SpaceType.smallYard,
    'Small yard bed',
    'Under 50 sq ft of ground',
    Symbols.yard_rounded,
  ),
  (
    SpaceType.largeYard,
    'Large yard',
    '50+ sq ft of ground',
    Symbols.grass_rounded,
  ),
  (
    SpaceType.communityPlot,
    'Community plot',
    'A shared garden bed',
    Symbols.diversity_3_rounded,
  ),
];

/// Sun options: title, subtitle, stored level, unsure flag, icon.
const _sunOptions = [
  ('Full sun', '6+ hours', SunLevel.full, false, Symbols.sunny_rounded),
  (
    'Partial',
    '3–6 hours',
    SunLevel.partial,
    false,
    Symbols.partly_cloudy_day_rounded,
  ),
  ('Shade', 'Under 3 hours', SunLevel.shade, false, Symbols.cloud_rounded),
  (
    'Not sure',
    "We'll assume partial — you can check later",
    SunLevel.partial,
    true,
    Symbols.help_rounded,
  ),
];

/// OB-03 Space: where the plants live, how much room, how much sun, and
/// (Balcony only) whether rain reaches them. Step dot 2.
class SpaceStepScreen extends ConsumerWidget {
  const SpaceStepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);
    final area = draft.areaSqFt;
    final complete = draft.spaceType != null && draft.sun != null;

    return OnboardingScaffold(
      route: OnboardingRoutes.space,
      step: 2,
      bottom: GeauxButton(
        label: 'Continue',
        onPressed: complete ? () => context.push(OnboardingRoutes.goals) : null,
      ),
      child: ListView(
        children: [
          Text(
            'Where will your plants live?',
            style: AppText.h1.copyWith(color: AppColors.soil900),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (type, title, subtitle, icon) in _spaceOptions) ...[
            GeauxSelectCard(
              title: title,
              subtitle: subtitle,
              icon: icon,
              selected: draft.spaceType == type,
              onTap: () => notifier.setSpaceType(type),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (draft.spaceType == SpaceType.balcony) ...[
            const SizedBox(height: AppSpacing.sm),
            _RainSwitch(
              value: draft.rainExposed ?? true,
              onChanged: notifier.setRainSwitch,
            ),
          ],
          if (area != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _AreaSlider(sqFt: area, onChanged: notifier.setAreaSqFt),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            'How much direct sun does it get?',
            style: AppText.cardTitle.copyWith(color: AppColors.soil900),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final (title, subtitle, sun, unsure, icon) in _sunOptions) ...[
            GeauxSelectCard(
              title: title,
              subtitle: subtitle,
              icon: icon,
              selected: draft.sun == sun && draft.sunUnsure == unsure,
              onTap: () => notifier.setSun(sun, unsure: unsure),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _AreaSlider extends StatelessWidget {
  const _AreaSlider({required this.sqFt, required this.onChanged});

  final int sqFt;
  final ValueChanged<int> onChanged;

  /// The stop at or just below [sqFt], so an off-stop value still shows.
  int get _index {
    var i = 0;
    while (i < areaStops.length - 1 && areaStops[i + 1] <= sqFt) {
      i++;
    }
    return i;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About how much room?',
          style: AppText.cardTitle.copyWith(color: AppColors.soil900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '≈ $sqFt sq ft · ${areaComparisonLabel(sqFt)}',
          style: AppText.body.copyWith(
            color: AppColors.leaf700,
            fontWeight: FontWeight.w700,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.leaf500,
            inactiveTrackColor: AppColors.stone200,
            thumbColor: AppColors.leaf700,
            overlayColor: AppColors.leaf100,
            activeTickMarkColor: AppColors.leaf100,
            inactiveTickMarkColor: AppColors.soil600,
            trackHeight: 8,
          ),
          child: Slider(
            value: _index.toDouble(),
            max: (areaStops.length - 1).toDouble(),
            divisions: areaStops.length - 1,
            semanticFormatterCallback: (v) => '${areaStops[v.round()]} sq ft',
            onChanged: (v) => onChanged(areaStops[v.round()]),
          ),
        ),
      ],
    );
  }
}

class _RainSwitch extends StatelessWidget {
  const _RainSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Symbols.rainy_rounded,
            color: AppColors.tileSkyLedge,
            fill: 1,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Rain reaches my plants',
              style: AppText.body.copyWith(
                color: AppColors.soil900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.leaf500,
          ),
        ],
      ),
    );
  }
}
