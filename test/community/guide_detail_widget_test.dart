import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/presentation/guide_detail_screen.dart';
import 'package:geaux_farm/features/community/presentation/widgets/guide_detail_skeleton.dart';
import 'package:geaux_farm/features/community/presentation/widgets/stat_button.dart';
import 'package:geaux_farm/features/recommendations/application/recommendations_provider.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/compat_badge.dart';

import '../helpers/app_fonts.dart';
import '../helpers/community_fixtures.dart';
import 'fake_auth_repository.dart';
import 'guide_detail_harness.dart';

const _tall = 2600.0;

Guide _fullGuide({String? forkedFrom}) => testGuide(
  'g1',
  stars: 128,
  grows: 42,
  remixes: 9,
  cost: 35,
  setupMinutes: 120,
  author: 'marisol_grows',
  materials: const [
    GuideMaterial(name: '5-gallon pots with drainage', qty: '4'),
    GuideMaterial(name: 'Potting mix', qty: '2 bags'),
  ],
  steps: const [
    GuideStep(title: 'Fill the pots', body: 'Fill each pot with potting mix.'),
    GuideStep(title: 'Plant the tomato', body: 'Add the cage.'),
  ],
  plantIds: const ['cherry-tomato', 'sweet-basil', 'not-in-the-catalog'],
  forkedFrom: forkedFrom,
);

final _source = testGuide(
  'src',
  title: 'Patio pizza garden',
  author: 'patio_pete',
);

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

/// A repository whose [fetchGuide] waits for [gate].
class _GatedRepository extends FakeGuideRepository {
  _GatedRepository(this.gate, {super.guides});

  final Completer<void> gate;

  @override
  Future<Guide> fetchGuide(String id) async {
    await gate.future;
    return super.fetchGuide(id);
  }
}

void main() {
  setUpAll(loadAppFonts);

  group('layout', () {
    testWidgets('shows the content in the order of plan/07 § Guide detail', (
      tester,
    ) async {
      final repo = FakeGuideRepository(
        guides: {
          'g1': _fullGuide(forkedFrom: 'src'),
          'src': _source,
        },
      );
      await pumpGuideDetail(tester, repo, height: _tall);

      final inOrder = <Finder>[
        find.text('Balcony salsa garden in 4 pots'),
        find.text('@marisol_grows'),
        find.text('Star'),
        find.text('Remix'),
        find.text('Cost'),
        find.text('Setup'),
        find.text('Difficulty'),
        find.text('Materials'),
        find.textContaining('5-gallon pots with drainage'),
        find.text('Steps'),
        find.text('Fill the pots'),
        find.text('Plants in this guide'),
        find.text('Cherry Tomato'),
        find.textContaining('Remixed from'),
      ];
      for (final finder in inOrder) {
        expect(finder, findsAtLeastNWidgets(1), reason: '$finder');
      }
      final tops = [for (final f in inOrder) _top(tester, f)];
      expect(tops, orderedEquals([...tops]..sort()));
      // Cost, Setup and Difficulty share a row, left to right.
      double left(String text) => tester.getTopLeft(find.text(text)).dx;
      expect(left('Cost'), lessThan(left('Setup')));
      expect(left('Setup'), lessThan(left('Difficulty')));
      // Every section starts below the one before it.
      final headings = [
        for (final t in ['Materials', 'Steps', 'Plants in this guide'])
          _top(tester, find.text(t)),
      ];
      expect(headings, orderedEquals([...headings]..sort()));
      expect(headings.toSet(), hasLength(3));
      // Star, Grow this and Remix come in that order.
      expect(
        _top(tester, find.text('Star')),
        lessThanOrEqualTo(_top(tester, find.text('Grow this'))),
      );
      expect(
        _top(tester, find.text('Grow this')),
        lessThanOrEqualTo(_top(tester, find.text('Remix'))),
      );
      await unmount(tester);
    });

    testWidgets('the three stat buttons carry the counts of the guide', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()});
      await pumpGuideDetail(tester, repo, height: _tall);

      Finder count(String label, String text) => find.descendant(
        of: find.widgetWithText(StatButton, label),
        matching: find.text(text),
      );
      expect(count('Star', '128'), findsOneWidget);
      expect(count('Grow this', '42 growing'), findsOneWidget);
      expect(count('Remix', '9'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('cost, setup time and difficulty read as plan/07 says', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()});
      await pumpGuideDetail(tester, repo, height: _tall);

      expect(find.text('\$35'), findsOneWidget);
      expect(find.text('~2 hours'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('steps are numbered in order', (tester) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()});
      await pumpGuideDetail(tester, repo, height: _tall);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(
        _top(tester, find.text('Fill the pots')),
        lessThan(_top(tester, find.text('Plant the tomato'))),
      );
      await unmount(tester);
    });

    testWidgets('a guide without materials, steps or plants has no sections', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': testGuide('g1')});
      await pumpGuideDetail(tester, repo, height: _tall);

      expect(find.text('Materials'), findsNothing);
      expect(find.text('Steps'), findsNothing);
      expect(find.text('Plants in this guide'), findsNothing);
      await unmount(tester);
    });
  });

  group('Plants in this guide', () {
    testWidgets('each plant shows the compat badge scorePlant gives it', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()});
      await pumpGuideDetail(tester, repo, height: _tall);

      final scored = ProviderScope.containerOf(
        tester.element(find.byType(GuideDetailScreen)),
      ).read(recommendationsProvider).requireValue;
      int score(String id) =>
          scored.firstWhere((s) => s.plant.id == id).compatibility.score;

      final badges = tester
          .widgetList<CompatBadge>(find.byType(CompatBadge))
          .map((b) => b.score)
          .toList();
      expect(badges, [score('cherry-tomato'), score('sweet-basil')]);
      expect(find.text('Cherry Tomato'), findsOneWidget);
      expect(find.text('Sweet Basil'), findsOneWidget);
      // The id that is not in the catalog is skipped, like Grow this does.
      expect(find.byType(CompatBadge), findsNWidgets(2));
      await unmount(tester);
    });

    testWidgets('tapping a plant opens its detail', (tester) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()});
      await pumpGuideDetail(tester, repo, height: _tall);

      await tester.tap(find.text('Sweet Basil'));
      await tester.pumpAndSettle();

      expect(find.text('plant sweet-basil'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('Remixed from', () {
    testWidgets('shows only when forked_from is set, and opens the original', (
      tester,
    ) async {
      final repo = FakeGuideRepository(
        guides: {
          'g1': _fullGuide(forkedFrom: 'src'),
          'src': _source,
        },
      );
      await pumpGuideDetail(tester, repo, height: _tall);

      final link = find.text('Remixed from Patio pizza garden by @patio_pete');
      expect(link, findsOneWidget);
      expect(find.text('Patio pizza garden'), findsNothing);
      await tester.tap(link);
      await settle(tester);
      // The original is open: its title is the heading now.
      expect(find.text('Patio pizza garden'), findsOneWidget);
      expect(find.text('@patio_pete'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('is absent for a guide that is not a remix', (tester) async {
      final repo = FakeGuideRepository(
        guides: {'g1': _fullGuide(), 'src': _source},
      );
      await pumpGuideDetail(tester, repo, height: _tall);

      expect(find.textContaining('Remixed from'), findsNothing);
      expect(repo.guideFetches, ['g1']);
      await unmount(tester);
    });

    testWidgets('is left out when the original cannot be read', (tester) async {
      final repo = FakeGuideRepository(
        guides: {'g1': _fullGuide(forkedFrom: 'gone')},
      );
      await pumpGuideDetail(tester, repo, height: _tall);

      expect(find.textContaining('Remixed from'), findsNothing);
      // The rest of the guide is still there.
      expect(find.text('Materials'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('states', () {
    testWidgets('loading: a skeleton until the guide arrives', (tester) async {
      final gate = Completer<void>();
      final repo = _GatedRepository(gate, guides: {'g1': _fullGuide()});
      await pumpGuideDetail(tester, repo);

      expect(find.byType(GuideDetailSkeleton), findsOneWidget);
      expect(find.text('Balcony salsa garden in 4 pots'), findsNothing);
      expect(find.byType(StatButton), findsNothing);

      gate.complete();
      await settle(tester);
      expect(find.byType(GuideDetailSkeleton), findsNothing);
      expect(find.text('Balcony salsa garden in 4 pots'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('error: a message with Retry that loads the guide again', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()})
        ..failFetch = true;
      await pumpGuideDetail(tester, repo);

      expect(find.text("Couldn't load this guide."), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
      expect(find.byType(StatButton), findsNothing);

      repo.failFetch = false;
      await tester.tap(find.text('RETRY'));
      await settle(tester);

      expect(find.text("Couldn't load this guide."), findsNothing);
      expect(find.text('Balcony salsa garden in 4 pots'), findsOneWidget);
      expect(repo.guideFetches, ['g1', 'g1']);
      await unmount(tester);
    });

    testWidgets('a guide that does not exist says so, without Retry', (
      tester,
    ) async {
      await pumpGuideDetail(tester, FakeGuideRepository(), id: 'nope');

      expect(find.text("This guide isn't available."), findsOneWidget);
      expect(find.text('RETRY'), findsNothing);
      await unmount(tester);
    });

    testWidgets('starred: the star pill is selected with the count shown', (
      tester,
    ) async {
      final repo = FakeGuideRepository(
        guides: {'g1': _fullGuide()},
        starred: {'g1'},
      );
      await pumpGuideDetail(
        tester,
        repo,
        auth: FakeAuthRepository(user: signedInUser),
      );

      final star = tester.widget<StatButton>(find.byType(StatButton).first);
      expect(star.selected, isTrue);
      expect(star.label, 'Starred');
      expect(star.count, 128);
      await unmount(tester);
    });

    testWidgets('not starred: the star pill is not selected', (tester) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()});
      await pumpGuideDetail(tester, repo);

      final star = tester.widget<StatButton>(find.byType(StatButton).first);
      expect(star.selected, isFalse);
      expect(star.label, 'Star');
      await unmount(tester);
    });

    testWidgets('growing: the bar reads Growing and opens the project', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()});
      await pumpGuideDetail(tester, repo, growing: {'g1': 'p1'});

      expect(find.text('GROWING · OPEN PROJECT'), findsOneWidget);
      expect(find.text('GROW THIS GUIDE'), findsNothing);

      await tester.tap(find.text('GROWING · OPEN PROJECT'));
      await tester.pumpAndSettle();
      expect(find.text('project p1'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('growing another guide does not mark this one', (tester) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()});
      await pumpGuideDetail(tester, repo, growing: {'other': 'p9'});

      expect(find.text('GROW THIS GUIDE'), findsOneWidget);
      expect(find.text('GROWING · OPEN PROJECT'), findsNothing);
      await unmount(tester);
    });

    testWidgets('not growing: the bar offers Grow this and calls onGrow', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()});
      var grown = 0;
      await pumpGuideDetail(tester, repo, onGrow: () => grown++);

      await tester.tap(find.text('GROW THIS GUIDE'));
      await tester.tap(find.text('Grow this'));
      await tester.pump();

      expect(grown, 2);
      await unmount(tester);
    });

    testWidgets('without a Grow this flow the bar is disabled', (tester) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()});
      await pumpGuideDetail(tester, repo);

      final bar = tester.widget<GeauxButton>(
        find.byWidgetPredicate(
          (w) => w is GeauxButton && w.label == 'Grow this guide',
        ),
      );
      expect(bar.onPressed, isNull);
      await unmount(tester);
    });
  });

  group('overflow menu', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
    }

    testWidgets("others' guides offer Report only", (tester) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()});
      var reported = 0;
      await pumpGuideDetail(
        tester,
        repo,
        auth: FakeAuthRepository(user: signedInUser),
        onReport: () => reported++,
      );
      await openMenu(tester);

      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);

      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(reported, 1);
      await unmount(tester);
    });

    testWidgets('your own guide offers Edit and Delete, not Report', (
      tester,
    ) async {
      final repo = FakeGuideRepository(guides: {'g1': _fullGuide()});
      final auth = FakeAuthRepository(
        user: signedInUser.copyForAuthor('author-marisol_grows'),
      );
      await pumpGuideDetail(tester, repo, auth: auth);
      await openMenu(tester);

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Report'), findsNothing);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('editor g1'), findsOneWidget);
      await unmount(tester);
    });
  });
}
