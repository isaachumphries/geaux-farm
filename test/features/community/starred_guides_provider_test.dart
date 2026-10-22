import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/application/my_guides_provider.dart';
import 'package:geaux_farm/features/community/application/starred_guides_provider.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/domain/guide_repository.dart';

import '../../community/fake_auth_repository.dart';
import '../../community/guide_detail_harness.dart' show signedInUser;
import '../../helpers/community_fixtures.dart';

ProviderContainer _container(
  FakeGuideRepository repo, {
  FakeAuthRepository? auth,
}) {
  final container = ProviderContainer(
    overrides: [
      guideRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(
        auth ?? FakeAuthRepository(user: signedInUser),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('starredGuidesProvider', () {
    test('loads the guides in the cached set, in its order', () async {
      final repo = FakeGuideRepository(
        starred: {'g3', 'g1'},
        guides: {
          'g1': testGuide('g1'),
          'g2': testGuide('g2'),
          'g3': testGuide('g3'),
        },
      );
      final container = _container(repo);
      container.listen(starredGuidesProvider, (_, _) {});

      final guides = await container.read(starredGuidesProvider.future);

      expect([for (final g in guides) g.id], ['g3', 'g1']);
      expect(repo.idFetches, [
        ['g3', 'g1'],
      ]);
    });

    test('opening it again does not fetch the set again', () async {
      final repo = FakeGuideRepository(
        starred: {'g1'},
        guides: {'g1': testGuide('g1')},
      );
      final container = _container(repo);
      container.listen(authStateProvider, (_, _) {});
      await container.read(authStateProvider.future);
      // CM-01 or CM-02 already read the set this session.
      await container.read(starredGuideIdsProvider.future);
      expect(repo.starredFetches, 1);

      final sub = container.listen(starredGuidesProvider, (_, _) {});
      await container.read(starredGuidesProvider.future);
      sub.close();
      await container.pump();
      final again = container.listen(starredGuidesProvider, (_, _) {});
      await container.read(starredGuidesProvider.future);
      again.close();

      expect(repo.starredFetches, 1);
    });

    test('a refreshed set (after an unstar) drops the guide', () async {
      final repo = FakeGuideRepository(
        starred: {'g1', 'g2'},
        guides: {'g1': testGuide('g1'), 'g2': testGuide('g2')},
      );
      final container = _container(repo);
      final sub = container.listen(starredGuidesProvider, (_, _) {});
      expect(
        [
          for (final g in await container.read(starredGuidesProvider.future))
            g.id,
        ],
        ['g1', 'g2'],
      );

      await repo.unstarGuide('g1');
      container.invalidate(starredGuideIdsProvider);

      expect(
        [
          for (final g in await container.read(starredGuidesProvider.future))
            g.id,
        ],
        ['g2'],
      );
      sub.close();
    });
  });

  group('myGuidesProvider', () {
    test('signed in: the repository\'s own guides, as ordered', () async {
      final repo = FakeGuideRepository(
        mine: [
          (guide: testGuide('d1'), status: GuideStatus.draft),
          (guide: testGuide('p1'), status: GuideStatus.published),
        ],
      );
      final container = _container(repo);
      container.listen(myGuidesProvider, (_, _) {});

      final mine = await container.read(myGuidesProvider.future);

      expect([for (final g in mine) g.guide.id], ['d1', 'p1']);
      expect(repo.myGuidesFetches, 1);
    });

    test('signed out: empty, with no request', () async {
      final repo = FakeGuideRepository(
        mine: [(guide: testGuide('d1'), status: GuideStatus.draft)],
      );
      final container = _container(repo, auth: FakeAuthRepository());
      container.listen(myGuidesProvider, (_, _) {});

      expect(await container.read(myGuidesProvider.future), isEmpty);
      expect(repo.myGuidesFetches, 0);
    });
  });
}
