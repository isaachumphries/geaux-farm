import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/catalog/data/catalog_repository.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/community/application/guide_grower.dart';
import 'package:geaux_farm/features/community/data/supabase_guide_grow_recorder.dart';
import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/domain/guide_grow_recorder.dart';
import 'package:geaux_farm/features/garden/data/guide_project_repository.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:http/http.dart' as http;

import '../../helpers/community_fixtures.dart';
import '../../helpers/file_asset_bundle.dart';

// plan/07 § Grow this, steps 1–3, and plan/05 § Grow this flow (setup
// default), over an in-memory Drift and a fake Supabase.

final _now = DateTime(2026, 10, 21, 9);

Space _space(SpaceType type, {bool container = false}) => Space(
  id: 'space-1',
  type: type,
  areaSqFt: 20,
  sun: SunLevel.full,
  rainExposed: true,
  inContainerDefault: container,
);

final _guide = testGuide(
  'g1',
  title: 'Fall greens for Louisiana',
  coverPath: 'author/cover.jpg',
  materials: const [
    GuideMaterial(name: 'Raised bed', qty: '1', estCostUsd: 60),
    GuideMaterial(name: 'Compost', qty: '2 bags'),
  ],
  steps: const [
    GuideStep(title: 'Fill the bed', body: 'Mix compost in.'),
    GuideStep(title: 'Sow', body: 'Seeds 1/4 inch deep.'),
  ],
  plantIds: const ['kale', 'collard-greens', 'swiss-chard', 'not-a-plant'],
);

class _RecordingRecorder implements GuideGrowRecorder {
  final calls = <String>[];
  Object? error;

  @override
  Future<void> recordGrow(String guideId) async {
    calls.add(guideId);
    if (error != null) throw error!;
  }
}

void main() {
  late AppDatabase db;
  late List<Plant> catalog;
  late GuideProjectRepository projects;

  setUpAll(() async {
    catalog = await loadPlants(FileAssetBundle());
  });

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    projects = GuideProjectRepository(db, now: () => _now, random: Random(1));
  });

  tearDown(() => db.close());

  Future<String> grow(Guide guide, {SpaceType type = SpaceType.balcony}) =>
      projects.createFromGuide(
        guide: guide,
        coverUrl: 'https://cdn.test/cover.jpg',
        catalog: catalog,
        space: _space(type),
      );

  group('step 1: the guide_projects snapshot', () {
    test('copies title and cover; nothing checked or done', () async {
      final id = await grow(_guide);
      final rows = await db.select(db.guideProjectsTable).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.id, id);
      expect(row.guideId, 'g1');
      expect(row.title, 'Fall greens for Louisiana');
      expect(row.coverUrl, 'https://cdn.test/cover.jpg');
      expect(row.createdAt, _now);
      expect(jsonDecode(row.materialsJson), [
        {
          'name': 'Raised bed',
          'qty': '1',
          'est_cost_usd': 60,
          'checked': false,
        },
        {
          'name': 'Compost',
          'qty': '2 bags',
          'est_cost_usd': null,
          'checked': false,
        },
      ]);
      expect(jsonDecode(row.stepsJson), [
        {'title': 'Fill the bed', 'body': 'Mix compost in.', 'done': false},
        {'title': 'Sow', 'body': 'Seeds 1/4 inch deep.', 'done': false},
      ]);
    });

    test('each tap makes exactly one new project', () async {
      final a = await grow(_guide);
      final b = await grow(_guide);
      expect(a, isNot(b));
      expect(await db.select(db.guideProjectsTable).get(), hasLength(2));
    });
  });

  group('step 2: planned plantings', () {
    test('3 catalog ids and 1 unknown give 3 planned plantings', () async {
      final id = await grow(_guide);
      final rows = await db.select(db.plantingsTable).get();
      expect(rows.map((r) => r.plantId), [
        'kale',
        'collard-greens',
        'swiss-chard',
      ]);
      for (final r in rows) {
        expect(r.status, PlantingStatus.planned);
        expect(r.plantedOn, isNull);
        expect(r.projectId, id);
        expect(r.spaceId, 'space-1');
      }
      final kale = rows.first;
      expect(kale.nickname, 'Kale');
      expect(kale.startMethod, 'transplant', reason: 'the first start');
    });

    test('plant_ids = [] gives no plantings', () async {
      await grow(testGuide('g2', plantIds: const []));
      expect(await db.select(db.plantingsTable).get(), isEmpty);
      expect(await db.select(db.guideProjectsTable).get(), hasLength(1));
    });

    test('a repeated id still gives one planting', () async {
      await grow(testGuide('g3', plantIds: const ['kale', 'kale']));
      expect(await db.select(db.plantingsTable).get(), hasLength(1));
    });

    for (final (type, setup) in [
      (SpaceType.windowsill, GrowSetup.indoor),
      (SpaceType.balcony, GrowSetup.outdoor),
      (SpaceType.smallYard, GrowSetup.outdoor),
    ]) {
      test('${type.name} space → ${setup.name}', () async {
        await grow(testGuide('g4', plantIds: const ['kale']), type: type);
        final row = await db.select(db.plantingsTable).getSingle();
        expect(row.setup, setup);
      });
    }
  });

  group('GD-03 checklists', () {
    test('ticks persist and read back from a fresh repository', () async {
      final id = await grow(_guide);
      await projects.setMaterialChecked(id, 1, true);
      await projects.setStepDone(id, 0, true);

      final reread = GuideProjectRepository(db, now: () => _now);
      final project = (await reread.watchProject(id).first)!;
      expect(project.materials.map((m) => m.checked), [false, true]);
      expect(project.steps.map((s) => s.done), [true, false]);

      await projects.setMaterialChecked(id, 1, false);
      final cleared = (await reread.watchProject(id).first)!;
      expect(cleared.materials.map((m) => m.checked), [false, false]);
    });

    test('an unknown project id reads as null', () async {
      expect(await projects.watchProject('nope').first, isNull);
    });
  });

  group('step 3 and the whole action (GuideGrower)', () {
    late _RecordingRecorder recorder;
    late GuideGrower grower;

    setUp(() {
      recorder = _RecordingRecorder();
      grower = GuideGrower(
        projects: projects,
        recorder: recorder,
        coverUrl: (path) => 'https://cdn.test/$path',
      );
    });

    Future<String?> run({required bool signedIn}) => grower.grow(
      guide: _guide,
      catalog: catalog,
      space: _space(SpaceType.balcony),
      signedIn: signedIn,
    );

    test('signed out: a project, and no Supabase call', () async {
      final id = await run(signedIn: false);
      expect(id, isNotNull);
      expect(recorder.calls, isEmpty);
      final row = await db.select(db.guideProjectsTable).getSingle();
      expect(row.coverUrl, 'https://cdn.test/author/cover.jpg');
    });

    test('signed in: one guide_grows insert', () async {
      await run(signedIn: true);
      expect(recorder.calls, ['g1']);
    });

    test('a failed count still returns the saved project', () async {
      recorder.error = const NetworkException('offline');
      final id = await run(signedIn: true);
      expect(id, isNotNull);
      expect(await db.select(db.guideProjectsTable).get(), hasLength(1));
    });

    test('a second tap while the first runs makes nothing', () async {
      final first = run(signedIn: false);
      final second = run(signedIn: false);
      expect(await second, isNull);
      expect(await first, isNotNull);
      expect(await db.select(db.guideProjectsTable).get(), hasLength(1));
    });
  });

  group('SupabaseGuideGrowRecorder', () {
    ({SupabaseGuideGrowRecorder recorder, List<Object?> inserts}) server({
      String? userId = 'u1',
      int status = 201,
    }) {
      final inserts = <Object?>[];
      final client = mockSupabase((request) async {
        if (request.url.path.endsWith('/guide_grows')) {
          final body = jsonDecode(request.body);
          inserts.add(body is List ? body.single : body);
          if (status == 409) {
            return http.Response(
              jsonEncode({'code': '23505', 'message': 'duplicate key'}),
              409,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          if (status >= 400) {
            return http.Response(
              jsonEncode({'code': '42501', 'message': 'denied'}),
              status,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
        }
        return http.Response('[]', status, request: request);
      });
      return (
        recorder: SupabaseGuideGrowRecorder(
          client,
          currentUserId: () => userId,
        ),
        inserts: inserts,
      );
    }

    test('inserts one row for the signed-in user', () async {
      final s = server();
      await s.recorder.recordGrow('g1');
      expect(s.inserts, [
        {'user_id': 'u1', 'guide_id': 'g1'},
      ]);
    });

    test('a unique violation (23505) is success', () async {
      final s = server(status: 409);
      await s.recorder.recordGrow('g1');
      expect(s.inserts, hasLength(1));
    });

    test('any other rejection is rethrown', () async {
      final s = server(status: 403);
      await expectLater(s.recorder.recordGrow('g1'), throwsA(isA<Exception>()));
    });

    test('signed out: AuthRequiredException and no request', () async {
      final s = server(userId: null);
      await expectLater(
        s.recorder.recordGrow('g1'),
        throwsA(isA<AuthRequiredException>()),
      );
      expect(s.inserts, isEmpty);
    });
  });
}
