import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http.dart';
import '../data/guide_repository_provider.dart';
import '../domain/guide.dart';
import '../domain/guide_repository.dart';

/// The guide CM-02 shows, fetched when the screen opens and dropped when it
/// closes, so reopening it reads the current counts (the Gate 2 star check).
final guideDetailProvider = FutureProvider.autoDispose.family<Guide, String>(
  (ref, id) => ref.watch(guideRepositoryProvider).fetchGuide(id),
  // No automatic retries (plan/09 § Errors): the error state has Retry.
  retry: (_, _) => null,
);

/// The guide [id] was remixed from, for the "Remixed from" link. Null when
/// [id] is not a remix, or the original cannot be read (hidden, or the
/// request failed): the link is then left out rather than failing the
/// screen.
final remixSourceProvider = FutureProvider.autoDispose.family<Guide?, String>((
  ref,
  id,
) async {
  final guide = await ref.watch(guideDetailProvider(id).future);
  final sourceId = guide.forkedFrom;
  if (sourceId == null) return null;
  try {
    return await ref.read(guideRepositoryProvider).fetchGuide(sourceId);
  } on GuideNotFoundException {
    return null;
  } on NetworkException {
    return null;
  }
}, retry: (_, _) => null);
