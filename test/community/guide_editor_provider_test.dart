import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/community/application/guide_editor_provider.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/domain/guide_repository.dart';
import 'package:geaux_farm/features/community/domain/guide_validation.dart';

import '../helpers/community_fixtures.dart';

// The notifier behind CM-03a-e: it holds one draft across the five steps,
// blocks a save that does not validate, and keeps the author's local edits
// when a write is refused (plan/07 § Editor).

GuideDraft _publishable(GuideDraft draft) => draft.copyWith(
  title: 'Bucket tomatoes',
  summary: 'A cheap way to grow tomatoes.',
  difficulty: 2,
  spaceTypes: const ['balcony'],
  materials: const [GuideMaterial(name: 'Bucket', qty: '1')],
  steps: const [GuideStep(title: 'Drill holes', body: 'Six.')],
);

/// The editors of the routes the tests open stay alive between reads, as
/// they do under the editor screen; pass `keepAlive: false` to watch one
/// being left.
({ProviderContainer container, FakeGuideRepository repo}) _rig({
  bool keepAlive = true,
}) {
  final repo = FakeGuideRepository(
    drafts: {
      'g1': (
        draft: const GuideDraft(id: 'g1', title: 'Old title', difficulty: 1),
        status: GuideStatus.published,
      ),
    },
  );
  final container = ProviderContainer(
    overrides: [guideRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  if (keepAlive) {
    for (final id in [newGuideRouteId, 'g1', 'missing']) {
      container.listen(guideEditorProvider(id), (_, _) {});
    }
  }
  return (container: container, repo: repo);
}

void main() {
  group('build', () {
    test('the "new" route id starts an unsaved draft', () {
      final rig = _rig();
      final state = rig.container.read(guideEditorProvider(newGuideRouteId));

      expect(state.draft.id, isNull);
      expect(state.draft.isSaved, isFalse);
      expect(state.errors, isEmpty);
    });

    test('an existing route id loads the author\'s guide', () async {
      final rig = _rig();
      final notifier = rig.container.read(guideEditorProvider('g1').notifier);

      expect(rig.container.read(guideEditorProvider('g1')).loading, isTrue);
      await notifier.load();

      final state = rig.container.read(guideEditorProvider('g1'));
      expect(state.loading, isFalse);
      expect(state.draft.id, 'g1');
      expect(state.draft.title, 'Old title');
      expect(state.status, GuideStatus.published);
    });

    test('a guide that cannot be read exposes the load error', () async {
      final rig = _rig();
      final notifier = rig.container.read(
        guideEditorProvider('missing').notifier,
      );
      await notifier.load();

      final state = rig.container.read(guideEditorProvider('missing'));
      expect(state.loading, isFalse);
      expect(state.loadError, isA<GuideNotFoundException>());
    });

    test('a published guide is never saved back to a draft', () async {
      final rig = _rig();
      final notifier = rig.container.read(guideEditorProvider('g1').notifier);
      await notifier.load();

      expect(await notifier.saveDraft(), isNull);
      expect(rig.repo.draftWrites, isEmpty);
    });
  });

  test('edits from the five steps accumulate on one draft', () {
    final rig = _rig();
    final notifier = rig.container.read(
      guideEditorProvider(newGuideRouteId).notifier,
    );

    notifier.edit((d) => d.copyWith(title: 'Bucket tomatoes'));
    notifier.edit((d) => d.copyWith(summary: 'Cheap and easy.'));
    notifier.edit((d) => d.copyWith(plantIds: const ['cherry-tomato']));

    final draft = rig.container
        .read(guideEditorProvider(newGuideRouteId))
        .draft;
    expect(draft.title, 'Bucket tomatoes');
    expect(draft.summary, 'Cheap and easy.');
    expect(draft.plantIds, ['cherry-tomato']);
  });

  group('saveDraft', () {
    test(
      'a blocked first save writes nothing and reports the fields',
      () async {
        final rig = _rig();
        final notifier = rig.container.read(
          guideEditorProvider(newGuideRouteId).notifier,
        );
        notifier.edit((d) => d.copyWith(title: 'four'));

        final id = await notifier.saveDraft();

        expect(id, isNull);
        expect(rig.repo.draftWrites, isEmpty);
        final state = rig.container.read(guideEditorProvider(newGuideRouteId));
        expect(state.errors[GuideField.title], GuideFieldError.titleTooShort);
        expect(
          state.errors[GuideField.difficulty],
          GuideFieldError.difficultyMissing,
        );
      },
    );

    test(
      'the first save keeps the server id, so the next save updates',
      () async {
        final rig = _rig();
        final notifier = rig.container.read(
          guideEditorProvider(newGuideRouteId).notifier,
        );
        notifier.edit(_publishable);

        final id = await notifier.saveDraft();
        expect(id, 'g-new');
        expect(
          rig.container.read(guideEditorProvider(newGuideRouteId)).draft.id,
          'g-new',
        );

        await notifier.saveDraft();
        expect(rig.repo.draftWrites.map((w) => w.$1), [
          'saveDraft',
          'saveDraft',
        ]);
        // The second call carries the id, so the repository updates.
        expect(rig.repo.draftWrites.last.$2.id, 'g-new');
      },
    );

    test('editing after a blocked save clears the stale errors', () async {
      final rig = _rig();
      final notifier = rig.container.read(
        guideEditorProvider(newGuideRouteId).notifier,
      );
      await notifier.saveDraft();
      expect(
        rig.container.read(guideEditorProvider(newGuideRouteId)).errors,
        isNotEmpty,
      );

      notifier.edit((d) => d.copyWith(title: 'Bucket tomatoes'));

      expect(
        rig.container.read(guideEditorProvider(newGuideRouteId)).errors,
        isEmpty,
      );
    });
  });

  group('publish', () {
    test(
      'a draft missing publish fields is blocked and writes nothing',
      () async {
        final rig = _rig();
        final notifier = rig.container.read(
          guideEditorProvider(newGuideRouteId).notifier,
        );
        notifier.edit(
          (d) => d.copyWith(title: 'Bucket tomatoes', difficulty: 2),
        );

        final id = await notifier.publish();

        expect(id, isNull);
        expect(rig.repo.draftWrites, isEmpty);
        final errors = rig.container
            .read(guideEditorProvider(newGuideRouteId))
            .errors;
        expect(
          errors.keys,
          containsAll(<String>[
            GuideField.summary,
            GuideField.spaceTypes,
            GuideField.materials,
            GuideField.steps,
          ]),
        );
      },
    );

    test('a complete draft publishes', () async {
      final rig = _rig();
      final notifier = rig.container.read(
        guideEditorProvider(newGuideRouteId).notifier,
      );
      notifier.edit(_publishable);

      expect(await notifier.publish(), 'g-new');
      expect(rig.repo.draftWrites.single.$1, 'publishGuide');
    });
  });

  group('a second write while one is out', () {
    test('publish twice without waiting writes once', () async {
      final rig = _rig();
      final gate = rig.repo.writeGate = Completer<void>();
      final notifier = rig.container.read(
        guideEditorProvider(newGuideRouteId).notifier,
      );
      notifier.edit(_publishable);

      final first = notifier.publish();
      final second = notifier.publish();
      await Future<void>.delayed(Duration.zero);
      gate.complete();

      expect(await first, 'g-new');
      expect(await second, isNull);
      expect(rig.repo.draftWrites, hasLength(1));
    });
  });

  group('leaving the editor', () {
    test('a save still in flight cannot name the next new guide', () async {
      final rig = _rig(keepAlive: false);
      final gate = rig.repo.writeGate = Completer<void>();
      final first = rig.container.listen(
        guideEditorProvider(newGuideRouteId),
        (_, _) {},
      );
      final notifier = rig.container.read(
        guideEditorProvider(newGuideRouteId).notifier,
      );
      notifier.edit(_publishable);
      final saving = notifier.saveDraft();
      await Future<void>.delayed(Duration.zero);
      expect(rig.repo.draftWrites, hasLength(1));

      // The author leaves, then opens a new guide while the save is out.
      first.close();
      await rig.container.pump();
      final second = rig.container.listen(
        guideEditorProvider(newGuideRouteId),
        (_, _) {},
      );
      expect(second.read().draft.title, isEmpty);

      gate.complete();
      // The write itself succeeded, so the caller still gets its id.
      expect(await saving, 'g-new');

      final state = second.read();
      expect(state.draft.id, isNull);
      expect(state.draft.title, isEmpty);
      expect(state.saving, isFalse);
      expect(state.status, isNull);
    });

    test('a write that fails after the editor closed ends quietly', () async {
      final rig = _rig(keepAlive: false);
      final gate = rig.repo.writeGate = Completer<void>();
      rig.repo.writeError = const NetworkException('offline');
      final editor = rig.container.listen(
        guideEditorProvider(newGuideRouteId),
        (_, _) {},
      );
      final notifier = rig.container.read(
        guideEditorProvider(newGuideRouteId).notifier,
      );
      notifier.edit(_publishable);
      final publishing = notifier.publish();
      await Future<void>.delayed(Duration.zero);

      editor.close();
      await rig.container.pump();
      gate.complete();

      expect(await publishing, isNull);
    });
  });

  group('a refused write', () {
    test('keeps the local edits and exposes the error', () async {
      final rig = _rig();
      rig.repo.writeError = const NetworkException('offline');
      final notifier = rig.container.read(guideEditorProvider('g1').notifier);
      await notifier.load();
      notifier.edit(_publishable);

      final id = await notifier.publish();

      expect(id, isNull);
      final state = rig.container.read(guideEditorProvider('g1'));
      expect(state.writeError, isA<NetworkException>());
      expect(state.saving, isFalse);
      // Nothing typed is lost.
      expect(state.draft.title, 'Bucket tomatoes');
      expect(state.draft.steps, hasLength(1));
    });

    test('a signed-out write is reported as needing sign-in', () async {
      final rig = _rig();
      rig.repo.writeError = const AuthRequiredException();
      final notifier = rig.container.read(
        guideEditorProvider(newGuideRouteId).notifier,
      );
      notifier.edit(_publishable);

      await notifier.publish();

      final state = rig.container.read(guideEditorProvider(newGuideRouteId));
      expect(isSignInRequired(state.writeError), isTrue);
      expect(state.draft.title, 'Bucket tomatoes');
    });

    test('the next edit clears the error', () async {
      final rig = _rig();
      rig.repo.writeError = const NetworkException('offline');
      final notifier = rig.container.read(guideEditorProvider('g1').notifier);
      await notifier.load();
      notifier.edit(_publishable);
      await notifier.publish();

      notifier.edit((d) => d.copyWith(title: 'Bucket tomatoes II'));

      expect(rig.container.read(guideEditorProvider('g1')).writeError, isNull);
    });
  });
}
