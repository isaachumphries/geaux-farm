import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../application/my_guides_provider.dart';
import '../application/starred_guides_provider.dart';
import '../data/auth_providers.dart';
import '../data/guide_repository_provider.dart';
import '../domain/guide.dart';
import '../domain/guide_repository.dart';
import 'sign_in_sheet.dart';
import 'widgets/guide_card.dart';
import 'widgets/guide_card_skeleton.dart';

/// CM-05 empty-state copy (agreed on #64; plan/07 § My profile).
const myGuidesEmptyCopy =
    'No guides yet. Guides you write show up here, drafts included.';
const starredEmptyCopy = 'No starred guides yet. Star a guide to keep it here.';

/// The label over a guide that isn't published: plan/07 § Moderation's
/// author-facing text for a hidden guide, and "Draft" for a draft.
String? ownGuideStatusLabel(GuideStatus status) => switch (status) {
  GuideStatus.draft => 'Draft',
  GuideStatus.hidden => 'Hidden pending review',
  GuideStatus.published => null,
};

enum _ProfileList { mine, starred }

/// CM-05 My profile: the signed-in user's guides, drafts and hidden ones
/// included, and the guides they starred (plan/01 § CM-05). A signed-out
/// user is asked to sign in first; closing CM-04 leaves the screen.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  var _list = _ProfileList.mine;

  /// True once the user is signed in; until then no list is read.
  var _signedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requireSignIn());
  }

  Future<void> _requireSignIn() async {
    var signedIn = false;
    await requireSignIn(
      context,
      ref,
      reason: SignInAction.account,
      action: () => signedIn = true,
    );
    if (!mounted) return;
    if (signedIn) {
      setState(() => _signedIn = true);
    } else {
      _leave();
    }
  }

  void _leave() => context.canPop() ? context.pop() : context.go('/community');

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (!_signedIn) {
      // CM-04 is over this screen, or about to be.
      body = ref.watch(authStateProvider).isLoading
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    } else {
      body = switch (_list) {
        _ProfileList.mine => const _MyGuidesList(),
        _ProfileList.starred => const _StarredList(),
      };
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              child: GeauxTopBar(
                title: 'My profile',
                leading: GeauxCircleButton(
                  icon: Symbols.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: _leave,
                ),
              ),
            ),
            if (_signedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: GeauxSegmentedChoice<_ProfileList>(
                  options: const [
                    (_ProfileList.mine, 'My guides'),
                    (_ProfileList.starred, 'Starred'),
                  ],
                  selected: _list,
                  onSelected: (list) => setState(() => _list = list),
                ),
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

const _listPadding = EdgeInsets.fromLTRB(
  AppSpacing.screenPadding,
  AppSpacing.xs,
  AppSpacing.screenPadding,
  AppSpacing.xl,
);

/// CM-01's error state: the same copy and Retry.
Widget _loadFailed(VoidCallback onRetry) => GeauxEmptyState(
  icon: Symbols.cloud_off_rounded,
  message: "Couldn't load guides.",
  action: GeauxButton(
    label: 'Retry',
    variant: GeauxButtonVariant.text,
    onPressed: onRetry,
  ),
);

class _MyGuidesList extends ConsumerWidget {
  const _MyGuidesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myGuidesProvider);
    final guides = mine.value;
    if (guides == null) {
      return mine.hasError
          ? _loadFailed(() => ref.invalidate(myGuidesProvider))
          : const GuideCardSkeletonList(padding: _listPadding);
    }
    if (guides.isEmpty) {
      return const GeauxEmptyState(
        icon: Symbols.menu_book_rounded,
        message: myGuidesEmptyCopy,
      );
    }
    return _GuideList(
      itemCount: guides.length,
      itemBuilder: (context, i) {
        final (:guide, :status) = guides[i];
        final label = ownGuideStatusLabel(status);
        final card = _Card(
          guide: guide,
          onTap: () async {
            if (status == GuideStatus.draft) {
              await context.push('/community/editor/${guide.id}');
              // A save in the editor changes the row and its order.
              ref.invalidate(myGuidesProvider);
            } else {
              await context.push('/community/guide/${guide.id}');
            }
          },
        );
        if (label == null) return card;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusLabel(label: label, hidden: status == GuideStatus.hidden),
            const SizedBox(height: AppSpacing.xs),
            card,
          ],
        );
      },
    );
  }
}

class _StarredList extends ConsumerWidget {
  const _StarredList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starred = ref.watch(starredGuidesProvider);
    final guides = starred.value;
    if (guides == null) {
      return starred.hasError
          ? _loadFailed(() => ref.invalidate(starredGuidesProvider))
          : const GuideCardSkeletonList(padding: _listPadding);
    }
    if (guides.isEmpty) {
      return const GeauxEmptyState(
        icon: Symbols.star_rounded,
        message: starredEmptyCopy,
      );
    }
    return _GuideList(
      itemCount: guides.length,
      itemBuilder: (context, i) => _Card(
        guide: guides[i],
        onTap: () => context.push('/community/guide/${guides[i].id}'),
      ),
    );
  }
}

class _GuideList extends StatelessWidget {
  const _GuideList({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: _listPadding,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: itemBuilder,
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.guide, required this.onTap});

  final Guide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = guide.coverPath;
    return GuideCard(
      guide: guide,
      coverUrl: cover == null
          ? null
          : ref.watch(guideRepositoryProvider).coverUrl(cover),
      onTap: onTap,
    );
  }
}

/// "Draft" or "Hidden pending review" over an author's own card.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.label, required this.hidden});

  final String label;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          hidden ? Symbols.visibility_off_rounded : Symbols.edit_note_rounded,
          size: AppIconSize.sm,
          color: hidden ? AppColors.possible : AppColors.soil600,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppText.overline.copyWith(
            color: hidden ? AppColors.possible : AppColors.soil600,
          ),
        ),
      ],
    );
  }
}
