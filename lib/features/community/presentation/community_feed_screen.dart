import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../application/community_feed_provider.dart';
import '../data/guide_repository_provider.dart';
import '../domain/guide_feed_query.dart';
import 'widgets/feed_filters.dart';
import 'widgets/guide_card.dart';
import 'widgets/guide_card_skeleton.dart';
import 'widgets/ledge_capsule.dart';

/// How long typing pauses before the search runs.
const searchDebounce = Duration(milliseconds: 300);

/// How close to the end of the list (in logical pixels) the next page starts
/// loading.
const _loadMoreExtent = 400.0;

/// The tabs, in order. Trending is a cut candidate (plan/10 § Cut order):
/// delete its entry here.
const _tabs = <(GuideSort, String, IconData)>[
  (GuideSort.top, 'Top', Symbols.emoji_events_rounded),
  (GuideSort.trending, 'Trending', Symbols.local_fire_department_rounded),
  (GuideSort.newest, 'New', Symbols.fiber_new_rounded),
];

/// CM-01: the community feed. Tabs, filter chips, search, and an endless
/// list of guides.
class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  final _scroll = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  var _query = const GuideFeedQuery();
  var _searching = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll
      ..removeListener(_maybeLoadMore)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scroll.position.extentAfter >= _loadMoreExtent) return;
    // After a failed page only the footer's Retry asks again, so scrolling
    // does not hammer a server that is down.
    final feed = ref.read(communityFeedProvider(_query)).value;
    if (feed == null || feed.loadMoreError != null) return;
    ref.read(communityFeedProvider(_query).notifier).loadMore();
  }

  /// A new sort or filter is a new feed: back to the top of page 1.
  void _setQuery(GuideFeedQuery next) {
    if (next == _query) return;
    setState(() => _query = next);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    // The request trims anyway; trimming here too keeps "kale" and "kale "
    // one feed instead of a second fetch and a jump back to the top.
    _debounce = Timer(searchDebounce, () {
      if (mounted) _setQuery(_query.copyWith(search: text.trim()));
    });
  }

  void _toggleSearch() {
    if (_searching) {
      _debounce?.cancel();
      _searchController.clear();
      _setQuery(_query.copyWith(search: ''));
    }
    setState(() => _searching = !_searching);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const _NewGuideButton(),
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
                0,
              ),
              child: _Header(searching: _searching, onSearch: _toggleSearch),
            ),
            if (_searching)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: GeauxTextField(
                  controller: _searchController,
                  autofocus: true,
                  hintText: 'Search guides',
                  prefixIcon: Symbols.search_rounded,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: _FeedTabs(
                selected: _query.sort,
                onSelected: (sort) => _setQuery(_query.withSort(sort)),
              ),
            ),
            const SizedBox(height: AppSpacing.md + AppSpacing.xs),
            FeedFilterRow(query: _query, onChanged: _setQuery),
            const SizedBox(height: AppSpacing.md + 2),
            Expanded(
              child: _FeedList(query: _query, controller: _scroll),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.searching, required this.onSearch});

  final bool searching;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Community',
            style: AppText.h1.copyWith(color: AppColors.soil900),
          ),
        ),
        _RoundButton(
          label: searching ? 'Close search' : 'Search guides',
          icon: searching ? Symbols.close_rounded : Symbols.search_rounded,
          onTap: onSearch,
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        _RoundButton(
          label: 'My profile',
          icon: Symbols.person_rounded,
          onTap: () => context.push('/community/me'),
        ),
      ],
    );
  }
}

/// A 48 pt white ledge circle with one icon (CM-01 header).
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

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

/// Darker edge under the selected tab (CM-01 export).
const _tabLedge = Color(0xFFD6D1C7);

/// The Top / Trending / New switch: a stone track with a white ledge pill
/// under the selected tab.
class _FeedTabs extends StatelessWidget {
  const _FeedTabs({required this.selected, required this.onSelected});

  final GuideSort selected;
  final ValueChanged<GuideSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.stone200,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            for (final (sort, label, icon) in _tabs)
              Expanded(
                child: _Tab(
                  label: label,
                  icon: icon,
                  active: sort == selected,
                  onTap: () => onSelected(sort),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.soil900 : AppColors.soil600;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: active,
        inMutuallyExclusiveGroup: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: active ? _tabLedge : null,
              borderRadius: BorderRadius.circular(
                AppRadii.card - AppSpacing.xs,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: active ? AppBorders.width : 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: active ? AppColors.white : null,
                  borderRadius: BorderRadius.circular(
                    AppRadii.card - AppSpacing.xs,
                  ),
                ),
                child: SizedBox(
                  height: AppSpacing.minTouchTarget - AppSpacing.sm - 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: AppIconSize.md,
                        // The trophy is gold while Top is selected.
                        color: active && icon == Symbols.emoji_events_rounded
                            ? AppColors.goldLedge
                            : fg,
                        fill: 1,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySm.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The entry to the guide editor (CM-03).
class _NewGuideButton extends StatelessWidget {
  const _NewGuideButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'New guide',
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/community/editor/new'),
        child: const SizedBox.square(
          dimension: _fabSize,
          child: LedgeCapsule(
            color: AppColors.leaf700,
            borderColor: AppColors.leaf700,
            ledgeColor: AppColors.leafLedge,
            child: Center(
              child: Icon(
                Symbols.add_rounded,
                size: AppIconSize.xl + AppSpacing.xs,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const double _fabSize = 60;

/// The guides under the filters: skeleton while the first page loads, the
/// empty and error states, or the cards with a footer for the next page.
class _FeedList extends ConsumerWidget {
  const _FeedList({required this.query, required this.controller});

  final GuideFeedQuery query;
  final ScrollController controller;

  /// Space under the last card so the FAB never covers it.
  static const _bottomInset = _fabSize + AppSpacing.xl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = communityFeedProvider(query);
    final feed = ref.watch(provider);
    final repository = ref.watch(guideRepositoryProvider);
    const inset = EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      AppSpacing.xs,
      AppSpacing.screenPadding,
      _bottomInset,
    );

    final state = feed.value;
    if (state == null) {
      if (feed.hasError) {
        return _Message(
          icon: Symbols.cloud_off_rounded,
          text: "Couldn't load guides.",
          onRetry: () => ref.invalidate(provider),
        );
      }
      return const GuideCardSkeletonList(padding: inset);
    }
    if (state.guides.isEmpty) {
      return _Message(
        icon: Symbols.menu_book_rounded,
        text: query.isFiltered ? 'No guides match.' : 'No guides yet.',
      );
    }
    return RefreshIndicator(
      color: AppColors.leaf500,
      onRefresh: () async {
        ref.invalidate(provider);
        try {
          await ref.read(provider.future);
        } on Object {
          // The list shows the error state with Retry.
        }
      },
      child: ListView.separated(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: inset,
        itemCount: state.guides.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, i) {
          if (i == state.guides.length) {
            return _Footer(
              state: state,
              onRetry: () => ref.read(provider.notifier).loadMore(),
            );
          }
          final guide = state.guides[i];
          final cover = guide.coverPath;
          return GuideCard(
            guide: guide,
            coverUrl: cover == null ? null : repository.coverUrl(cover),
            onTap: () => context.push('/community/guide/${guide.id}'),
          );
        },
      ),
    );
  }
}

/// Below the last card: a spinner while the next page loads, or the failure
/// with a retry.
class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final GuideFeedState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.loadMoreError != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              "Couldn't load more guides.",
              style: AppText.bodySm.copyWith(color: AppColors.soil600),
            ),
          ),
          GeauxButton(
            label: 'Retry',
            variant: GeauxButtonVariant.text,
            onPressed: onRetry,
          ),
        ],
      );
    }
    if (!state.hasMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: SizedBox.square(
          dimension: AppSpacing.xl,
          child: CircularProgressIndicator(
            color: AppColors.leaf500,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}

/// The empty and error states: an icon tile over a message, with a Retry
/// button when [onRetry] is given.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.leaf100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.leaf500),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppText.cardTitle.copyWith(color: AppColors.soil600),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              GeauxButton(
                label: 'Retry',
                variant: GeauxButtonVariant.text,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
