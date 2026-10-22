import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_providers.dart';
import '../data/guide_repository_provider.dart';
import '../domain/guide_repository.dart';

/// CM-05 My guides: the signed-in author's guides of every status, newest
/// update first. Empty when signed out, without a request; CM-05 asks for
/// sign-in before it shows the list.
final myGuidesProvider = FutureProvider.autoDispose<List<OwnGuide>>((
  ref,
) async {
  final userId = await ref.watch(
    authStateProvider.selectAsync((auth) => auth?.id),
  );
  if (userId == null) return const [];
  return ref.read(guideRepositoryProvider).fetchMyGuides();
}, retry: (_, _) => null);
