import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env.dart';
import '../../../core/http.dart';
import '../domain/guide.dart';
import '../domain/guide_feed_query.dart';
import '../domain/guide_repository.dart';
import '../domain/guide_validation.dart';
import '../domain/report_reason.dart';
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
  Future<List<Guide>> fetchGuidesByIds(List<String> ids) async => const [];

  @override
  Future<List<OwnGuide>> fetchMyGuides() => Future.error(_unavailable);

  @override
  Future<Guide> fetchGuide(String id) => Future.error(_unavailable);

  @override
  Future<void> starGuide(String id) => Future.error(_unavailable);

  @override
  Future<void> unstarGuide(String id) => Future.error(_unavailable);

  @override
  Future<void> reportGuide(
    String id, {
    required ReportReason reason,
    String? note,
  }) => Future.error(_unavailable);

  @override
  String coverUrl(String coverPath) => '';

  @override
  Future<EditableGuide> fetchDraft(String id) => Future.error(_unavailable);

  @override
  Future<String> saveDraft(GuideDraft draft) => Future.error(_unavailable);

  @override
  Future<String> publishGuide(GuideDraft draft) => Future.error(_unavailable);

  @override
  Future<String> insertRemixDraft(Map<String, dynamic> payload) =>
      Future.error(_unavailable);

  @override
  Future<void> deleteGuide(String guideId) => Future.error(_unavailable);
}
