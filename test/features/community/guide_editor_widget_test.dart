import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/community/application/guide_editor_provider.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/data/supabase_guide_repository.dart'
    show GuideWriteRejectedException;
import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/domain/guide_repository.dart';
import 'package:geaux_farm/features/community/domain/guide_validation.dart';
import 'package:geaux_farm/features/community/presentation/editor/basics_step_screen.dart';
import 'package:geaux_farm/features/community/presentation/editor/editor_copy.dart';
import 'package:geaux_farm/features/community/presentation/editor/guide_editor_screen.dart';
import 'package:geaux_farm/features/community/presentation/editor/materials_step_screen.dart';
import 'package:geaux_farm/features/community/presentation/editor/plants_step_screen.dart';
import 'package:geaux_farm/features/community/presentation/editor/preview_step_screen.dart';
import 'package:geaux_farm/features/community/presentation/editor/steps_step_screen.dart';
import 'package:geaux_farm/features/community/presentation/sign_in_sheet.dart';
import 'package:go_router/go_router.dart';

import '../../community/fake_auth_repository.dart';
import '../../community/guide_detail_harness.dart'
    show settle, signedInUser, unmount;
import '../../helpers/app_fonts.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/community_fixtures.dart';

/// Tall enough that a step with a few rows needs no scrolling.
const _tall = 2400.0;

/// A saved draft with something in every field.
const _guide = GuideDraft(
  id: 'g1',
  title: 'Bucket tomatoes',
  summary: 'Two buckets on a balcony.',
  difficulty: 2,
  spaceTypes: ['balcony'],
  estCostUsd: 35,
  setupMinutes: 90,
  materials: [
    GuideMaterial(
      name: 'Bucket',
      qty: '2',
      estCostUsd: 8,
      url: 'https://example.com/bucket',
    ),
    GuideMaterial(name: 'Potting mix', qty: '1 bag'),
  ],
  steps: [
    GuideStep(
      title: 'Drill holes',
      body: 'Six holes in the base.',
      imagePath: 'u1/g1/a.jpg',
    ),
    GuideStep(title: 'Fill and plant', body: 'Mix and plant.'),
  ],
  plantIds: ['cherry-tomato'],
  tags: ['containers', 'budget'],
);

FakeGuideRepository _repoWith([GuideDraft draft = _guide]) =>
    FakeGuideRepository(
      drafts: {draft.id!: (draft: draft, status: GuideStatus.draft)},
    );

/// A repository whose [fetchDraft] waits for [gate].
class _GatedRepository extends FakeGuideRepository {
  _GatedRepository(this.gate, {super.drafts});

  final Completer<void> gate;

  @override
  Future<EditableGuide> fetchDraft(String id) async {
    await gate.future;
    return super.fetchDraft(id);
  }
}

/// Pumps the app at 360 wide on a stand-in for the feed, then opens the
/// editor for [id] on top of it, as CM-01's "+" and CM-02's Edit do.
Future<GoRouter> _openEditor(
  WidgetTester tester, {
  FakeGuideRepository? repo,
  FakeAuthRepository? auth,
  String id = newGuideRouteId,
  double height = 800,
}) async {
  tester.view.physicalSize = Size(360, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('feed')),
      GoRoute(
        path: '/community/editor/:id',
        builder: (_, state) =>
            GuideEditorScreen(guideId: state.pathParameters['id']!),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...appOverrides(profile: onboardedProfile),
        guideRepositoryProvider.overrideWithValue(
          repo ?? FakeGuideRepository(),
        ),
        authRepositoryProvider.overrideWithValue(
          auth ?? FakeAuthRepository(user: signedInUser),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await settle(tester);
  unawaited(router.push('/community/editor/$id'));
  await settle(tester);
  return router;
}

Finder _field(String key) => find.byKey(ValueKey(key));

/// What is typed in the [index]th field with this [key].
String _typed(WidgetTester tester, String key, [int index = 0]) {
  final editable = find.descendant(
    of: _field(key).at(index),
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editable).controller.text;
}

Future<void> _enter(
  WidgetTester tester,
  String key,
  String text, [
  int index = 0,
]) async {
  await tester.enterText(_field(key).at(index), text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pump();
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.text('NEXT'));
  await settle(tester);
}

Future<void> _tapBack(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Back'));
  await settle(tester);
}

/// The editor's own state for guide [id], read from the running app.
GuideEditorState _state(WidgetTester tester, [String id = newGuideRouteId]) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(guideEditorProvider(id));

GuideDraft _draft(WidgetTester tester, [String id = newGuideRouteId]) =>
    _state(tester, id).draft;

GuideEditorNotifier _notifier(
  WidgetTester tester, [
  String id = newGuideRouteId,
]) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(guideEditorProvider(id).notifier);

/// What the Publish button on Preview does, without Preview.
Future<void> _publish(WidgetTester tester) async {
  unawaited(_notifier(tester).publish());
  await settle(tester);
}

/// What the Save draft button on Preview does, without Preview.
Future<void> _saveDraft(WidgetTester tester) async {
  unawaited(_notifier(tester).saveDraft());
  await settle(tester);
}

GeauxStepProgress _progress(WidgetTester tester) =>
    tester.widget<GeauxStepProgress>(find.byType(GeauxStepProgress));

bool _picked(WidgetTester tester, String label) => tester
    .widget<GeauxSelectCard>(find.widgetWithText(GeauxSelectCard, label))
    .selected;

/// Walks the sign-in sheet for an email whose account has a profile.
Future<void> _signIn(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'isaac@example.com');
  await tester.pump();
  await tester.tap(find.text('SEND CODE'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '481926');
  await tester.pump();
  await tester.tap(find.text('VERIFY'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('moving between steps', () {
    testWidgets(
      'Next walks the five steps and Back returns with the title and summary '
      'kept',
      (tester) async {
        await _openEditor(tester);
        expect(find.byType(BasicsStepScreen), findsOneWidget);
        await _enter(tester, 'guide-title', 'Bucket tomatoes');
        await _enter(tester, 'guide-summary', 'Two buckets on a balcony.');

        const forward = <Type>[
          MaterialsStepScreen,
          StepsStepScreen,
          PlantsStepScreen,
          PreviewStepScreen,
        ];
        for (final (i, screen) in forward.indexed) {
          await _tapNext(tester);
          expect(find.byType(screen), findsOneWidget, reason: '$screen');
          expect(_progress(tester).current, i + 1);
        }
        // Preview ends the walk: its own buttons take over from Next.
        expect(find.text('NEXT'), findsNothing);

        const backward = <Type>[
          PlantsStepScreen,
          StepsStepScreen,
          MaterialsStepScreen,
          BasicsStepScreen,
        ];
        for (final screen in backward) {
          await _tapBack(tester);
          expect(find.byType(screen), findsOneWidget, reason: '$screen');
        }
        expect(_progress(tester).current, 0);
        expect(_typed(tester, 'guide-title'), 'Bucket tomatoes');
        expect(_typed(tester, 'guide-summary'), 'Two buckets on a balcony.');
        expect(_draft(tester).title, 'Bucket tomatoes');
        await unmount(tester);
      },
    );

    testWidgets('Back on Basics leaves the editor', (tester) async {
      await _openEditor(tester);

      await _tapBack(tester);

      expect(find.byType(GuideEditorScreen), findsNothing);
      expect(find.text('feed'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('the device back button steps back, and leaves from Basics', (
      tester,
    ) async {
      await _openEditor(tester);
      await _tapNext(tester);
      expect(find.byType(MaterialsStepScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.byType(BasicsStepScreen), findsOneWidget);
      expect(find.text('feed'), findsNothing);

      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.byType(GuideEditorScreen), findsNothing);
      expect(find.text('feed'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('Preview sends the author to the step they ask to edit', (
      tester,
    ) async {
      await _openEditor(tester);
      for (var i = 0; i < 4; i++) {
        await _tapNext(tester);
      }
      expect(find.byType(PreviewStepScreen), findsOneWidget);

      tester
          .widget<PreviewStepScreen>(find.byType(PreviewStepScreen))
          .onEditStep(EditorStep.materials);
      await settle(tester);

      expect(find.byType(MaterialsStepScreen), findsOneWidget);
      expect(_progress(tester).current, EditorStep.materials.index);
      await unmount(tester);
    });
  });

  group('signed out', () {
    testWidgets('CM-04 comes first: no field is shown and nothing is read', (
      tester,
    ) async {
      final repo = _repoWith();
      await _openEditor(
        tester,
        repo: repo,
        auth: FakeAuthRepository(),
        id: 'g1',
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignInSheet), findsOneWidget);
      expect(find.text('Sign in to publish guides'), findsOneWidget);
      expect(find.byType(BasicsStepScreen), findsNothing);
      expect(find.byType(GeauxStepProgress), findsNothing);
      expect(repo.draftFetches, isEmpty);
      await unmount(tester);
    });

    testWidgets('closing the sheet closes the editor', (tester) async {
      await _openEditor(tester, auth: FakeAuthRepository());
      await tester.pumpAndSettle();

      await tester.tap(find.text('NOT NOW'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInSheet), findsNothing);
      expect(find.byType(GuideEditorScreen), findsNothing);
      expect(find.text('feed'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('signing in opens the editor and only then reads the guide', (
      tester,
    ) async {
      final repo = _repoWith();
      final auth = FakeAuthRepository()..verifiedHasProfile = true;
      await _openEditor(tester, repo: repo, auth: auth, id: 'g1');
      await tester.pumpAndSettle();
      expect(repo.draftFetches, isEmpty);

      await _signIn(tester);

      expect(find.byType(SignInSheet), findsNothing);
      expect(find.byType(BasicsStepScreen), findsOneWidget);
      expect(repo.draftFetches, ['g1']);
      expect(_typed(tester, 'guide-title'), 'Bucket tomatoes');
      await unmount(tester);
    });
  });

  group('an existing guide', () {
    testWidgets('opens with its own values in every Basics field', (
      tester,
    ) async {
      final repo = _repoWith();
      await _openEditor(tester, repo: repo, id: 'g1', height: _tall);

      expect(repo.draftFetches, ['g1']);
      expect(_typed(tester, 'guide-title'), 'Bucket tomatoes');
      expect(_typed(tester, 'guide-summary'), 'Two buckets on a balcony.');
      expect(_typed(tester, 'guide-cost'), '35');
      expect(_typed(tester, 'guide-setup'), '90');
      expect(
        tester
            .widget<GeauxSegmentedChoice<int?>>(
              find.byType(GeauxSegmentedChoice<int?>),
            )
            .selected,
        2,
      );
      expect(_picked(tester, 'Balcony'), isTrue);
      expect(_picked(tester, 'Windowsill'), isFalse);
      expect(find.text('Optional. Pick up to 5. 2 of 5 picked.'), findsOne);
      await unmount(tester);
    });

    testWidgets('shows a spinner and no field until it is read', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _GatedRepository(gate, drafts: _repoWith().drafts);
      await _openEditor(tester, repo: repo, id: 'g1');

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(BasicsStepScreen), findsNothing);
      expect(find.text('NEXT'), findsNothing);

      gate.complete();
      await settle(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_typed(tester, 'guide-title'), 'Bucket tomatoes');
      expect(find.text('NEXT'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a failed read offers Retry, which reads again', (
      tester,
    ) async {
      final repo = _repoWith()..failFetch = true;
      await _openEditor(tester, repo: repo, id: 'g1');

      expect(find.text("Couldn't load this guide."), findsOneWidget);
      expect(find.byType(BasicsStepScreen), findsNothing);
      expect(find.text('NEXT'), findsNothing);

      repo.failFetch = false;
      await tester.tap(find.text('RETRY'));
      await settle(tester);

      expect(find.text("Couldn't load this guide."), findsNothing);
      expect(_typed(tester, 'guide-title'), 'Bucket tomatoes');
      expect(repo.draftFetches, ['g1', 'g1']);
      await unmount(tester);
    });

    testWidgets('a guide that is not there says so, with no Retry', (
      tester,
    ) async {
      await _openEditor(tester, id: 'missing');

      expect(find.text("This guide isn't available."), findsOneWidget);
      expect(find.text('RETRY'), findsNothing);
      expect(find.byType(BasicsStepScreen), findsNothing);
      await unmount(tester);
    });
  });

  group('Basics', () {
    testWidgets('every control writes to the draft', (tester) async {
      await _openEditor(tester, height: _tall);

      await _enter(tester, 'guide-title', 'Bucket tomatoes');
      await _enter(tester, 'guide-summary', 'Two buckets on a balcony.');
      await _tap(tester, 'Medium');
      await _tap(tester, 'Balcony');
      await _tap(tester, 'Windowsill');
      await _enter(tester, 'guide-cost', '35');
      await _enter(tester, 'guide-setup', '90');
      await _tap(tester, 'Budget');
      await _tap(tester, 'Containers');

      final draft = _draft(tester);
      expect(draft.title, 'Bucket tomatoes');
      expect(draft.summary, 'Two buckets on a balcony.');
      expect(draft.difficulty, 2);
      // Both lists keep the picker's order, not the order of the taps.
      expect(draft.spaceTypes, ['windowsill', 'balcony']);
      expect(draft.tags, ['containers', 'budget']);
      expect(draft.estCostUsd, 35);
      expect(draft.setupMinutes, 90);

      await _tap(tester, 'Balcony');
      await _tap(tester, 'Budget');
      expect(_draft(tester).spaceTypes, ['windowsill']);
      expect(_draft(tester).tags, ['containers']);
      await unmount(tester);
    });

    testWidgets('title and summary stop at their limits', (tester) async {
      await _openEditor(tester, height: _tall);

      await _enter(tester, 'guide-title', 'a' * (guideTitleMaxLength + 20));
      await _enter(tester, 'guide-summary', 'b' * (guideSummaryMaxLength + 20));

      expect(_typed(tester, 'guide-title'), hasLength(guideTitleMaxLength));
      expect(_draft(tester).title, hasLength(guideTitleMaxLength));
      expect(_typed(tester, 'guide-summary'), hasLength(guideSummaryMaxLength));
      expect(_draft(tester).summary, hasLength(guideSummaryMaxLength));
      await unmount(tester);
    });

    testWidgets('cost and setup take digits, and clearing one clears only it', (
      tester,
    ) async {
      await _openEditor(tester, height: _tall);

      await _enter(tester, 'guide-cost', '12a3.4');
      await _enter(tester, 'guide-setup', '45');

      expect(_typed(tester, 'guide-cost'), '1234');
      expect(_draft(tester).estCostUsd, 1234);
      expect(_draft(tester).setupMinutes, 45);

      await _enter(tester, 'guide-cost', '');

      expect(_draft(tester).estCostUsd, isNull);
      expect(_draft(tester).setupMinutes, 45);

      await _enter(tester, 'guide-setup', '');
      expect(_draft(tester).setupMinutes, isNull);
      await unmount(tester);
    });

    testWidgets('clearing the cost keeps every other field of the draft', (
      tester,
    ) async {
      await _openEditor(tester, repo: _repoWith(), id: 'g1', height: _tall);

      await _enter(tester, 'guide-cost', '');

      final draft = _draft(tester, 'g1');
      expect(draft.estCostUsd, isNull);
      expect(draft.id, 'g1');
      expect(draft.title, 'Bucket tomatoes');
      expect(draft.setupMinutes, 90);
      expect(draft.difficulty, 2);
      expect(draft.spaceTypes, ['balcony']);
      expect(draft.materials, hasLength(2));
      expect(draft.steps, hasLength(2));
      expect(draft.plantIds, ['cherry-tomato']);
      expect(draft.tags, ['containers', 'budget']);
      await unmount(tester);
    });

    testWidgets('at five tags the rest do nothing until one is dropped', (
      tester,
    ) async {
      await _openEditor(tester, height: _tall);
      for (final tag in [
        'Vertical',
        'Containers',
        'Raised bed',
        'Hydroponic',
        'Budget',
      ]) {
        await _tap(tester, tag);
      }
      expect(_draft(tester).tags, hasLength(guideTagsMax));
      expect(find.text('Optional. Pick up to 5. 5 of 5 picked.'), findsOne);

      await _tap(tester, 'Kids');

      expect(_draft(tester).tags, isNot(contains('kids')));
      expect(_draft(tester).tags, hasLength(guideTagsMax));

      await _tap(tester, 'Vertical');
      await _tap(tester, 'Kids');

      expect(_draft(tester).tags, contains('kids'));
      expect(_draft(tester).tags, isNot(contains('vertical')));
      await unmount(tester);
    });
  });

  group('Materials', () {
    testWidgets('adding and removing keeps the text of the others', (
      tester,
    ) async {
      await _openEditor(tester, height: _tall);
      await _tapNext(tester);
      expect(_field('material-name'), findsNothing);

      for (var i = 0; i < 3; i++) {
        await _tap(tester, 'ADD MATERIAL');
      }
      expect(find.text('Material 3'), findsOneWidget);
      await _enter(tester, 'material-name', 'Pots', 0);
      await _enter(tester, 'material-name', 'Soil', 1);
      await _enter(tester, 'material-qty', '2 bags', 1);
      await _enter(tester, 'material-name', 'Seeds', 2);

      await tester.tap(find.byTooltip('Remove material 1'));
      await tester.pump();

      expect(find.text('Material 3'), findsNothing);
      expect(_typed(tester, 'material-name', 0), 'Soil');
      expect(_typed(tester, 'material-qty', 0), '2 bags');
      expect(_typed(tester, 'material-name', 1), 'Seeds');
      expect(
        [for (final m in _draft(tester).materials) (m.name, m.qty)],
        [('Soil', '2 bags'), ('Seeds', '')],
      );

      await _tap(tester, 'ADD MATERIAL');
      expect(_draft(tester).materials.map((m) => m.name), [
        'Soil',
        'Seeds',
        '',
      ]);
      await unmount(tester);
    });

    testWidgets('the rows come back when the step is opened again', (
      tester,
    ) async {
      await _openEditor(tester, height: _tall);
      await _tapNext(tester);
      await _tap(tester, 'ADD MATERIAL');
      await _enter(tester, 'material-name', 'Pots');
      await _enter(tester, 'material-qty', '4');
      await _enter(tester, 'material-cost', '12');
      await _enter(tester, 'material-url', 'https://example.com/pots');

      await _tapNext(tester);
      await _tapBack(tester);

      expect(find.byType(MaterialsStepScreen), findsOneWidget);
      expect(_typed(tester, 'material-name'), 'Pots');
      expect(_typed(tester, 'material-qty'), '4');
      expect(_typed(tester, 'material-cost'), '12');
      expect(_typed(tester, 'material-url'), 'https://example.com/pots');
      await unmount(tester);
    });

    testWidgets('cost takes digits, and an emptied cost or link is none', (
      tester,
    ) async {
      await _openEditor(tester, repo: _repoWith(), id: 'g1', height: _tall);
      await _tapNext(tester);
      expect(_typed(tester, 'material-name', 0), 'Bucket');
      expect(_typed(tester, 'material-cost', 0), '8');
      expect(_typed(tester, 'material-url', 0), 'https://example.com/bucket');

      await _enter(tester, 'material-cost', '9x', 0);
      expect(_draft(tester, 'g1').materials[0].estCostUsd, 9);

      await _enter(tester, 'material-cost', '', 0);
      await _enter(tester, 'material-url', '  ', 0);

      final first = _draft(tester, 'g1').materials[0];
      expect(first.estCostUsd, isNull);
      expect(first.url, isNull);
      expect(first.name, 'Bucket');
      expect(first.qty, '2');
      expect(_draft(tester, 'g1').materials[1].name, 'Potting mix');
      await unmount(tester);
    });

    testWidgets('Add material stops at the limit until one is removed', (
      tester,
    ) async {
      final full = GuideDraft(
        id: 'g1',
        title: 'Bucket tomatoes',
        materials: [
          for (var i = 1; i <= guideMaterialsMax; i++)
            GuideMaterial(name: 'Item $i', qty: '1'),
        ],
      );
      await _openEditor(tester, repo: _repoWith(full), id: 'g1');
      await _tapNext(tester);

      final add = find.widgetWithText(GeauxButton, 'ADD MATERIAL');
      expect(tester.widget<GeauxButton>(add).onPressed, isNull);

      final remove = find.byTooltip('Remove material $guideMaterialsMax');
      await tester.ensureVisible(remove);
      await tester.pump();
      await tester.tap(remove);
      await tester.pump();

      expect(tester.widget<GeauxButton>(add).onPressed, isNotNull);
      expect(_draft(tester, 'g1').materials, hasLength(guideMaterialsMax - 1));
      await unmount(tester);
    });
  });

  group('Steps', () {
    testWidgets('adding and removing keeps the text of the others', (
      tester,
    ) async {
      await _openEditor(tester, height: _tall);
      await _tapNext(tester);
      await _tapNext(tester);
      expect(find.byType(StepsStepScreen), findsOneWidget);
      expect(_field('step-title'), findsNothing);

      for (var i = 0; i < 3; i++) {
        await _tap(tester, 'ADD STEP');
      }
      expect(find.text('Step 3'), findsOneWidget);
      await _enter(tester, 'step-title', 'Drill', 0);
      await _enter(tester, 'step-title', 'Fill', 1);
      await _enter(tester, 'step-body', 'Fill each bucket.', 1);
      await _enter(tester, 'step-title', 'Plant', 2);

      await tester.tap(find.byTooltip('Remove step 1'));
      await tester.pump();

      expect(find.text('Step 3'), findsNothing);
      expect(_typed(tester, 'step-title', 0), 'Fill');
      expect(_typed(tester, 'step-body', 0), 'Fill each bucket.');
      expect(_typed(tester, 'step-title', 1), 'Plant');
      expect(
        [for (final s in _draft(tester).steps) (s.title, s.body)],
        [('Fill', 'Fill each bucket.'), ('Plant', '')],
      );
      await unmount(tester);
    });

    testWidgets('the rows come back when the step is opened again', (
      tester,
    ) async {
      await _openEditor(tester, height: _tall);
      await _tapNext(tester);
      await _tapNext(tester);
      await _tap(tester, 'ADD STEP');
      await _enter(tester, 'step-title', 'Drill holes');
      await _enter(tester, 'step-body', 'Six holes in the base.');

      await _tapNext(tester);
      await _tapBack(tester);

      expect(find.byType(StepsStepScreen), findsOneWidget);
      expect(_typed(tester, 'step-title'), 'Drill holes');
      expect(_typed(tester, 'step-body'), 'Six holes in the base.');
      await unmount(tester);
    });

    testWidgets('editing a step keeps the photo it already has', (
      tester,
    ) async {
      await _openEditor(tester, repo: _repoWith(), id: 'g1', height: _tall);
      await _tapNext(tester);
      await _tapNext(tester);
      expect(_typed(tester, 'step-title', 0), 'Drill holes');

      await _enter(tester, 'step-title', 'Drill six holes', 0);

      final steps = _draft(tester, 'g1').steps;
      expect(steps[0].title, 'Drill six holes');
      expect(steps[0].imagePath, 'u1/g1/a.jpg');
      expect(steps[1].imagePath, isNull);
      await unmount(tester);
    });

    testWidgets('details stop at the limit', (tester) async {
      await _openEditor(tester, height: _tall);
      await _tapNext(tester);
      await _tapNext(tester);
      await _tap(tester, 'ADD STEP');

      await _enter(tester, 'step-body', 'a' * (guideStepBodyMaxLength + 200));

      expect(_typed(tester, 'step-body'), hasLength(guideStepBodyMaxLength));
      expect(
        _draft(tester).steps.single.body,
        hasLength(guideStepBodyMaxLength),
      );
      await unmount(tester);
    });

    testWidgets('Add step stops at the limit until one is removed', (
      tester,
    ) async {
      final full = GuideDraft(
        id: 'g1',
        title: 'Bucket tomatoes',
        steps: [
          for (var i = 1; i <= guideStepsMax; i++)
            GuideStep(title: 'Step title $i', body: ''),
        ],
      );
      await _openEditor(tester, repo: _repoWith(full), id: 'g1');
      await _tapNext(tester);
      await _tapNext(tester);

      final add = find.widgetWithText(GeauxButton, 'ADD STEP');
      expect(tester.widget<GeauxButton>(add).onPressed, isNull);

      final remove = find.byTooltip('Remove step $guideStepsMax');
      await tester.ensureVisible(remove);
      await tester.pump();
      await tester.tap(remove);
      await tester.pump();

      expect(tester.widget<GeauxButton>(add).onPressed, isNotNull);
      expect(_draft(tester, 'g1').steps, hasLength(guideStepsMax - 1));
      await unmount(tester);
    });
  });

  group('validation errors', () {
    final blocked = validatePublish(const GuideDraft());
    String copy(String field) => guideFieldErrorText(blocked[field]!);

    testWidgets('a blocked publish names each field on its own step', (
      tester,
    ) async {
      await _openEditor(tester, height: _tall);

      await _publish(tester);

      for (final field in [
        GuideField.title,
        GuideField.summary,
        GuideField.difficulty,
        GuideField.spaceTypes,
      ]) {
        expect(find.text(copy(field)), findsOneWidget, reason: field);
      }
      await _tapNext(tester);
      expect(find.text(copy(GuideField.materials)), findsOneWidget);
      await _tapNext(tester);
      expect(find.text(copy(GuideField.steps)), findsOneWidget);

      await _tapBack(tester);
      await _tapBack(tester);
      await _enter(tester, 'guide-title', 'Bucket tomatoes');

      expect(find.text(copy(GuideField.title)), findsNothing);
      await unmount(tester);
    });

    testWidgets('a material without a name is marked until it has one', (
      tester,
    ) async {
      await _openEditor(tester, height: _tall);
      await _tapNext(tester);
      await _tap(tester, 'ADD MATERIAL');

      await _publish(tester);

      final message = guideFieldErrorText(GuideFieldError.materialNameEmpty);
      expect(find.text(message), findsOneWidget);
      expect(
        tester.widget<GeauxTextField>(_field('material-name')).hasError,
        true,
      );

      await _enter(tester, 'material-name', 'Pots');

      expect(find.text(message), findsNothing);
      expect(
        tester.widget<GeauxTextField>(_field('material-name')).hasError,
        false,
      );
      await unmount(tester);
    });

    testWidgets('a step without a title is marked until it has one', (
      tester,
    ) async {
      await _openEditor(tester, height: _tall);
      await _tapNext(tester);
      await _tapNext(tester);
      await _tap(tester, 'ADD STEP');

      await _publish(tester);

      final message = guideFieldErrorText(GuideFieldError.stepTitleEmpty);
      expect(find.text(message), findsOneWidget);
      expect(
        tester.widget<GeauxTextField>(_field('step-title')).hasError,
        true,
      );

      await _enter(tester, 'step-title', 'Drill');

      expect(find.text(message), findsNothing);
      expect(
        tester.widget<GeauxTextField>(_field('step-title')).hasError,
        false,
      );
      await unmount(tester);
    });
  });

  group('a write that fails', () {
    final cases = <(String, Object, String?)>[
      (
        'refused by the server',
        const GuideWriteRejectedException(),
        'This guide can no longer be edited',
      ),
      (
        'offline',
        const NetworkException('offline'),
        "Couldn't save. Check your connection and try again.",
      ),
      ('for any other reason', Exception('boom'), "Couldn't save. Try again."),
      // Preview answers a signed-out write with CM-04, not a banner.
      ('because the session ended', const AuthRequiredException(), null),
    ];
    for (final (name, error, message) in cases) {
      testWidgets('$name: ${message ?? 'no banner'}, and nothing is lost', (
        tester,
      ) async {
        final repo = FakeGuideRepository()..writeError = error;
        await _openEditor(tester, repo: repo, height: _tall);
        await _enter(tester, 'guide-title', 'Bucket tomatoes');
        await _tap(tester, 'Medium');

        await _saveDraft(tester);

        expect(repo.draftWrites, hasLength(1));
        if (message == null) {
          expect(find.byType(GeauxAlertBanner), findsNothing);
        } else {
          expect(find.text(message), findsOneWidget);
          // The banner stays with the author on the next step, and goes at
          // the next edit.
          await _tapNext(tester);
          expect(find.text(message), findsOneWidget);
          await _tap(tester, 'ADD MATERIAL');
          expect(find.text(message), findsNothing);
          await _tapBack(tester);
        }
        expect(_typed(tester, 'guide-title'), 'Bucket tomatoes');
        await unmount(tester);
      });
    }
  });

  group('a new visit', () {
    testWidgets('to a new guide starts with nothing typed', (tester) async {
      final router = await _openEditor(tester);
      await _enter(tester, 'guide-title', 'Bucket tomatoes');
      await _tapNext(tester);
      await _tapBack(tester);
      await _tapBack(tester);
      expect(find.text('feed'), findsOneWidget);

      unawaited(router.push('/community/editor/$newGuideRouteId'));
      await settle(tester);

      expect(find.byType(BasicsStepScreen), findsOneWidget);
      expect(_progress(tester).current, 0);
      expect(_typed(tester, 'guide-title'), isEmpty);
      expect(_draft(tester).title, isEmpty);
      await unmount(tester);
    });

    testWidgets('to an existing guide reads it again', (tester) async {
      final repo = _repoWith();
      final router = await _openEditor(tester, repo: repo, id: 'g1');
      await _enter(tester, 'guide-title', 'Something else');
      await _tapBack(tester);
      expect(find.text('feed'), findsOneWidget);

      unawaited(router.push('/community/editor/g1'));
      await settle(tester);

      expect(_typed(tester, 'guide-title'), 'Bucket tomatoes');
      expect(repo.draftFetches, ['g1', 'g1']);
      await unmount(tester);
    });
  });

  group('screen readers', () {
    testWidgets('every text field is announced under its label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _openEditor(tester, height: _tall);
      void expectLabelled(String key, String label) {
        final node = tester.getSemantics(_field(key));
        expect(node.label, contains(label), reason: key);
      }

      expectLabelled('guide-title', 'Title');
      expectLabelled('guide-summary', 'Summary');
      expectLabelled('guide-cost', 'Est. cost (USD)');
      expectLabelled('guide-setup', 'Setup time (minutes)');

      await _tapNext(tester);
      await _tap(tester, 'ADD MATERIAL');
      expectLabelled('material-name', 'Name');
      expectLabelled('material-qty', 'Quantity');
      expectLabelled('material-cost', 'Est. cost (USD)');
      expectLabelled('material-url', 'Link');

      await _tapNext(tester);
      await _tap(tester, 'ADD STEP');
      expectLabelled('step-title', 'Title');
      expectLabelled('step-body', 'Details');
      handle.dispose();
      await unmount(tester);
    });
  });

  group('at 360x800', () {
    // Every field holds as much as it takes, so this is the widest every
    // step gets: an overflow fails the test as it would show on a phone.
    final longest = GuideDraft(
      id: 'g1',
      title: 'T' * guideTitleMaxLength,
      summary: 'S' * guideSummaryMaxLength,
      difficulty: 3,
      spaceTypes: ['windowsill', 'balcony', 'smallYard', 'largeYard'],
      estCostUsd: 999999,
      setupMinutes: 999999,
      materials: [
        GuideMaterial(
          name: 'M' * 120,
          qty: 'Q' * 40,
          estCostUsd: 999999,
          url: 'https://example.com/${'u' * 120}',
        ),
      ],
      steps: [GuideStep(title: 'T' * 120, body: 'B' * guideStepBodyMaxLength)],
      plantIds: ['cherry-tomato'],
      tags: ['vertical', 'containers', 'raised-bed', 'hydroponic', 'budget'],
    );

    testWidgets('every step fits, with its labels whole', (tester) async {
      await _openEditor(tester, repo: _repoWith(longest), id: 'g1');

      for (final step in EditorStep.values) {
        expect(_progress(tester).current, step.index);
        expect(tester.takeException(), isNull, reason: step.label);
        // A step label under a dot is cut off with an ellipsis when it
        // does not fit its share of the row.
        for (final label in EditorStep.values.map((s) => s.label)) {
          final text = find.descendant(
            of: find.byType(GeauxStepProgress),
            matching: find.text(label),
          );
          expect(
            tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
            isFalse,
            reason: '$label on ${step.label}',
          );
        }
        if (step != EditorStep.preview) await _tapNext(tester);
      }
      await unmount(tester);
    });

    testWidgets('every target is at least 48 square', (tester) async {
      await _openEditor(tester, repo: _repoWith(), id: 'g1');

      void expectTarget(Finder finder, String what) {
        final size = tester.getSize(finder.first);
        expect(
          size.height,
          greaterThanOrEqualTo(AppSpacing.minTouchTarget),
          reason: what,
        );
        expect(
          size.width,
          greaterThanOrEqualTo(AppSpacing.minTouchTarget),
          reason: what,
        );
      }

      expectTarget(find.byTooltip('Back'), 'Back');
      expectTarget(find.widgetWithText(GeauxButton, 'NEXT'), 'Next');
      for (final tag in ['Vertical', 'Raised bed', 'Hydroponic']) {
        await tester.ensureVisible(find.text(tag));
        expectTarget(
          find.ancestor(
            of: find.text(tag),
            matching: find.byType(GestureDetector),
          ),
          'tag $tag',
        );
      }
      await _tapNext(tester);
      expectTarget(find.byTooltip('Remove material 1'), 'Remove material');
      expectTarget(
        find.widgetWithText(GeauxButton, 'ADD MATERIAL'),
        'Add material',
      );
      await _tapNext(tester);
      expectTarget(find.byTooltip('Remove step 1'), 'Remove step');
      expectTarget(find.widgetWithText(GeauxButton, 'ADD STEP'), 'Add step');
      await unmount(tester);
    });
  });
}
