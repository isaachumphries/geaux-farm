import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env.dart';
import '../../../core/http.dart';
import '../domain/guide.dart';
import '../domain/guide_feed_query.dart';
import '../domain/guide_repository.dart';
import 'supabase_guide_repository.dart';

/// The Supabase-backed repository, or [UnconfiguredGuideRepository] when
/// the app was started without `env.json` (see [Env.hasSupabase]).
final guideRepositoryProvider = Provider<GuideRepository>(
  (ref) => Env.hasSupabase
      ? SupabaseGuideRepository(Supabase.instance.client)
      : const UnconfiguredGuideRepository(),
);

/// No backend: the feed fails as unreachable, so the screen shows its error
/// state with Retry instead of crashing.
class UnconfiguredGuideRepository implements GuideRepository {
  const UnconfiguredGuideRepository();

  static const _unavailable = NetworkException('Supabase is not configured');

  @override
  Future<List<Guide>> fetchFeed(GuideFeedQuery query, {int offset = 0}) =>
      Future.error(_unavailable);

  @override
  Future<Set<String>> starredGuideIds() async => const {};

  @override
  String coverUrl(String coverPath) => '';
}
