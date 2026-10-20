import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/core/notifications/notification_providers.dart';
import 'package:geaux_farm/core/notifications/notification_service.dart';
import 'package:geaux_farm/features/care/application/care_reminders.dart';
import 'package:geaux_farm/features/care/application/care_schedule_provider.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/care/domain/care_reminders.dart';
import 'package:geaux_farm/features/care/domain/care_schedule.dart';
import 'package:geaux_farm/features/care/domain/slot.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';
import 'package:geaux_farm/features/garden/data/plantings_provider.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/weather/data/forecast_client.dart';
import 'package:geaux_farm/features/weather/data/weather_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/in_memory_database.dart';
import '../helpers/recording_notification_plugin.dart';

/// Thursday 2026-05-14, 07:00 local. Every planner test passes this `now`.
final _now = DateTime(2026, 5, 14, 7);

/// The slot most planner tests use: 18:00 the same day.
final _slot = DateTime(2026, 5, 14, 18);

ScheduledCareTask _task(String nickname, CareTaskKind kind, {DateTime? slot}) =>
    ScheduledCareTask(
      plantingId: nickname.toLowerCase(),
      nickname: nickname,
      kind: kind,
      due: DateTime(2026, 5, 14),
      slot: CareSlot(start: slot ?? _slot, outsideFreeTimes: false),
      overdue: false,
    );

List<ScheduledCareTask> _water(List<String> names, {DateTime? slot}) => [
  for (final n in names) _task(n, CareTaskKind.water, slot: slot),
];

List<CareReminder> _plan(List<ScheduledCareTask> tasks) =>
    planCareReminders(tasks: tasks, now: _now);

void main() {
  // The sync provider listens for app lifecycle changes, which needs a binding.
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('planCareReminders', () {
    test('3 water tasks at one slot make one reminder', () {
      final reminders = _plan(_water(['Basil', 'Kale', 'Mint']));
      expect(reminders, hasLength(1));
      expect(reminders.single.body, 'Water Basil, Kale, Mint');
      expect(reminders.single.start, _slot);
    });

    test('3 water tasks plus 1 fertilize task join verbs with a dot', () {
      final reminders = _plan([
        ..._water(['Basil', 'Kale', 'Mint']),
        _task('Tomato', CareTaskKind.fertilize),
      ]);
      expect(reminders, hasLength(1));
      expect(
        reminders.single.body,
        'Water Basil, Kale, Mint · Fertilize Tomato',
      );
    });

    test('5 water tasks list 3 names and count the rest', () {
      final reminders = _plan(
        _water(['Basil', 'Kale', 'Mint', 'Sage', 'Thyme']),
      );
      expect(reminders.single.body, 'Water Basil, Kale, Mint +2 more');
    });

    test('exactly 4 names in one verb gives +1 more', () {
      final reminders = _plan(_water(['Basil', 'Kale', 'Mint', 'Sage']));
      expect(reminders.single.body, 'Water Basil, Kale, Mint +1 more');
    });

    test('the 3-name cap applies to each verb on its own', () {
      final reminders = _plan([
        for (final n in ['A', 'B', 'C', 'D']) _task(n, CareTaskKind.fertilize),
        for (final n in ['E', 'F', 'G', 'H', 'I']) _task(n, CareTaskKind.water),
      ]);
      expect(
        reminders.single.body,
        'Water E, F, G +2 more · Fertilize A, B, C +1 more',
      );
    });

    test('verbs come out as Water, Fertilize, Prune, Harvest', () {
      final reminders = _plan([
        _task('Pepper', CareTaskKind.harvest),
        _task('Rose', CareTaskKind.prune),
        _task('Tomato', CareTaskKind.fertilize),
        _task('Basil', CareTaskKind.water),
      ]);
      expect(
        reminders.single.body,
        'Water Basil · Fertilize Tomato · Prune Rose · Harvest Pepper',
      );
    });

    test(
      'matches the CR-02 notification: Water Kale · Prune English Lavender',
      () {
        final reminders = _plan([
          _task('Kale', CareTaskKind.water),
          _task('English Lavender', CareTaskKind.prune),
        ]);
        expect(reminders.single.body, 'Water Kale · Prune English Lavender');
      },
    );

    test('the payload is care?date= the date of the slot', () {
      final reminders = planCareReminders(
        tasks: _water(['Basil'], slot: DateTime(2026, 5, 16, 6)),
        now: _now,
      );
      expect(reminders.single.payload, 'care?date=2026-05-16');
      expect(isCareReminderPayload(reminders.single.payload), isTrue);
    });

    test('isCareReminderPayload rejects weather and empty payloads', () {
      expect(isCareReminderPayload(null), isFalse);
      expect(isCareReminderPayload('weather?kind=frost'), isFalse);
    });

    test('id is the slot in UTC epoch minutes mod 2^31', () {
      final slot = DateTime.utc(2026, 5, 14, 18);
      final expected = (slot.millisecondsSinceEpoch ~/ 60000) % (1 << 31);
      expect(careReminderId(slot), expected);
      // The same instant given in local time has the same id.
      expect(careReminderId(slot.toLocal()), expected);
      final reminders = _plan(_water(['Basil'], slot: slot));
      expect(reminders.single.id, expected);
    });

    test('id wraps once the minute count passes 2^31', () {
      final slot = DateTime.utc(8125);
      final minutes = slot.millisecondsSinceEpoch ~/ 60000;
      expect(minutes, greaterThan(1 << 31));
      expect(careReminderId(slot), minutes % (1 << 31));
      expect(careReminderId(slot), lessThan(1 << 31));
    });

    test('slots become separate reminders, earliest first', () {
      final late = DateTime(2026, 5, 15, 9);
      final reminders = _plan([
        ..._water(['Kale'], slot: late),
        ..._water(['Basil']),
      ]);
      expect(reminders.map((r) => r.body), ['Water Basil', 'Water Kale']);
      expect(reminders.map((r) => r.start), [_slot, late]);
      expect(reminders[0].id, isNot(reminders[1].id));
    });

    test('slots that already started are dropped, a slot at now is not', () {
      final reminders = _plan([
        ..._water(['Past'], slot: DateTime(2026, 5, 14, 6, 59)),
        ..._water(['Now'], slot: _now),
      ]);
      expect(reminders.map((r) => r.body), ['Water Now']);
    });

    test('slots on or past the 7th day ahead are dropped', () {
      final reminders = _plan([
        ..._water(['Inside'], slot: DateTime(2026, 5, 20, 22)),
        ..._water(['Outside'], slot: DateTime(2026, 5, 21, 6)),
      ]);
      expect(reminders.map((r) => r.body), ['Water Inside']);
    });

    test('a slot with only other tasks makes no reminder', () {
      expect(_plan([_task('Oddity', CareTaskKind.other)]), isEmpty);
    });

    test('other tasks never show in a body', () {
      final reminders = _plan([
        _task('Oddity', CareTaskKind.other),
        _task('Basil', CareTaskKind.water),
      ]);
      expect(reminders.single.body, 'Water Basil');
    });

    test('at most 56 reminders, the earliest slots win', () {
      expect(careReminderBudget, 56);
      final tasks = [
        for (var i = 0; i < 70; i++)
          _task(
            'Plant$i',
            CareTaskKind.water,
            slot: DateTime(2026, 5, 14, 8).add(Duration(hours: i)),
          ),
      ];
      final reminders = _plan(tasks);
      expect(reminders, hasLength(56));
      expect(reminders.first.body, 'Water Plant0');
      expect(reminders.last.body, 'Water Plant55');
    });
  });

  group('CareReminderScheduler', () {
    late AppDatabase db;
    late RecordingNotificationPlugin plugin;
    late CareReminderScheduler scheduler;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedProfile(db);
      plugin = RecordingNotificationPlugin();
      scheduler = CareReminderScheduler(
        NotificationService(plugin, db, () async => 'UTC'),
        db,
        () => _now,
      );
    });

    test('schedules title, body, channel, payload and time per slot', () async {
      await scheduler.recompute(
        enabled: true,
        tasks: _water(['Basil', 'Kale', 'Mint']),
      );
      final notice = plugin.pendingById.values.single;
      expect(notice.title, 'Garden time');
      expect(notice.body, 'Water Basil, Kale, Mint');
      expect(notice.channelId, 'care_reminders');
      expect(notice.payload, 'care?date=2026-05-14');
      expect(notice.id, careReminderId(_slot));
      expect(notice.scheduledDate.toUtc(), _slot.toUtc());
    });

    test('cancels earlier care reminders before it schedules any', () async {
      plugin.seed(111, 'care?date=2026-05-13');
      plugin.seed(222, 'care?date=2026-05-15');
      await scheduler.recompute(enabled: true, tasks: _water(['Basil']));

      final firstSchedule = plugin.calls.indexWhere(
        (c) => c.startsWith('schedule:'),
      );
      expect(firstSchedule, isNonNegative);
      expect(plugin.calls.indexOf('cancel:111'), lessThan(firstSchedule));
      expect(plugin.calls.indexOf('cancel:222'), lessThan(firstSchedule));
      expect(plugin.pendingById.keys, [careReminderId(_slot)]);
    });

    test('leaves weather notifications alone', () async {
      plugin.seed(333, 'weather?kind=frost');
      plugin.seed(444, null);
      plugin.seed(555, 'care?date=2026-05-13');
      await scheduler.recompute(enabled: true, tasks: _water(['Basil']));
      expect(plugin.calls, isNot(contains('cancel:333')));
      expect(plugin.calls, isNot(contains('cancel:444')));
      expect(plugin.calls, contains('cancel:555'));
      expect(plugin.pendingById.keys, containsAll([333, 444]));
      expect(plugin.calls, isNot(contains('cancelAll')));
    });

    test('a removed task leaves no stale reminder', () async {
      await scheduler.recompute(
        enabled: true,
        tasks: _water(['Basil'], slot: DateTime(2026, 5, 15, 9)),
      );
      await scheduler.recompute(enabled: true, tasks: _water(['Kale']));
      expect(plugin.pendingById.values.map((n) => n.body), ['Water Kale']);
    });

    test('recomputing twice does not duplicate reminders', () async {
      final tasks = _water(['Basil']);
      await scheduler.recompute(enabled: true, tasks: tasks);
      await scheduler.recompute(enabled: true, tasks: tasks);
      expect(plugin.pendingById, hasLength(1));
    });

    test('overlapping recomputes end with the later one pending', () async {
      plugin.yieldOnSchedule = true;
      final stale = _water(['Old'], slot: DateTime(2026, 5, 15, 9));
      final fresh = _water(['New'], slot: DateTime(2026, 5, 16, 9));
      await Future.wait([
        scheduler.recompute(enabled: true, tasks: stale),
        scheduler.recompute(enabled: true, tasks: fresh),
      ]);
      expect(plugin.pendingById.values.map((n) => n.body), ['Water New']);
    });

    test('never schedules more than 56 care reminders', () async {
      final tasks = [
        for (var i = 0; i < 70; i++)
          _task(
            'P$i',
            CareTaskKind.water,
            slot: DateTime(2026, 5, 14, 8).add(Duration(hours: i)),
          ),
      ];
      await scheduler.recompute(enabled: true, tasks: tasks);
      expect(plugin.pendingById, hasLength(56));
    });

    test('disabled: cancels every care id and schedules nothing', () async {
      plugin.seed(111, 'care?date=2026-05-13');
      plugin.seed(222, 'care?date=2026-05-15');
      plugin.seed(333, 'weather?kind=frost');
      await scheduler.recompute(enabled: false, tasks: _water(['Basil']));
      expect(plugin.scheduleCalls, isEmpty);
      expect(plugin.calls, containsAll(['cancel:111', 'cancel:222']));
      expect(plugin.pendingById.keys, [333]);
    });

    test('setEnabled(false) stores false and clears the reminders', () async {
      await scheduler.recompute(enabled: true, tasks: _water(['Basil']));
      plugin.calls.clear();
      await scheduler.setEnabled(enabled: false, tasks: const []);
      expect(await _storedEnabled(db), isFalse);
      expect(plugin.scheduleCalls, isEmpty);
      expect(plugin.calls, contains('cancel:${careReminderId(_slot)}'));
      expect(plugin.pendingById, isEmpty);
    });

    test('setEnabled(true) stores true and schedules again', () async {
      await scheduler.setEnabled(enabled: false, tasks: const []);
      await scheduler.setEnabled(enabled: true, tasks: _water(['Basil']));
      expect(await _storedEnabled(db), isTrue);
      expect(plugin.pendingById.values.map((n) => n.body), ['Water Basil']);
    });
  });

  group('careRemindersSyncProvider', () {
    late RecordingNotificationPlugin plugin;
    late _Feed<List<Planting>> plantings;
    late _Feed<List<CareEvent>> events;
    late _Feed<UserProfile> profile;
    late ProviderContainer container;

    // Friday 2026-05-01 is the 2nd day of the window, so one Kale water
    // task lands in the free block at 06:00 that day.
    final now = DateTime(2026, 4, 30, 7);
    final kale = carePlanting();

    UserProfile profileWith({
      Availability? availability,
      bool notificationsEnabled = true,
    }) => UserProfile(
      city: defaultUserProfile.city,
      admin1: defaultUserProfile.admin1,
      countryCode: defaultUserProfile.countryCode,
      lat: 40.0,
      lon: -90.0,
      timezone: defaultUserProfile.timezone,
      goals: defaultUserProfile.goals,
      experience: defaultUserProfile.experience,
      availability: availability ?? careAllFree,
      notificationsEnabled: notificationsEnabled,
    );

    Future<void> settle() => pumpEventQueue(times: 100);

    Future<void> start({List<Planting>? initial}) async {
      plugin = RecordingNotificationPlugin();
      plantings = _Feed(initial ?? [kale]);
      events = _Feed(const <CareEvent>[]);
      profile = _Feed(profileWith());
      container = ProviderContainer(
        overrides: [
          inMemoryDatabaseOverride(),
          notificationServiceProvider.overrideWith(
            (ref) => NotificationService(
              plugin,
              ref.watch(appDatabaseProvider),
              () async => 'UTC',
            ),
          ),
          plantingsProvider.overrideWith((ref) => plantings.watch()),
          spacesProvider.overrideWith((ref) => Stream.value([careSpace()])),
          careEventsProvider.overrideWith((ref) => events.watch()),
          userProfileProvider.overrideWith((ref) => profile.watch()),
          catalogProvider.overrideWith((ref) async => [carePlant()]),
          clockProvider.overrideWithValue(() => now),
          forecastClientProvider.overrideWithValue(
            OpenMeteoForecastClient(
              MockClient((_) async => http.Response('', 500)),
            ),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await plantings.close();
        await events.close();
        await profile.close();
      });
      container.listen(careRemindersSyncProvider, (_, _) {});
      await settle();
    }

    List<String> bodies() => [
      for (final n in plugin.pendingById.values) n.body,
    ];

    test('app start schedules the reminder for the care schedule', () async {
      await start();
      expect(bodies(), ['Water Kale']);
      final notice = plugin.pendingById.values.single;
      expect(notice.scheduledDate.toUtc(), DateTime(2026, 5, 1, 6).toUtc());
      expect(notice.payload, 'care?date=2026-05-01');
    });

    test('planting add reschedules with the new plant', () async {
      await start();
      plantings.emit([kale, carePlanting(id: 'p2', nickname: 'Basil')]);
      await settle();
      expect(bodies(), ['Water Basil, Kale']);
    });

    test('planting remove cancels its reminder', () async {
      await start();
      plantings.emit(const []);
      await settle();
      expect(bodies(), isEmpty);
    });

    test('planting status change drops it from the reminders', () async {
      await start();
      plantings.emit([carePlanting(status: PlantingStatus.planned)]);
      await settle();
      expect(bodies(), isEmpty);
    });

    test('availability edit moves the reminder to the new slot', () async {
      await start();
      // Friday block 2 starts at 10:00.
      profile.emit(
        profileWith(
          availability: careFree({
            5: [2],
          }),
        ),
      );
      await settle();
      final notice = plugin.pendingById.values.single;
      expect(notice.scheduledDate.toUtc(), DateTime(2026, 5, 1, 10).toUtc());
      expect(plugin.pendingById.keys, [careReminderId(notice.scheduledDate)]);
    });

    test('a care event insert recomputes', () async {
      await start();
      final before = plugin.pendingCalls;
      events.emit([
        CareEvent(
          id: 'e1',
          plantingId: kale.id,
          type: CareEventType.water,
          at: DateTime(2026, 4, 30, 6),
        ),
      ]);
      await settle();
      expect(plugin.pendingCalls, greaterThan(before));
    });

    test('a weather refresh recomputes', () async {
      await start();
      final before = plugin.pendingCalls;
      container.invalidate(weatherProvider);
      await settle();
      expect(plugin.pendingCalls, greaterThan(before));
    });

    test('app resume recomputes', () async {
      await start();
      final before = plugin.pendingCalls;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle();
      expect(plugin.pendingCalls, greaterThan(before));
    });

    test('one change recomputes once, not once per loading state', () async {
      await start();
      final before = plugin.pendingCalls;
      plantings.emit([kale, carePlanting(id: 'p2', nickname: 'Basil')]);
      await settle();
      expect(plugin.pendingCalls - before, 1);
    });

    test('switching notifications off clears care ids and stays off', () async {
      await start();
      expect(bodies(), isNotEmpty);
      profile.emit(profileWith(notificationsEnabled: false));
      await settle();
      expect(bodies(), isEmpty);

      // Every other trigger is now a no-op.
      plugin.calls.clear();
      plantings.emit([kale, carePlanting(id: 'p2', nickname: 'Basil')]);
      await settle();
      container.invalidate(weatherProvider);
      await settle();
      expect(plugin.scheduleCalls, isEmpty);
      expect(bodies(), isEmpty);
    });

    test('switching notifications on schedules again', () async {
      await start();
      profile.emit(profileWith(notificationsEnabled: false));
      await settle();
      profile.emit(profileWith());
      await settle();
      expect(bodies(), ['Water Kale']);
    });
  });
}

Future<void> _seedProfile(AppDatabase db) => db
    .into(db.userProfileTable)
    .insert(
      UserProfileTableCompanion.insert(
        id: const Value(1),
        city: 'Baton Rouge',
        admin1: 'Louisiana',
        countryCode: 'US',
        lat: 30.45,
        lon: -91.19,
        timezone: 'America/Chicago',
        goals: [Goal.food],
        experience: Experience.beginner,
        availability: careAllFree,
        units: 'imperial',
      ),
    );

Future<bool> _storedEnabled(AppDatabase db) async =>
    (await db.select(db.userProfileTable).getSingle()).notificationsEnabled;

/// A value stream the test can push to after the first read. Each new
/// listener gets the current value first, then every [emit].
class _Feed<T> {
  _Feed(this._value);

  final _controller = StreamController<T>.broadcast();
  T _value;

  void emit(T next) {
    _value = next;
    _controller.add(next);
  }

  Future<void> close() => _controller.close();

  Stream<T> watch() async* {
    yield _value;
    yield* _controller.stream;
  }
}
