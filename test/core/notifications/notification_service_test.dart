import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/core/notifications/notification_channels.dart';
import 'package:geaux_farm/core/notifications/notification_payload.dart';
import 'package:geaux_farm/core/notifications/notification_plugin.dart';
import 'package:geaux_farm/core/notifications/notification_service.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// One `zonedSchedule` call as the fake plugin received it.
class ScheduledCall {
  const ScheduledCall({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.details,
    required this.mode,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final tz.TZDateTime scheduledDate;
  final NotificationDetails details;
  final AndroidScheduleMode mode;
  final String? payload;
}

/// Records every plugin call. Tests set the fields to script the answers.
class FakePlugin implements NotificationPlugin {
  int initializeCount = 0;
  int failInitializes = 0;
  String? launchPayloadValue;
  void Function(String? payload)? onTap;
  final channelBatches = <List<AndroidNotificationChannel>>[];
  final scheduled = <ScheduledCall>[];
  bool permissionGranted = true;
  int permissionRequests = 0;
  final cancelledIds = <int>[];
  int cancelAllCount = 0;
  List<({int id, String? payload})> pendingNotices = const [];

  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {
    initializeCount++;
    if (failInitializes > 0) {
      failInitializes--;
      throw StateError('plugin unavailable');
    }
    this.onTap = onTap;
  }

  @override
  Future<String?> launchPayload() async => launchPayloadValue;

  @override
  Future<void> createChannels(List<AndroidNotificationChannel> channels) async {
    channelBatches.add(List.of(channels));
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
  }) async {
    scheduled.add(
      ScheduledCall(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        details: details,
        mode: androidScheduleMode,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
  }

  @override
  Future<List<({int id, String? payload})>> pending() async => pendingNotices;
}

Future<void> _seedProfile(AppDatabase db) async {
  await db
      .into(db.userProfileTable)
      .insert(
        UserProfileTableCompanion.insert(
          id: const Value(1),
          city: 'Lafayette',
          admin1: 'Louisiana',
          countryCode: 'US',
          lat: 30.22,
          lon: -92.02,
          timezone: 'America/Chicago',
          goals: [Goal.food],
          experience: Experience.beginner,
          availability: const Availability([1, 2, 4]),
          units: 'metric',
        ),
      );
}

Future<bool> _permissionAsked(AppDatabase db) async {
  final row = await db.select(db.userProfileTable).getSingle();
  return row.notificationPermissionAsked;
}

void main() {
  late FakePlugin plugin;
  late AppDatabase db;

  setUp(() {
    tzdata.initializeTimeZones();
    // timezone's `local` is process-global; reset it so each test starts at UTC.
    tz.setLocalLocation(tz.UTC);
    plugin = FakePlugin();
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
  });

  NotificationService service({String zone = 'America/Chicago'}) =>
      NotificationService(plugin, db, () async => zone);

  group('init', () {
    test(
      'creates both channels once across repeated and concurrent calls',
      () async {
        final svc = service();
        await Future.wait([svc.init(), svc.init(), svc.init()]);
        await svc.init();

        expect(plugin.initializeCount, 1);
        expect(plugin.channelBatches, hasLength(1));
        final channels = plugin.channelBatches.single;
        expect(channels.map((c) => c.id).toList(), [
          'care_reminders',
          'weather_alerts',
        ]);
        expect(channels.map((c) => c.name).toList(), [
          'Care reminders',
          'Weather alerts',
        ]);
      },
    );

    test('retries after a failed initialize, then succeeds', () async {
      plugin.failInitializes = 1;
      final svc = service();

      await expectLater(svc.init(), throwsStateError);
      await svc.init();

      expect(plugin.initializeCount, 2);
      expect(plugin.channelBatches, hasLength(1));
    });

    test('sets the local zone from the device timezone', () async {
      await service().init();
      expect(tz.local.name, 'America/Chicago');
    });

    test('keeps UTC when the device zone is unknown', () async {
      await service(zone: 'Mars/Olympus').init();
      expect(tz.local.name, tz.UTC.name);
      expect(plugin.initializeCount, 1);
    });
  });

  group('payload taps', () {
    test('delivers a launch payload through onTap once', () async {
      plugin.launchPayloadValue = 'care?date=2026-05-14';
      final taps = <String?>[];
      final svc = service();

      await svc.init(onTap: taps.add);
      await svc.init(onTap: taps.add);

      expect(taps, ['care?date=2026-05-14']);
    });

    test(
      'holds a payload that arrives before onTap, then replays it once',
      () async {
        plugin.launchPayloadValue = 'care?date=2026-05-14';
        final svc = service();
        await svc.init();

        final taps = <String?>[];
        await svc.init(onTap: taps.add);
        await svc.init(onTap: taps.add);

        expect(taps, ['care?date=2026-05-14']);
      },
    );

    test('routes a tap that arrives after init to onTap', () async {
      final taps = <String?>[];
      await service().init(onTap: taps.add);

      plugin.onTap!('care?date=2026-05-14');

      expect(taps, ['care?date=2026-05-14']);
    });
  });

  group('zonedSchedule', () {
    late tz.TZDateTime when;

    setUp(() {
      when = tz.TZDateTime.from(DateTime.utc(2026, 5, 14, 12), tz.UTC);
    });

    test('always uses inexact allow-while-idle on the care channel', () async {
      await service().zonedSchedule(
        id: 42,
        title: 'Water basil',
        body: 'Check the soil',
        scheduledDate: when,
        channel: careRemindersChannel,
        payload: 'care?date=2026-05-14',
      );

      final call = plugin.scheduled.single;
      expect(call.mode, AndroidScheduleMode.inexactAllowWhileIdle);
      expect(call.id, 42);
      expect(call.title, 'Water basil');
      expect(call.body, 'Check the soil');
      expect(call.scheduledDate.isAtSameMomentAs(when), isTrue);
      expect(call.payload, 'care?date=2026-05-14');
      expect(call.details.android?.channelId, 'care_reminders');
    });

    test('weather alerts go out at high importance', () async {
      await service().zonedSchedule(
        id: 7,
        title: 'Frost tonight',
        body: 'Cover tender plants',
        scheduledDate: when,
        channel: weatherAlertsChannel,
      );

      final call = plugin.scheduled.single;
      expect(call.mode, AndroidScheduleMode.inexactAllowWhileIdle);
      expect(call.details.android?.channelId, 'weather_alerts');
      expect(call.details.android?.importance, Importance.high);
    });
  });

  group('requestPermission', () {
    test('asks once, returns the grant, and records the prompt', () async {
      await _seedProfile(db);
      expect(await _permissionAsked(db), isFalse);
      plugin.permissionGranted = true;

      expect(await service().requestPermission(), isTrue);

      expect(plugin.permissionRequests, 1);
      expect(await _permissionAsked(db), isTrue);
    });

    test('records the prompt even when the user denies it', () async {
      await _seedProfile(db);
      plugin.permissionGranted = false;

      expect(await service().requestPermission(), isFalse);

      expect(plugin.permissionRequests, 1);
      expect(await _permissionAsked(db), isTrue);
    });

    test('markPermissionAsked records the prompt without asking', () async {
      await _seedProfile(db);

      await service().markPermissionAsked();

      expect(plugin.permissionRequests, 0);
      expect(plugin.initializeCount, 0);
      expect(await _permissionAsked(db), isTrue);
    });
  });

  group('cancel and pending', () {
    test('delegates cancel, cancelAll, and pending to the plugin', () async {
      plugin.pendingNotices = [
        (id: 5, payload: null),
        (id: 9, payload: 'care?date=2026-05-14'),
      ];
      final svc = service();

      final pending = await svc.pending();
      expect(pending.map((notice) => notice.id), [5, 9]);
      expect(pending.last.payload, 'care?date=2026-05-14');
      await svc.cancel(5);
      await svc.cancelAll();

      expect(plugin.cancelledIds, [5]);
      expect(plugin.cancelAllCount, 1);
    });
  });

  group('routeForPayload', () {
    const cases = <(String?, String)>[
      ('care?date=2026-05-14', '/care?date=2026-05-14'),
      ('care?date=2028-02-29', '/care?date=2028-02-29'),
      ('care?date=bad', '/care'),
      ('care?date=2026-05-14x', '/care'),
      ('care?date=x2026-05-14', '/care'),
      ('care?date=2026-05-14T10:00:00', '/care'),
      ('care?date=2026-13-45', '/care'),
      ('care?date=2026-02-30', '/care'),
      ('care', '/care'),
      ('weather', '/weather'),
      ('weather?date=2026-05-14', '/care'),
      ('unknown', '/care'),
      ('', '/care'),
      (null, '/care'),
    ];

    for (final (payload, route) in cases) {
      test('maps ${payload ?? 'null'} to $route', () {
        expect(routeForPayload(payload), route);
      });
    }
  });
}
