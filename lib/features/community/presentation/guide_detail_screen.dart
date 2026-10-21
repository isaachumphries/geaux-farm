import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../recommendations/application/recommendations_provider.dart';
import '../../recommendations/domain/scored_plant.dart';
import '../application/growing_guides_provider.dart';
import '../application/guide_detail_provider.dart';
import '../application/guide_star_provider.dart';
import '../application/starred_guides_provider.dart';
import '../data/auth_providers.dart';
import '../data/guide_repository_provider.dart';
import '../domain/guide.dart';
import '../domain/guide_repository.dart';
import 'sign_in_sheet.dart';
import 'widgets/guide_detail_skeleton.dart';
import 'widgets/guide_hero.dart';
import 'widgets/guide_info_row.dart';
import 'widgets/guide_plants.dart';
import 'widgets/guide_sections.dart';
import 'widgets/stat_button.dart';

enum _MenuAction { report, edit, delete }

/// CM-02: one guide, top to bottom as plan/07 § Guide detail lists it, with
/// an optimistic Star and the sticky Grow this bar.
///
/// Grow this, Remix, Report and Delete belong to #49, #57, #60 and #50: each
/// is inert (the menu entry disabled) until its flow passes a callback.
class GuideDetailScreen extends ConsumerWidget {
  const GuideDetailScreen({
    super.key,
    required this.guideId,
    this.onGrow,
    this.onRemix,
    this.onReport,
    this.onDelete,
  });

  final String guideId;

  /// Starts Grow this (#49) for a guide the user is not growing yet.
  final VoidCallback? onGrow;

  /// Starts Remix (#57).
  final VoidCallback? onRemix;

  /// Opens the report sheet (#60).
  final VoidCallback? onReport;

  /// Deletes the user's own guide (#50).
  final VoidCallback? onDelete;

  /// Stars the guide, or unstars it when [starred] is false. Signed out, asks
  /// the user to sign in first and does it once they have.
  Future<void> _setStar(BuildContext context, WidgetRef ref, bool starred) {
    final messenger = ScaffoldMessenger.of(context);
    return requireSignIn(
      context,
      ref,
      reason: SignInAction.star,
      action: () async {
        // The sign-in sheet can outlive the screen behind it.
        if (!context.mounted) return;
        try {
          await ref
              .read(guideStarProvider(guideId).notifier)
              .setStarred(starred);
        } on Object {
          messenger.showSnackBar(
            const SnackBar(content: Text("Couldn't update your star.")),
          );
        }
      },
    );
  }

  void _retry(WidgetRef ref) {
    ref.invalidate(guideDetailProvider(guideId));
    ref.invalidate(starredGuideIdsProvider);
    ref.invalidate(guideStarProvider(guideId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(guideDetailProvider(guideId));
    final star = ref.watch(guideStarProvider(guideId));
    final guide = detail.value;
    final starState = star.value;
    final loaded = guide != null && starState != null;

    final Widget body;
    if (loaded) {
      body = _Loaded(
        guide: guide,
        star: starState,
        onStar: () => _setStar(context, ref, !starState.starred),
        onGrow: onGrow,
        onRemix: onRemix,
      );
    } else if (detail.hasError || star.hasError) {
      final error = detail.error ?? star.error;
      body = SafeArea(
        child: error is GuideNotFoundException
            ? const GeauxEmptyState(
                icon: Symbols.menu_book_rounded,
                message: "This guide isn't available.",
              )
            : GeauxEmptyState(
                icon: Symbols.cloud_off_rounded,
                message: "Couldn't load this guide.",
                action: GeauxButton(
                  label: 'Retry',
                  variant: GeauxButtonVariant.text,
                  onPressed: () => _retry(ref),
                ),
              ),
      );
    } else {
      body = const GuideDetailSkeleton();
    }

    final isOwn =
        guide != null &&
        ref.watch(authStateProvider).value?.id == guide.authorId;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          body,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              menu: !loaded
                  ? null
                  : _OverflowMenu(
                      own: isOwn,
                      onSelected: (action) => switch (action) {
                        _MenuAction.report => onReport?.call(),
                        _MenuAction.edit => context.push(
                          '/community/editor/${guide.id}',
                        ),
                        _MenuAction.delete => onDelete?.call(),
                      },
                      reportEnabled: onReport != null,
                      deleteEnabled: onDelete != null,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({
    required this.guide,
    required this.star,
    required this.onStar,
    required this.onGrow,
    required this.onRemix,
  });

  final Guide guide;
  final GuideStarState star;
  final VoidCallback onStar;
  final VoidCallback? onGrow;
  final VoidCallback? onRemix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(guideRepositoryProvider);
    final cover = guide.coverPath;
    final projectId = ref.watch(growingGuideProjectsProvider).value?[guide.id];
    final VoidCallback? grow = projectId == null
        ? onGrow
        : () => context.push('/garden/project/$projectId');

    final scored = {
      for (final s
          in ref.watch(recommendationsProvider).value ?? const <ScoredPlant>[])
        s.plant.id: s,
    };
    final plants = [
      for (final id in guide.plantIds)
        if (scored[id] != null) scored[id]!,
    ];
    final source = ref.watch(remixSourceProvider(guide.id)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: guideHeroHeight,
                  child: GuideHero(
                    url: cover == null ? null : repository.coverUrl(cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: guideHeroHeight - AppRadii.sheet,
                  ),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.cream50,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadii.sheet),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.xl,
                        children: [
                          _Header(guide: guide),
                          _Stats(
                            guide: guide,
                            star: star,
                            onStar: onStar,
                            onGrow: grow,
                            onRemix: onRemix,
                          ),
                          GuideInfoRow(guide: guide),
                          if (guide.summary.isNotEmpty)
                            Text(
                              guide.summary,
                              style: AppText.body.copyWith(
                                color: AppColors.soil600,
                              ),
                            ),
                          if (guide.materials.isNotEmpty)
                            GuideSection(
                              title: 'Materials',
                              child: GuideMaterials(materials: guide.materials),
                            ),
                          if (guide.steps.isNotEmpty)
                            GuideSection(
                              title: 'Steps',
                              child: GuideSteps(steps: guide.steps),
                            ),
                          if (plants.isNotEmpty)
                            GuideSection(
                              title: 'Plants in this guide',
                              child: GuidePlants(
                                plants: plants,
                                onOpen: (id) => context.push('/plants/$id'),
                              ),
                            ),
                          if (source != null) _RemixedFrom(source: source),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _GrowBar(growing: projectId != null, onPressed: grow),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.guide});

  final Guide guide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Text(guide.title, style: AppText.h1.copyWith(color: AppColors.soil900)),
        Row(
          spacing: AppSpacing.md,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.tileSoil,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.person_rounded,
                size: AppIconSize.md,
                color: AppColors.tileSoilLedge,
                fill: 1,
              ),
            ),
            Expanded(
              child: Text(
                '@${guide.authorUsername}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(
                  color: AppColors.soil900,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({
    required this.guide,
    required this.star,
    required this.onStar,
    required this.onGrow,
    required this.onRemix,
  });

  final Guide guide;
  final GuideStarState star;
  final VoidCallback onStar;
  final VoidCallback? onGrow;
  final VoidCallback? onRemix;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm + 2,
      children: [
        StatButton(
          icon: Icon(
            Symbols.star_rounded,
            size: AppIconSize.md,
            color: star.starred ? AppColors.geauxGold : AppColors.soil600,
            fill: star.starred ? 1 : 0,
          ),
          label: star.starred ? 'Starred' : 'Star',
          count: star.count,
          selected: star.starred,
          onTap: onStar,
        ),
        StatButton(
          icon: const _GrowMark(),
          label: 'Grow this',
          count: guide.growCount,
          countSuffix: ' growing',
          onTap: onGrow,
        ),
        StatButton(
          icon: const Icon(
            Symbols.call_split_rounded,
            size: AppIconSize.md,
            color: AppColors.soil900,
          ),
          label: 'Remix',
          count: guide.remixCount,
          onTap: onRemix,
        ),
      ],
    );
  }
}

/// The dark flower tile that marks Grow this.
class _GrowMark extends StatelessWidget {
  const _GrowMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppIconSize.md,
      height: AppIconSize.md,
      decoration: BoxDecoration(
        color: AppColors.soil600,
        borderRadius: BorderRadius.circular(AppRadii.chip - 2),
      ),
      child: const Icon(
        Symbols.local_florist_rounded,
        size: AppIconSize.xs,
        color: AppColors.white,
        fill: 1,
      ),
    );
  }
}

/// "Remixed from {title} by @{user}", a link to the original.
class _RemixedFrom extends StatelessWidget {
  const _RemixedFrom({required this.source});

  final Guide source;

  @override
  Widget build(BuildContext context) {
    final base = AppText.bodySm.copyWith(color: AppColors.soil600);
    return Semantics(
      link: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/community/guide/${source.id}'),
        child: Row(
          spacing: AppSpacing.sm,
          children: [
            const Icon(
              Symbols.shuffle_rounded,
              size: AppIconSize.md,
              color: AppColors.soil600,
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: base,
                  children: [
                    const TextSpan(text: 'Remixed from '),
                    TextSpan(
                      text: source.title,
                      style: base.copyWith(color: AppColors.tileSkyLedge),
                    ),
                    TextSpan(text: ' by @${source.authorUsername}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sticky bar: "Grow this guide", or "Growing · Open project" once the
/// guide has a project.
class _GrowBar extends StatelessWidget {
  const _GrowBar({required this.growing, required this.onPressed});

  final bool growing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.stone200)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.xxl,
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
          ),
          child: growing
              ? GeauxButton(
                  label: 'Growing · Open project',
                  icon: Symbols.check_rounded,
                  variant: GeauxButtonVariant.secondary,
                  onPressed: onPressed,
                )
              : GeauxButton(
                  label: 'Grow this guide',
                  icon: Symbols.local_florist_rounded,
                  onPressed: onPressed,
                ),
        ),
      ),
    );
  }
}

/// Back on the left, the overflow menu on the right, over the hero.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.menu});

  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _RoundButton(
              label: 'Back',
              icon: Symbols.arrow_back_ios_new_rounded,
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/community'),
            ),
            ?menu,
          ],
        ),
      ),
    );
  }
}

/// A 48 pt white ledge circle with one icon.
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: AppSpacing.minTouchTarget,
          child: LedgeCapsule(
            child: Center(
              child: Icon(
                icon,
                size: AppIconSize.lg,
                color: AppColors.soil900,
                fill: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({
    required this.own,
    required this.onSelected,
    required this.reportEnabled,
    required this.deleteEnabled,
  });

  final bool own;
  final ValueChanged<_MenuAction> onSelected;
  final bool reportEnabled;
  final bool deleteEnabled;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      tooltip: 'More',
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        side: AppBorders.cardSide,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => own
          ? [
              const PopupMenuItem(value: _MenuAction.edit, child: Text('Edit')),
              PopupMenuItem(
                value: _MenuAction.delete,
                enabled: deleteEnabled,
                child: const Text('Delete'),
              ),
            ]
          : [
              PopupMenuItem(
                value: _MenuAction.report,
                enabled: reportEnabled,
                child: const Text('Report'),
              ),
            ],
      child: const IgnorePointer(
        child: SizedBox.square(
          dimension: AppSpacing.minTouchTarget,
          child: LedgeCapsule(
            child: Center(
              child: Icon(
                Symbols.more_horiz_rounded,
                size: AppIconSize.lg,
                weight: 700,
                color: AppColors.soil900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
