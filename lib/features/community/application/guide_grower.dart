import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/domain/plant.dart';
import '../../garden/data/guide_project_repository.dart';
import '../../onboarding/domain/space.dart';
import '../data/guide_repository_provider.dart';
import '../data/supabase_guide_grow_recorder.dart';
import '../domain/guide.dart';
import '../domain/guide_grow_recorder.dart';

/// Grow this on CM-02 (plan/07 § Grow this). Works signed out, with no
/// sign-in prompt: the project and its plantings live on the device.
class GuideGrower {
  GuideGrower({
    required this.projects,
    required this.recorder,
    required this.coverUrl,
  });

  final GuideProjectRepository projects;
  final GuideGrowRecorder recorder;
  final String Function(String coverPath) coverUrl;
  final _inFlight = <String>{};

  /// Runs steps 1–3 and returns the new project id, or null when a Grow
  /// this for [guide] is already running (a double tap).
  ///
  /// 1. Snapshots [guide] into a `guide_projects` row.
  /// 2. Adds a `planned` planting in [space] per plant id in [catalog].
  /// 3. When [signedIn], counts the grow in `guide_grows`.
  ///
  /// Step 3 never fails the action: the project is already saved, and a
  /// missed count (offline, or grown before) only leaves the counter where
  /// it was.
  Future<String?> grow({
    required Guide guide,
    required List<Plant> catalog,
    required Space space,
    required bool signedIn,
  }) async {
    if (!_inFlight.add(guide.id)) return null;
    try {
      final cover = guide.coverPath;
      final id = await projects.createFromGuide(
        guide: guide,
        coverUrl: cover == null ? null : coverUrl(cover),
        catalog: catalog,
        space: space,
      );
      if (signedIn) {
        try {
          await recorder.recordGrow(guide.id);
        } on Object {
          // See above: the count is best effort.
        }
      }
      return id;
    } finally {
      _inFlight.remove(guide.id);
    }
  }
}

final guideGrowerProvider = Provider<GuideGrower>((ref) {
  final guides = ref.watch(guideRepositoryProvider);
  return GuideGrower(
    projects: ref.watch(guideProjectRepositoryProvider),
    recorder: ref.watch(guideGrowRecorderProvider),
    coverUrl: guides.coverUrl,
  );
});
