import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/core/db/app_database.dart';
import 'package:geaux_farm/core/notifications/notification_providers.dart';
import 'package:geaux_farm/core/notifications/notification_service.dart';
import 'package:geaux_farm/features/care/presentation/widgets/task_row.dart';
import 'package:geaux_farm/features/garden/presentation/planting_added_screen.dart';
import 'package:geaux_farm/features/garden/presentation/reminder_pre_prompt.dart';

import '../helpers/inert_notification_plugin.dart';
import '../helpers/persisted_app_harness.dart' show settleDrift;
import 'garden_harness.dart';

/// Counts OS permission prompts. [missing] makes it act like a platform
/// with no notification plugin.
class _CountingPlugin extends InertNotificationPlugin {
  _CountingPlugin({this.missing = false});

  final bool missing;
  int permissionRequests = 0;

  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {
    if (missing) throw MissingPluginException();
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }
}

/// Pushes PD-03 over a launcher page, with the profile's pre-prompt
/// answered or not.
Future<(AppDatabase, _CountingPlugin)> _open(
  WidgetTester tester, {
  required bool permissionAsked,
  bool missingPlugin = false,
}) async {
  final db = openGardenDb();
  await tester.runAsync(
    () => seedProfile(db, permissionAsked: permissionAsked),
  );
  final plugin = _CountingPlugin(missing: missingPlugin);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...gardenOverrides(db),
        notificationServiceProvider.overrideWith(
          (ref) => NotificationService(plugin, db, () async => 'UTC'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PlantingAddedScreen(name: 'Kale'),
                ),
              ),
              child: const Text('launcher'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('launcher'));
  await settleDrift(tester);
  return (db, plugin);
}

Future<bool> _asked(WidgetTester tester, AppDatabase db) async {
  final row = await tester.runAsync(
    () => db.select(db.userProfileTable).getSingle(),
  );
  return row!.notificationPermissionAsked;
}

void main() {
  testWidgets('confirms the planting and shows "Water it in today" first', (
    tester,
  ) async {
    await _open(tester, permissionAsked: false);

    expect(find.text('Kale is in your garden!'), findsOneWidget);
    final row = tester.widget<TaskRow>(find.byType(TaskRow).first);
    expect(row.type, TaskRowType.water);
    expect(row.state, TaskRowState.due);
    expect(find.text('Water it in today'), findsOneWidget);
  });

  testWidgets('never asked: shows the pre-prompt with the plan copy', (
    tester,
  ) async {
    await _open(tester, permissionAsked: false);

    expect(find.byType(ReminderPrePrompt), findsOneWidget);
    expect(find.text('Get reminders during your free times?'), findsOneWidget);
    expect(find.text('TURN ON'), findsOneWidget);
    expect(find.text('NOT NOW'), findsOneWidget);
  });

  testWidgets('already asked: no pre-prompt, Done leaves', (tester) async {
    await _open(tester, permissionAsked: true);

    expect(find.byType(ReminderPrePrompt), findsNothing);
    expect(find.text('Get reminders during your free times?'), findsNothing);

    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();
    expect(find.text('launcher'), findsOneWidget);
  });

  testWidgets('Turn on asks the OS once and records the prompt', (
    tester,
  ) async {
    final (db, plugin) = await _open(tester, permissionAsked: false);

    await tester.tap(find.text('TURN ON'));
    await settleDrift(tester);

    expect(plugin.permissionRequests, 1);
    expect(await _asked(tester, db), isTrue);
    expect(find.text('launcher'), findsOneWidget);
  });

  testWidgets('Not now records the prompt without asking the OS', (
    tester,
  ) async {
    final (db, plugin) = await _open(tester, permissionAsked: false);

    await tester.tap(find.text('NOT NOW'));
    await settleDrift(tester);

    expect(plugin.permissionRequests, 0);
    expect(await _asked(tester, db), isTrue);
    expect(find.text('launcher'), findsOneWidget);
  });

  testWidgets('Turn on with no notification plugin still records and leaves', (
    tester,
  ) async {
    final (db, plugin) = await _open(
      tester,
      permissionAsked: false,
      missingPlugin: true,
    );

    await tester.tap(find.text('TURN ON'));
    await settleDrift(tester);

    expect(plugin.permissionRequests, 0);
    expect(await _asked(tester, db), isTrue);
    expect(find.text('launcher'), findsOneWidget);
  });
}
