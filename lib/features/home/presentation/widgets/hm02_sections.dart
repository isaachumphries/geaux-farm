import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../care/application/care_schedule_provider.dart';
import '../../../care/domain/slot.dart';
import '../../../care/presentation/care_screen.dart';
import '../../../care/presentation/widgets/task_row.dart';
import '../../../community/application/community_feed_provider.dart';
import '../../../community/data/guide_repository_provider.dart';
import '../../../community/presentation/widgets/guide_card.dart';
import '../../../recommendations/application/clock_provider.dart';
import '../../../weather/application/garden_alerts_provider.dart';
import '../../../weather/presentation/alert_banner.dart';
import '../../domain/today_tasks.dart';

/// HM-02 garden alerts, top of the page. Nothing at all when there are no
/// alerts: an alert is never invented without data (#73).
class HomeAlerts extends ConsumerWidget {
  const HomeAlerts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(gardenAlertsProvider).value ?? const [];
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        for (final a in alerts) ...[
          AlertBanner.alert(a),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// HM-02 "Today": today's care tasks grouped under their free-time slot
/// (CR-01's labels). A row opens CR-01 for today; marking done happens
/// there.
class TodaySection extends ConsumerWidget {
  const TodaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(careScheduleProvider);
    final today = ref.watch(todayProvider);
    final tasks = schedule.value;
    final groups = tasks == null ? null : todayGroups(tasks, today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Today',
                style: AppText.h2.copyWith(color: AppColors.soil900),
              ),
            ),
            GeauxButton(
              label: 'Care list',
              variant: GeauxButtonVariant.text,
              onPressed: () => context.go('/care'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (groups == null && schedule.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.leaf500),
            ),
          )
        else if (groups == null || groups.isEmpty)
          Text(
            careEmptyCopy,
            style: AppText.body.copyWith(color: AppColors.soil600),
          )
        else
          for (final g in groups) ...[
            CareGroupHeader(
              icon: Symbols.schedule_rounded,
              label: g.start == null
                  ? outsideFreeTimesCopy
                  : formatClock(context, g.start!),
            ),
            for (final t in g.tasks) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.go('/care'),
                child: TaskRow(
                  type: taskRowTypeOf(t.kind),
                  state: t.rainSkip ? TaskRowState.rainSkip : TaskRowState.due,
                  plantName: t.nickname,
                  note: t.note,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

/// HM-02 "Top guide this week": the first Trending guide as a [GuideCard].
/// Shows a section loader while pending; hidden on error or empty Trending.
class TopGuideSection extends ConsumerWidget {
  const TopGuideSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(topGuideThisWeekProvider);
    final guide = trending.value;
    if (guide == null) {
      if (trending.isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.leaf500),
        );
      }
      return const SizedBox.shrink();
    }
    final cover = guide.coverPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Top guide this week',
                style: AppText.h2.copyWith(color: AppColors.soil900),
              ),
            ),
            GeauxButton(
              label: 'See all',
              variant: GeauxButtonVariant.text,
              onPressed: () => context.go('/community'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GuideCard(
          guide: guide,
          coverUrl: cover == null
              ? null
              : ref.read(guideRepositoryProvider).coverUrl(cover),
          onTap: () => context.push('/community/guide/${guide.id}'),
        ),
      ],
    );
  }
}
