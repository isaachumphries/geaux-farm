import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/guide_detail_provider.dart';
import '../application/my_guides_provider.dart';
import '../data/guide_repository_provider.dart';
import '../data/remix_payload.dart';
import 'sign_in_sheet.dart';

/// CM-02 Remix: copies guide [guideId] into a new draft of the signed-in
/// user's and opens it on CM-03a (plan/07 § Remix). Signed out, the CM-04
/// sheet comes first and nothing is sent until sign-in finishes.
///
/// A failed insert leaves the user on CM-02 with nothing saved. plan/07
/// gives no copy for that failure, so none is shown (raised on #57).
Future<void> remixGuide(
  BuildContext context,
  WidgetRef ref, {
  required String guideId,
}) {
  return requireSignIn(
    context,
    ref,
    reason: SignInAction.remix,
    action: () async {
      // The sign-in sheet can outlive the screen behind it.
      if (!context.mounted) return;
      // The container, not the ref: CM-05's cached list must refresh even
      // if the page goes away while the insert is in flight.
      final container = ProviderScope.containerOf(context);
      final String newId;
      try {
        final original = await ref.read(guideDetailProvider(guideId).future);
        newId = await container
            .read(guideRepositoryProvider)
            .insertRemixDraft(buildRemixPayload(original));
      } on Object {
        return;
      }
      container.invalidate(myGuidesProvider);
      if (!context.mounted) return;
      context.push('/community/editor/$newId');
    },
  );
}
