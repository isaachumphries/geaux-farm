import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../climate/data/climate_provider.dart';
import '../../garden/domain/planting.dart';
import '../../onboarding/data/profile_providers.dart';
import '../../recommendations/application/clock_provider.dart';
import '../../recommendations/application/recommendations_provider.dart';
import '../../recommendations/domain/scored_plant.dart';
import '../../recommendations/domain/season_line.dart';
import '../../recommendations/presentation/widgets/plant_card.dart';
import '../application/first_plant_prompt_provider.dart';
import '../domain/home_copy.dart';

/// How many recommendations the first-run carousel shows (plan/01 HM-01).
const homeCarouselCount = 10;

/// Home before the first planting: HM-01 (first-plant carousel) and, after
/// "I'll pick later", HM-01b (one slim "Pick your first plant" card).
class HomeFirstRunScreen extends ConsumerStatefulWidget {
  const HomeFirstRunScreen({super.key});

  @override
  ConsumerState<HomeFirstRunScreen> createState() => _HomeFirstRunState();
}

class _HomeFirstRunState extends ConsumerState<HomeFirstRunScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Home is the only tab built so far; tapping it again scrolls to the
  /// top. Garden, Care, and Community open once the router (#41) lands.
  void _onTab(int index) {
    if (index == 0 && _scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dismissed = ref.watch(firstPlantPromptDismissedProvider);
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          children: [
            const Padding(padding: inset, child: _Header()),
            const SizedBox(height: AppSpacing.lg),
            const Padding(padding: inset, child: _SeasonBanner()),
            if (dismissed) ...[
              const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
              const Padding(padding: inset, child: _SlimPromptCard()),
            ] else ...[
              // The header row is as tall as the 48 px "See all" target,
              // so the visible gap to the title is 18.
              const SizedBox(height: AppSpacing.sm),
              const Padding(padding: inset, child: _PromptHeader()),
              const SizedBox(height: AppSpacing.md),
              const _Carousel(),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: GeauxButton(
                  label: "I'll pick later",
                  variant: GeauxButtonVariant.text,
                  onPressed: () => ref
                      .read(firstPlantPromptDismissedProvider.notifier)
                      .dismiss(),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: GeauxBottomNav(
        currentIndex: 0,
        onTap: _onTab,
        items: const [
          GeauxNavItem(icon: Symbols.home_rounded, label: 'Home'),
          GeauxNavItem(icon: Symbols.yard_rounded, label: 'Garden'),
          GeauxNavItem(icon: Symbols.event_available_rounded, label: 'Care'),
          GeauxNavItem(icon: Symbols.groups_rounded, label: 'Community'),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final now = ref.watch(clockProvider)();
    final city = ref.watch(userProfileProvider).value?.city;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                homeDateLine(today),
                style: AppText.overline.copyWith(color: AppColors.soil600),
              ),
              // One line at any width: on narrow phones the greeting
              // shrinks to fit beside the city pill instead of wrapping.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  greetingFor(now),
                  maxLines: 1,
                  style: AppText.h1.copyWith(color: AppColors.soil900),
                ),
              ),
            ],
          ),
        ),
        // No gap before the pill: the Figma butts "Good morning!" against
        // it, and at 390 wide any gap wraps the greeting.
        if (city != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _pillMaxWidth),
            child: _LocationPill(city: city),
          ),
        const SizedBox(width: AppSpacing.sm + 2),
        const _GearButton(),
      ],
    );
  }
}

/// Long city names ellipsize so the greeting keeps room to wrap.
const double _pillMaxWidth = 160;

/// White ledge capsule: 2 px stone border with a stone ledge underneath.
class _LedgeCapsule extends StatelessWidget {
  const _LedgeCapsule({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppRadii.pill));
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.stone200,
        borderRadius: radius,
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppBorders.ledge - AppBorders.width,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: radius,
            border: Border.all(
              color: AppColors.stone200,
              width: AppBorders.width,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    return _LedgeCapsule(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 6, AppSpacing.md, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Symbols.location_on_rounded,
            size: AppIconSize.md,
            color: AppColors.leaf700,
            fill: 1,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodySm.copyWith(
                color: AppColors.soil900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens settings once `/settings` exists (#41); inert until then.
class _GearButton extends StatelessWidget {
  const _GearButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Settings',
      button: true,
      child: const SizedBox.square(
        dimension: AppSpacing.minTouchTarget,
        child: _LedgeCapsule(
          padding: EdgeInsets.zero,
          child: Center(
            child: Icon(
              Symbols.settings_rounded,
              size: AppIconSize.lg,
              color: AppColors.soil900,
              fill: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// The banner's leaf tile is 48 across in the HM-01 export.
const double _seasonTileSize = 48;

class _SeasonBanner extends ConsumerWidget {
  const _SeasonBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final climate = ref.watch(climateProvider).value;
    final today = ref.watch(todayProvider);
    final line = profile == null || climate == null
        ? null
        : seasonLine(
            city: profile.city,
            latitude: profile.lat,
            months: climate.months,
            today: today,
          );
    return GeauxCard(
      color: AppColors.leaf700,
      borderColor: null,
      ledgeColor: AppColors.leafLedge,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.leaf500,
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: const SizedBox.square(
              dimension: _seasonTileSize,
              child: Icon(
                Symbols.eco_rounded,
                size: AppIconSize.xl,
                color: AppColors.white,
                fill: 1,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg - 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This season'.toUpperCase(),
                  style: AppText.overline.copyWith(
                    color: AppColors.seasonOverline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (line != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    line,
                    style: AppText.body.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Pick your first plant" with "See all" and the space subline. "See all"
/// opens RC-01 once it and the router (#41, #71) exist.
class _PromptHeader extends ConsumerWidget {
  const _PromptHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(userProfileProvider).value?.city;
    final space = ref.watch(primarySpaceProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pick your first plant',
                style: AppText.h2.copyWith(color: AppColors.soil900),
              ),
            ),
            const GeauxButton(
              label: 'See all',
              variant: GeauxButtonVariant.text,
              onPressed: null,
            ),
          ],
        ),
        if (city != null && space != null)
          Text(
            topMatchesLine(space.type, city),
            style: AppText.bodySm.copyWith(color: AppColors.soil600),
          ),
      ],
    );
  }
}

/// First [homeCarouselCount] recommendations as compact cards. Loading
/// while the catalog or the climate is pending, and while the climate
/// build has failed (#26: consumers keep loading until a build succeeds).
class _Carousel extends ConsumerWidget {
  const _Carousel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final climate = ref.watch(climateProvider);
    final recs = ref.watch(recommendationsProvider);
    final space = ref.watch(primarySpaceProvider).value;
    if (climate is! AsyncData || space == null) return const _CarouselLoading();
    return switch (recs) {
      AsyncData(:final value) => _CarouselRow(
        plants: value.take(homeCarouselCount).toList(),
        setup: defaultGrowSetup(space.type),
      ),
      AsyncError() => const _CarouselMessage("Couldn't load plants."),
      _ => const _CarouselLoading(),
    };
  }
}

class _CarouselRow extends StatelessWidget {
  const _CarouselRow({required this.plants, required this.setup});

  final List<ScoredPlant> plants;
  final GrowSetup setup;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, s) in plants.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            // Card tap opens PD-01 once it and the router exist (#74, #41).
            PlantCard(
              key: ValueKey(s.plant.id),
              plant: s,
              state: PlantCardState.of(s.compatibility, setup),
            ),
          ],
        ],
      ),
    );
  }
}

/// Height the carousel slot keeps while it has no cards.
const double _carouselSlotHeight = 240;

class _CarouselLoading extends StatelessWidget {
  const _CarouselLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: _carouselSlotHeight,
      child: Center(child: CircularProgressIndicator(color: AppColors.leaf500)),
    );
  }
}

class _CarouselMessage extends StatelessWidget {
  const _CarouselMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _carouselSlotHeight,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppText.bodySm.copyWith(color: AppColors.soil600),
        ),
      ),
    );
  }
}

/// HM-01b: the carousel collapsed into one card. Opens RC-01 once it and
/// the router exist (#71, #41).
class _SlimPromptCard extends ConsumerWidget {
  const _SlimPromptCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(primarySpaceProvider).value;
    final recs = ref.watch(recommendationsProvider).value;
    final line = space == null || recs == null
        ? null
        : slimCardLine([for (final s in recs) s.plant.commonName], space.type);
    return GeauxCard(
      child: Row(
        children: [
          const _SlimArt(),
          const SizedBox(width: AppSpacing.lg - 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick your first plant',
                  style: AppText.cardTitle.copyWith(color: AppColors.soil900),
                ),
                if (line != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    line,
                    style: AppText.bodySm.copyWith(color: AppColors.soil600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Symbols.chevron_right_rounded,
            size: AppIconSize.xl,
            color: AppColors.soil600,
          ),
        ],
      ),
    );
  }
}

class _SlimArt extends StatelessWidget {
  const _SlimArt();

  // HM-01b export (2x, halved): the tile is 64 across and its leaf glyph
  // about 24 wide, which a 34 Material Symbol draws.
  static const double _size = 64;
  static const double _iconSize = 34;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: AppColors.leaf100,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.artHalo,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Symbols.eco_rounded,
            size: _iconSize,
            color: AppColors.leaf500,
            fill: 1,
          ),
        ),
      ),
    );
  }
}
