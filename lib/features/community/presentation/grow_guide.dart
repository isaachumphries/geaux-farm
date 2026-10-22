import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../catalog/data/catalog_provider.dart';
import '../../onboarding/data/profile_providers.dart';
import '../application/guide_detail_provider.dart';
import '../application/guide_grower.dart';
import '../data/auth_providers.dart';

/// CM-02 Grow this: copies guide [guideId] into My Garden, then opens the
/// new project on GD-03. The button reads "Growing" from then on, because
/// the project row exists.
Future<void> growGuide(
  BuildContext context,
  WidgetRef ref, {
  required String guideId,
}) async {
  // Riverpod pauses a stream provider nobody listens to, and read() isn't
  // listening, so hold listeners while waiting for the first values.
  final subscriptions = [
    ref.listenManual(primarySpaceProvider, (_, _) {}),
    ref.listenManual(authStateProvider, (_, _) {}),
  ];
  final String? projectId;
  try {
    final guide = await ref.read(guideDetailProvider(guideId).future);
    final catalog = await ref.read(catalogProvider.future);
    final space = await ref.read(primarySpaceProvider.future);
    final user = ref.read(authStateProvider).value;
    projectId = await ref
        .read(guideGrowerProvider)
        .grow(
          guide: guide,
          catalog: catalog,
          space: space,
          signedIn: user != null && user.hasProfile,
        );
  } finally {
    for (final s in subscriptions) {
      s.close();
    }
  }
  if (projectId == null || !context.mounted) return;
  context.push('/garden/project/$projectId');
}
