import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/community/application/growing_guides_provider.dart';

import '../helpers/in_memory_database.dart';

// CM-02 reads "Growing" and opens the project for a guide the user already
// grew, from the device-local guide_projects rows (plan/07 § Grow this). The
// screen tests override this provider; these read the real rows.
void main() {
  late ProviderContainer container;
  late AppDatabase db;

  setUp(() {
    container = ProviderContainer(overrides: [inMemoryDatabaseOverride()]);
    addTearDown(container.dispose);
    db = container.read(appDatabaseProvider);
    container.listen(growingGuideProjectsProvider, (_, _) {});
  });

  /// The provider's latest value once drift's re-query has landed.
  Future<Map<String, String>> growing() async {
    await pumpEventQueue();
    return container.read(growingGuideProjectsProvider).requireValue;
  }

  Future<void> addProject(String id, String guideId, DateTime createdAt) => db
      .into(db.guideProjectsTable)
      .insert(
        GuideProjectsTableCompanion.insert(
          id: id,
          guideId: guideId,
          title: 'Balcony salsa garden in 4 pots',
          materialsJson: '[]',
          stepsJson: '[]',
          createdAt: createdAt,
        ),
      );

  test('no guide is growing before Grow this has run', () async {
    expect(await growing(), isEmpty);
  });

  test('maps each guide id to the id of its project', () async {
    await addProject('project-1', 'guide-a', DateTime(2026, 10, 1));
    await addProject('project-2', 'guide-b', DateTime(2026, 10, 2));

    expect(await growing(), {'guide-a': 'project-1', 'guide-b': 'project-2'});
  });

  test('follows a project added while the guide is open', () async {
    expect(await growing(), isEmpty);

    await addProject('project-1', 'guide-a', DateTime(2026, 10, 1));

    expect(await growing(), {'guide-a': 'project-1'});
  });

  test('the newest project wins when a guide was grown twice', () async {
    // Written newest first, so row order and creation order disagree.
    await addProject('newer', 'guide-a', DateTime(2026, 10, 9));
    await addProject('older', 'guide-a', DateTime(2026, 10, 3));

    expect(await growing(), {'guide-a': 'newer'});
  });
}
