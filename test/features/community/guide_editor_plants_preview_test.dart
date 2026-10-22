import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/community/application/guide_editor_provider.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/domain/guide_repository.dart';
import 'package:geaux_farm/features/community/domain/guide_validation.dart';
import 'package:geaux_farm/features/community/presentation/editor/editor_copy.dart';
import 'package:geaux_farm/features/community/presentation/editor/plants_step_screen.dart';
import 'package:geaux_farm/features/community/presentation/editor/preview_step_screen.dart';
import 'package:geaux_farm/features/community/presentation/sign_in_sheet.dart';
import 'package:go_router/go_router.dart';

import '../../community/fake_auth_repository.dart';
import '../../community/guide_detail_harness.dart' show signedInUser;
import '../../helpers/app_fonts.dart';
import '../../helpers/community_fixtures.dart';
import '../../recommendations/fixtures/baton_rouge.dart';

// CM-03d and CM-03e: the plant picker and the preview with its Save draft
// and Publish buttons (plan/07 § Editor).

const _names = [
  'Basil',
  'Kale',
  'Tomato',
  'Mint',
  'Lavender',
  'Rosemary',
  'Thyme',
  'Okra',
  'Pepper',
  'Squash',
  'Cucumber',
  'Marigold',
];

/// Twelve catalog plants, ids `p1` to `p12`, named by [_names].
final _catalog = [
  for (final (i, name) in _names.indexed)
    Plant.fromJson({...rawKale(), 'id': 'p${i + 1}', 'commonName': name}),
];

String _id(String name) => 'p${_names.indexOf(name) + 1}';

/// Passes every publish rule.
const _complete = GuideDraft(
  title: 'Balcony salsa garden',
  summary: 'Four pots, one afternoon.',
  difficulty: 1,
  spaceTypes: ['balcony'],
  materials: [GuideMaterial(name: 'Grow pots', qty: '4')],
  steps: [GuideStep(title: 'Fill the pots', body: 'Potting mix to the rim.')],
  plantIds: ['p2'],
);

typedef _Harness = ({ProviderContainer container, List<EditorStep> edits});

/// Pumps [builder]'s screen at 360x800, inside a router that has a stub
/// CM-02, and returns the provider container and the steps Edit asked for.
Future<_Harness> _pump(
  WidgetTester tester,
  FakeGuideRepository repo, {
  required Widget Function(List<EditorStep> edits) screen,
  FakeAuthRepository? auth,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final edits = <EditorStep>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: screen(edits),
          ),
        ),
      ),
      GoRoute(
        path: '/community/guide/:id',
        builder: (_, state) => Text('guide ${state.pathParameters['id']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      guideRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(
        auth ?? FakeAuthRepository(user: signedInUser),
      ),
      catalogProvider.overrideWith((ref) async => _catalog),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
  return (container: container, edits: edits);
}

Future<_Harness> _pumpPlants(WidgetTester tester, FakeGuideRepository repo) =>
    _pump(
      tester,
      repo,
      screen: (_) => const PlantsStepScreen(guideId: newGuideRouteId),
    );

Future<_Harness> _pumpPreview(
  WidgetTester tester,
  FakeGuideRepository repo, {
  String id = newGuideRouteId,
  FakeAuthRepository? auth,
}) async {
  final harness = await _pump(
    tester,
    repo,
    auth: auth,
    screen: (edits) => PreviewStepScreen(guideId: id, onEditStep: edits.add),
  );
  await tester.pumpAndSettle();
  return harness;
}

GuideEditorState _state(_Harness h, [String id = newGuideRouteId]) =>
    h.container.read(guideEditorProvider(id));

void _edit(_Harness h, GuideDraft draft) => h.container
    .read(guideEditorProvider(newGuideRouteId).notifier)
    .edit((_) => draft);

/// The Preview button labelled [label] ("Save draft" or "Publish").
GeauxButton _button(WidgetTester tester, String label) =>
    tester.widget<GeauxButton>(
      find.byWidgetPredicate((w) => w is GeauxButton && w.label == label),
    );

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('CM-03d plants', () {
    testWidgets('search narrows the catalog and a tap picks the plant', (
      tester,
    ) async {
      final h = await _pumpPlants(tester, FakeGuideRepository());
      expect(find.text('Kale'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'MAR');
      await tester.pump();
      expect(find.text('Marigold'), findsOneWidget);
      expect(find.text('Rosemary'), findsOneWidget);
      expect(find.text('Kale'), findsNothing);

      await _tap(tester, find.text('Marigold'));
      expect(_state(h).draft.plantIds, [_id('Marigold')]);
      // Picked plants show first as a chip that removes them again.
      expect(find.byKey(ValueKey('chip-${_id('Marigold')}')), findsOneWidget);
      await _tap(tester, find.byKey(ValueKey('chip-${_id('Marigold')}')));
      expect(_state(h).draft.plantIds, isEmpty);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('an eleventh plant cannot be picked', (tester) async {
      final h = await _pumpPlants(tester, FakeGuideRepository());
      final nine = _names.take(9).map(_id).toList();
      _edit(h, GuideDraft(plantIds: nine));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Squash');
      await tester.pump();
      await _tap(tester, find.byKey(ValueKey('plant-${_id('Squash')}')));
      expect(_state(h).draft.plantIds, hasLength(10));

      await tester.enterText(find.byType(TextField), 'Marigold');
      await tester.pump();
      await tester.tap(
        find.byKey(ValueKey('plant-${_id('Marigold')}')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(_state(h).draft.plantIds, hasLength(10));
      expect(_state(h).draft.plantIds, isNot(contains(_id('Marigold'))));

      // Taking one out opens a place again.
      await _tap(tester, find.byKey(ValueKey('chip-${_id('Basil')}')));
      await _tap(tester, find.byKey(ValueKey('plant-${_id('Marigold')}')));
      expect(_state(h).draft.plantIds, contains(_id('Marigold')));
    });

    testWidgets('a plant that cannot be picked is still read out by name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = await _pumpPlants(tester, FakeGuideRepository());
      _edit(h, GuideDraft(plantIds: _names.take(10).map(_id).toList()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Marigold');
      await tester.pump();

      final node = tester.getSemantics(
        find.byKey(ValueKey('plant-${_id('Marigold')}')),
      );
      expect(node.label, contains('Marigold'));
      handle.dispose();
    });
  });

  group('CM-03e preview', () {
    testWidgets('shows the draft the way CM-02 lays it out', (tester) async {
      final repo = FakeGuideRepository(
        drafts: {
          'g1': (
            draft: _complete.copyWith(id: 'g1'),
            status: GuideStatus.draft,
          ),
        },
      );
      await _pumpPreview(tester, repo, id: 'g1');

      expect(find.text('Balcony salsa garden'), findsOneWidget);
      expect(find.text('Four pots, one afternoon.'), findsOneWidget);
      expect(find.text('Balcony'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
      expect(find.textContaining('Grow pots'), findsOneWidget);
      expect(find.text('Fill the pots'), findsOneWidget);
      expect(find.text('Kale'), findsOneWidget);
    });

    testWidgets('publishing an incomplete draft writes nothing and says why', (
      tester,
    ) async {
      final repo = FakeGuideRepository();
      final h = await _pumpPreview(tester, repo);
      _edit(h, const GuideDraft(title: 'Salsa'));
      await tester.pump();

      await _tap(tester, find.text('PUBLISH'));

      expect(repo.draftWrites, isEmpty);
      expect(find.text('Add a summary'), findsOneWidget);
      expect(find.text('Pick a difficulty'), findsOneWidget);
      expect(find.text('Add at least one material'), findsOneWidget);
      expect(find.text('Add at least one step'), findsOneWidget);

      Finder editFor(String message) => find.descendant(
        of: find.widgetWithText(GeauxCard, message),
        matching: find.text('EDIT'),
      );
      await _tap(tester, editFor('Add at least one material'));
      await _tap(tester, editFor('Add at least one step'));
      await _tap(tester, editFor('Add a summary'));
      expect(h.edits, [
        EditorStep.materials,
        EditorStep.steps,
        EditorStep.basics,
      ]);
    });

    testWidgets('publishing a complete draft opens the new guide', (
      tester,
    ) async {
      final repo = FakeGuideRepository();
      final h = await _pumpPreview(tester, repo);
      _edit(h, _complete);
      await tester.pump();

      await _tap(tester, find.text('PUBLISH'));

      expect(repo.draftWrites, hasLength(1));
      final (action, written) = repo.draftWrites.single;
      expect(action, 'publishGuide');
      expect(written.title, 'Balcony salsa garden');
      expect(written.plantIds, ['p2']);
      expect(find.text('guide g-new'), findsOneWidget);
      // The next new guide starts blank, not as an edit of this one.
      expect(_state(h).draft.title, isEmpty);
      expect(_state(h).draft.id, isNull);
    });

    testWidgets('Save draft keeps the guide and says so', (tester) async {
      final repo = FakeGuideRepository();
      final h = await _pumpPreview(tester, repo);

      // Nothing to save until there is a title.
      expect(_button(tester, 'Save draft').onPressed, isNull);
      _edit(h, const GuideDraft(title: '  ', difficulty: 2));
      await tester.pump();
      expect(_button(tester, 'Save draft').onPressed, isNull);
      expect(repo.draftWrites, isEmpty);

      _edit(h, const GuideDraft(title: 'Balcony salsa', difficulty: 2));
      await tester.pump();
      expect(_button(tester, 'Save draft').onPressed, isNotNull);
      await _tap(tester, find.text('SAVE DRAFT'));

      expect(repo.draftWrites.map((w) => w.$1), ['saveDraft']);
      expect(find.text('Draft saved'), findsOneWidget);
      expect(find.text('PUBLISH'), findsOneWidget);
      expect(_state(h).draft.id, 'g-new');
    });

    testWidgets('a published guide is edited in place: no Save draft', (
      tester,
    ) async {
      final repo = FakeGuideRepository(
        drafts: {
          'g1': (
            draft: _complete.copyWith(id: 'g1'),
            status: GuideStatus.published,
          ),
        },
      );
      await _pumpPreview(tester, repo, id: 'g1');

      expect(find.text('SAVE DRAFT'), findsNothing);
      expect(find.text('PUBLISH'), findsOneWidget);
    });

    testWidgets('signed out, Publish and Save draft ask to sign in first', (
      tester,
    ) async {
      final repo = FakeGuideRepository();
      final h = await _pumpPreview(tester, repo, auth: FakeAuthRepository());
      _edit(h, _complete);
      await tester.pump();

      await _tap(tester, find.text('PUBLISH'));
      expect(find.byType(SignInSheet), findsOneWidget);
      expect(find.text('Sign in to publish guides'), findsOneWidget);
      expect(repo.draftWrites, isEmpty);

      await tester.tap(find.text('NOT NOW'));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('SAVE DRAFT'));
      expect(find.text('Sign in to publish guides'), findsOneWidget);
      expect(repo.draftWrites, isEmpty);
    });
  });
}
