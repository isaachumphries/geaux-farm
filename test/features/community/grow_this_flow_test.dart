import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/router.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/data/supabase_guide_grow_recorder.dart';
import 'package:geaux_farm/features/community/domain/auth_user.dart';
import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/domain/guide_grow_recorder.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/garden/presentation/guide_project_screen.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_writer.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:go_router/go_router.dart';

import '../../community/fake_auth_repository.dart';
import '../../helpers/app_fonts.dart';
import '../../helpers/app_harness.dart' show onboardedProfile;
import '../../helpers/community_fixtures.dart';
import '../../helpers/file_asset_bundle.dart';
import '../../helpers/fixed_climate.dart';

// The demo's step 10 on the real routes (plan/10 § Demo script): CM-02
// "Grow this guide" → GD-03 with the project and planned plants, then the
// checklist and the plant links (#49).

final _guide = testGuide(
  'g1',
  title: 'Fall greens for Louisiana',
  materials: const [
    GuideMaterial(name: 'Raised bed', qty: '1', estCostUsd: 60),
    GuideMaterial(name: 'Compost', qty: '2 bags'),
  ],
  steps: const [GuideStep(title: 'Fill the bed', body: 'Mix compost in.')],
  plantIds: const ['kale', 'collard-greens', 'not-a-plant'],
);

class _Recorder implements GuideGrowRecorder {
  final calls = <String>[];

  @override
  Future<void> recordGrow(String guideId) async => calls.add(guideId);
}

void main() {
  late AppDatabase db;
  late _Recorder recorder;

  setUpAll(loadAppFonts);

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    recorder = _Recorder();
  });

  // Not awaited: after a failed expect the tree may still hold Drift
  // streams, and waiting on close() there would hang instead of failing.
  tearDown(() {
    db.close();
  });

  /// Lets Drift's real futures finish, then draws the result.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<GoRouter> pump(WidgetTester tester, {FakeAuthRepository? auth}) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(
      () => ProfileWriter(db).save(onboardedProfile, defaultSpace),
    );
    late GoRouter router;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          fileAssetBundleOverride(),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 21, 9)),
          climateProvider.overrideWith(FixedClimate.new),
          guideRepositoryProvider.overrideWithValue(
            FakeGuideRepository(guides: {'g1': _guide}),
          ),
          authRepositoryProvider.overrideWithValue(
            auth ?? FakeAuthRepository(),
          ),
          guideGrowRecorderProvider.overrideWithValue(recorder),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.watch(goRouterProvider);
            return MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await settle(tester);
    router.go('/community/guide/g1');
    await settle(tester);
    return router;
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  Future<void> tapGrow(WidgetTester tester) async {
    await tester.tap(find.text('GROW THIS GUIDE'));
    await settle(tester);
    expect(
      find.byType(GuideProjectScreen),
      findsOneWidget,
      reason: 'Grow this opens GD-03',
    );
  }

  testWidgets('signed out: Grow this opens GD-03 with no sign-in prompt', (
    tester,
  ) async {
    final router = await pump(tester);
    await tapGrow(tester);

    final projects = await tester.runAsync(
      () => db.select(db.guideProjectsTable).get(),
    );
    expect(projects, hasLength(1));
    final id = projects!.single.id;
    expect(router.state.uri.path, '/garden/project/$id');
    expect(find.byType(GuideProjectScreen), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    expect(recorder.calls, isEmpty);

    expect(find.text('Fall greens for Louisiana'), findsOneWidget);
    expect(find.text('Raised bed'), findsOneWidget);
    expect(find.text('\$60'), findsOneWidget);
    expect(find.text('2 bags'), findsOneWidget);
    expect(find.text('1. Fill the bed'), findsOneWidget);
    expect(find.text('Kale'), findsOneWidget);
    expect(find.text('Collard Greens'), findsOneWidget);

    final plantings = await tester.runAsync(
      () => db.select(db.plantingsTable).get(),
    );
    expect(plantings!.map((p) => p.status).toSet(), {PlantingStatus.planned});
    await unmount(tester);
  });

  testWidgets('signed in: the grow is counted once', (tester) async {
    await pump(
      tester,
      auth: FakeAuthRepository(
        user: const AuthUser(
          id: 'u1',
          email: 'isaac@example.com',
          username: 'isaac',
        ),
      ),
    );
    await tapGrow(tester);
    expect(recorder.calls, ['g1']);
    await unmount(tester);
  });

  testWidgets('back on CM-02 the button reads Growing and reopens GD-03', (
    tester,
  ) async {
    final router = await pump(tester);
    await tapGrow(tester);
    final projectPath = router.state.uri.path;

    router.go('/community/guide/g1');
    await settle(tester);
    expect(find.text('GROWING · OPEN PROJECT'), findsOneWidget);
    expect(find.text('GROW THIS GUIDE'), findsNothing);

    await tester.tap(find.text('GROWING · OPEN PROJECT'));
    await settle(tester);
    expect(router.state.uri.path, projectPath);
    final projects = await tester.runAsync(
      () => db.select(db.guideProjectsTable).get(),
    );
    expect(projects, hasLength(1));
    await unmount(tester);
  });

  testWidgets('a ticked item is saved and survives a rebuild', (tester) async {
    await pump(tester);
    await tapGrow(tester);

    await tester.tap(find.text('Compost'));
    await tester.tap(find.text('1. Fill the bed'));
    await settle(tester);

    final row = (await tester.runAsync(
      () => db.select(db.guideProjectsTable).getSingle(),
    ))!;
    expect(row.materialsJson, contains('"checked":true'));
    expect(row.stepsJson, contains('"done":true'));

    // A new scope over the same database: the app restarted.
    await unmount(tester);
    final router = await pump(tester);
    router.go('/garden/project/${row.id}');
    await settle(tester);
    final boxes = tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .map((c) => c.value)
        .toList();
    expect(boxes, [false, true, true]);
    await unmount(tester);
  });

  testWidgets('a linked plant opens GD-02 for that planting', (tester) async {
    final router = await pump(tester);
    await tapGrow(tester);

    final kale = (await tester.runAsync(
      () => (db.select(
        db.plantingsTable,
      )..where((t) => t.plantId.equals('kale'))).getSingle(),
    ))!;
    await tester.tap(find.text('Kale'));
    await settle(tester);
    expect(router.state.uri.path, '/garden/planting/${kale.id}');
    await unmount(tester);
  });
}
