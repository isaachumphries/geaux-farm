import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/guide_project_repository.dart';
import '../data/plantings_provider.dart';
import '../domain/guide_project.dart';
import '../domain/planting.dart';

/// One `guide_projects` row for GD-03, or null when there is none.
final guideProjectProvider = StreamProvider.autoDispose
    .family<GuideProject?, String>(
      (ref, id) => ref.watch(guideProjectRepositoryProvider).watchProject(id),
    );

/// The plantings Grow this created for project [id], oldest first.
final projectPlantingsProvider = Provider.autoDispose
    .family<AsyncValue<List<Planting>>, String>(
      (ref, id) => ref
          .watch(plantingsProvider)
          .whenData(
            (all) => [
              for (final p in all)
                if (p.projectId == id) p,
            ],
          ),
    );
