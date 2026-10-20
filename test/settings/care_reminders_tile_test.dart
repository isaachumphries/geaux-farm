import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/core/notifications/notification_providers.dart';
import 'package:geaux_farm/core/notifications/notification_service.dart';
import 'package:geaux_farm/features/care/application/care_schedule_provider.dart';
import 'package:geaux_farm/features/care/domain/care_reminders.dart';
import 'package:geaux_farm/features/care/domain/care_schedule.dart';
import 'package:geaux_farm/features/care/domain/slot.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/settings/presentation/settings_screen.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/in_memory_database.dart';
import '../helpers/recording_notification_plugin.dart';

final _now = DateTime(2026, 5, 14, 7);
final _slot = DateTime(2026, 5, 14, 18);

final _tasks = [
  ScheduledCareTask(
    plantingId: 'p1',
    nickname: 'Basil',
    kind: CareTaskKind.water,
    due: DateTime(2026, 5, 14),
    slot: CareSlot(start: _slot, outsideFreeTimes: false),
    overdue: false,
  ),
];

Future<void> _seedProfile(AppDatabase db, {required bool enabled}) => db
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
        notificationsEnabled: Value(enabled),
      ),
    );

Future<bool> _stored(WidgetTester tester, AppDatabase db) async {
  final row = await tester.runAsync(
    () => db.select(db.userProfileTable).getSingle(),
  );
  return row!.notificationsEnabled;
}

/// Lets real async work (Drift, plugin fakes) finish, then settles frames.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  late RecordingNotificationPlugin plugin;
  late ProviderContainer container;

  Future<AppDatabase> pump(WidgetTester tester, {required bool enabled}) async {
    plugin = RecordingNotificationPlugin();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inMemoryDatabaseOverride(),
          notificationServiceProvider.overrideWith(
            (ref) => NotificationService(
              plugin,
              ref.watch(appDatabaseProvider),
              () async => 'UTC',
            ),
          ),
          careScheduleProvider.overrideWith((ref) async => _tasks),
          clockProvider.overrideWithValue(() => _now),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    final db = container.read(appDatabaseProvider);
    await tester.runAsync(() => _seedProfile(db, enabled: enabled));
    await _settle(tester);
    return db;
  }

  // Drift closes its stream queries on a zero-length timer.
  Future<void> tearDownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  bool switchValue(WidgetTester tester) =>
      tester.widget<Switch>(find.byType(Switch)).value;

  testWidgets('shows the label, subtitle and a switch bound to the profile', (
    tester,
  ) async {
    await pump(tester, enabled: true);
    expect(find.text('Care reminders'), findsOneWidget);
    expect(find.text('Only during your free times'), findsOneWidget);
    expect(switchValue(tester), isTrue);
    await tearDownTree(tester);
  });

  testWidgets('the switch shows off when the profile has it off', (
    tester,
  ) async {
    await pump(tester, enabled: false);
    expect(switchValue(tester), isFalse);
    await tearDownTree(tester);
  });

  testWidgets('switching off stores false and cancels care reminders', (
    tester,
  ) async {
    final db = await pump(tester, enabled: true);
    plugin.seed(111, 'care?date=2026-05-14');
    plugin.seed(222, 'weather?kind=frost');

    await tester.tap(find.byType(Switch));
    await _settle(tester);

    expect(await _stored(tester, db), isFalse);
    expect(switchValue(tester), isFalse);
    expect(plugin.scheduleCalls, isEmpty);
    expect(plugin.calls, contains('cancel:111'));
    expect(plugin.pendingById.keys, [222]);
    await tearDownTree(tester);
  });

  testWidgets('switching on stores true and schedules the reminders', (
    tester,
  ) async {
    final db = await pump(tester, enabled: false);

    await tester.tap(find.byType(Switch));
    await _settle(tester);

    expect(await _stored(tester, db), isTrue);
    expect(switchValue(tester), isTrue);
    final notice = plugin.pendingById.values.single;
    expect(notice.title, 'Garden time');
    expect(notice.body, 'Water Basil');
    expect(notice.id, careReminderId(_slot));
    await tearDownTree(tester);
  });
}
