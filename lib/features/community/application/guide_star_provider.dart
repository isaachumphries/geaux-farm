import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_providers.dart';
import '../data/guide_repository_provider.dart';
import 'guide_detail_provider.dart';
import 'starred_guides_provider.dart';

/// Whether the user starred a guide, and the count shown next to the star.
class GuideStarState {
  const GuideStarState({required this.starred, required this.count});

  final bool starred;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is GuideStarState &&
      other.starred == starred &&
      other.count == count;

  @override
  int get hashCode => Object.hash(starred, count);
}

/// The star on CM-02 for one guide: the fetched count plus the user's own
/// star from the cached "Starred by me" set, changed at once by [setStarred]
/// and rolled back when the write fails (plan/07 § Star).
final guideStarProvider = AsyncNotifierProvider.autoDispose
    .family<GuideStarNotifier, GuideStarState, String>(
      GuideStarNotifier.new,
      retry: (_, _) => null,
    );

class GuideStarNotifier extends AsyncNotifier<GuideStarState> {
  GuideStarNotifier(this.guideId);

  final String guideId;
  var _writing = false;

  @override
  Future<GuideStarState> build() async {
    // Signing in or out changes whose star this is.
    ref.watch(authStateProvider.select((auth) => auth.value?.id));
    final guide = await ref.watch(guideDetailProvider(guideId).future);
    // Read, not watched: a successful write invalidates the set, and that
    // must not reset the count shown here.
    final starred = await ref.read(starredGuideIdsProvider.future);
    return GuideStarState(
      starred: starred.contains(guideId),
      count: guide.starCount,
    );
  }

  /// Makes the star [starred]: changes the pill and count now, then writes
  /// the one `guide_stars` row. A failed write restores the previous state
  /// and rethrows. Does nothing when the guide is already so, or while a
  /// write is in flight. The caller has checked the user is signed in.
  ///
  /// The caller decides [starred] when the user taps, so a tap that waited
  /// for sign-in still means what the user saw, even if signing in showed
  /// the guide was starred already. Signing in rebuilds this state, and the
  /// tap resumes while that is still running: [setStarred] waits for it.
  Future<void> setStarred(bool starred) async {
    if (_writing) return;
    _writing = true;
    // The screen may close while the write is in flight.
    final link = ref.keepAlive();
    try {
      final before = await future;
      if (before.starred == starred) return;
      state = AsyncData(
        GuideStarState(
          starred: starred,
          count: max(0, before.count + (starred ? 1 : -1)),
        ),
      );
      final repository = ref.read(guideRepositoryProvider);
      try {
        await (starred
            ? repository.starGuide(guideId)
            : repository.unstarGuide(guideId));
      } on Object {
        state = AsyncData(before);
        rethrow;
      }
      // The cached set must show the new star the next time a screen reads
      // it.
      ref.invalidate(starredGuideIdsProvider);
    } finally {
      _writing = false;
      link.close();
    }
  }
}
