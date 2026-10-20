import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/guide_repository_provider.dart';

/// "Starred by me": the ids of the guides the signed-in user starred
/// (plan/07 § Feed and ranking). Fetched on first read and cached for the
/// session; `ref.invalidate` refetches it.
final starredGuideIdsProvider = FutureProvider<Set<String>>(
  (ref) => ref.read(guideRepositoryProvider).starredGuideIds(),
  // No automatic retries (plan/09 § Errors).
  retry: (_, _) => null,
);
