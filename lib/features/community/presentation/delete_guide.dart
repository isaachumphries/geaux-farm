import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../application/community_feed_provider.dart';
import '../application/guide_detail_provider.dart';
import '../application/starred_guides_provider.dart';
import '../data/guide_repository_provider.dart';

/// CM-02 Delete: asks first, then removes the author's own guide and goes
/// back to the feed. A failed delete keeps the user on the guide.
///
/// RLS is the real guard on whose guide this is; CM-02 only offers the
/// action on the author's own guide.
Future<void> deleteOwnGuide(
  BuildContext context, {
  required String guideId,
}) async {
  // Taken before any await: the page behind this call is gone once the
  // route changes, the root messenger is not.
  final messenger = ScaffoldMessenger.of(context);
  // The container, not a WidgetRef: a ref dies with its page, but the
  // cached lists must refresh even when the user left while the request
  // was in flight.
  final container = ProviderScope.containerOf(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete this guide?', style: AppText.h2),
      content: const Text(
        "It will be removed from the community for everyone. This can't be undone.",
        style: AppText.body,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.soil600,
            textStyle: AppText.button,
            minimumSize: const Size(
              AppSpacing.minTouchTarget,
              AppSpacing.minTouchTarget,
            ),
          ),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
            textStyle: AppText.button,
            minimumSize: const Size(
              AppSpacing.minTouchTarget,
              AppSpacing.minTouchTarget,
            ),
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await container.read(guideRepositoryProvider).deleteGuide(guideId);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text("Couldn't delete the guide. Try again.")),
    );
    return;
  }
  container
    ..invalidate(communityFeedProvider)
    ..invalidate(starredGuideIdsProvider)
    ..invalidate(guideDetailProvider(guideId));
  if (!context.mounted) return;
  context.go('/community');
  messenger.showSnackBar(const SnackBar(content: Text('Guide deleted')));
}
