import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../domain/planting.dart';

/// Every `plantings` row, oldest first.
final plantingsProvider = StreamProvider<List<Planting>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.plantingsTable)
    ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
  return query.watch().map((rows) => rows.map(_plantingFromRow).toList());
});

Planting _plantingFromRow(PlantingRow r) => Planting(
  id: r.id,
  plantId: r.plantId,
  spaceId: r.spaceId,
  nickname: r.nickname,
  setup: r.setup,
  inContainer: r.inContainer,
  startMethod: r.startMethod,
  plantedOn: r.plantedOn,
  status: r.status,
  projectId: r.projectId,
  createdAt: r.createdAt,
);
