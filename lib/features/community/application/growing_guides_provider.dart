import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';

/// The guides the user is growing, as guide id to the id of the Drift
/// `guide_projects` row that Grow this created (plan/07 § Grow this).
/// CM-02 reads "Growing" and opens GD-03 for these.
final growingGuideProjectsProvider = StreamProvider<Map<String, String>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.guideProjectsTable)
    ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
  return query.watch().map(
    (rows) => {for (final row in rows) row.guideId: row.id},
  );
});
