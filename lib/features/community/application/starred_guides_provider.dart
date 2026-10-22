import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_providers.dart';
import '../data/guide_repository_provider.dart';
import '../domain/guide.dart';

/// "Starred by me": the ids of the guides the signed-in user starred
/// (plan/07 § Feed and ranking). Fetched on first read and cached for the
/// session; `ref.invalidate` refetches it, and so does signing in or out.
final starredGuideIdsProvider = FutureProvider<Set<String>>((ref) {
  // The set belongs to one user: a different user (or none) refetches.
  ref.watch(authStateProvider.select((auth) => auth.value?.id));
  return ref.read(guideRepositoryProvider).starredGuideIds();
}, retry: (_, _) => null);

/// CM-05 Starred: the published guides in the cached "Starred by me" set,
/// newest star first. Built from the cached set, so opening CM-05 doesn't
/// fetch the set again; a star change on CM-02 refreshes the set and this
/// list follows it.
final starredGuidesProvider = FutureProvider.autoDispose<List<Guide>>((
  ref,
) async {
  final ids = await ref.watch(starredGuideIdsProvider.future);
  return ref.read(guideRepositoryProvider).fetchGuidesByIds(ids.toList());
}, retry: (_, _) => null);
