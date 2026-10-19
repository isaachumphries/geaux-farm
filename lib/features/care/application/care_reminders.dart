import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/db/app_database.dart';
import '../../../core/notifications/notification_channels.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../onboarding/data/profile_providers.dart';
import '../../recommendations/application/clock_provider.dart';
import '../domain/care_reminders.dart';
import '../domain/care_schedule.dart';
import 'care_schedule_provider.dart';

/// Owns the care reminder notifications on this device.
///
/// Every recompute cancels the care reminders still pending, then schedules
/// one per slot in the next 7 days.
///
/// Known limitation: There is no background refresh. If the app is not opened
/// for 7 or more days, scheduled reminders stop firing once the 7-day window
/// has passed. Reminders resume when the app is opened.
class CareReminderScheduler {
  CareReminderScheduler(this._service, this._db, this._now);

  final NotificationService _service;
  final AppDatabase _db;
  final DateTime Function() _now;

  /// Stores the switch, then brings the device schedule in line with it.
  Future<void> setEnabled({
    required bool enabled,
    required List<ScheduledCareTask> tasks,
  }) async {
    await (_db.update(_db.userProfileTable)..where((t) => t.id.equals(1)))
        .write(UserProfileTableCompanion(notificationsEnabled: Value(enabled)));
    await recompute(enabled: enabled, tasks: tasks);
  }

  /// Cancels every pending care reminder, then schedules one per slot when
  /// [enabled]. Cancelling first means a removed task or a switched-off
  /// toggle never leaves a stale reminder behind.
  Future<void> recompute({
    required bool enabled,
    required List<ScheduledCareTask> tasks,
  }) async {
    final now = _now();
    for (final notice in await _service.pending()) {
      if (isCareReminderPayload(notice.payload)) {
        await _service.cancel(notice.id);
      }
    }
    if (!enabled) return;
    for (final reminder in planCareReminders(tasks: tasks, now: now)) {
      await _service.zonedSchedule(
        id: reminder.id,
        title: careReminderTitle,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.start, tz.local),
        channel: careRemindersChannel,
        payload: reminder.payload,
      );
    }
  }
}

final careReminderSchedulerProvider = Provider<CareReminderScheduler>(
  (ref) => CareReminderScheduler(
    ref.watch(notificationServiceProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

/// Keeps care reminders in step with the care schedule. The app root watches
/// it, so it runs at start. Every input the schedule reads (plantings, care
/// events, availability, weather, the profile) re-runs it. Resume invalidates
/// the schedule so the 7-day window rolls forward.
final careRemindersSyncProvider = Provider<void>((ref) {
  Future<void> sync(List<ScheduledCareTask> tasks) async {
    try {
      final profile = await ref.read(userProfileProvider.future);
      if (!ref.mounted) return;
      await ref
          .read(careReminderSchedulerProvider)
          .recompute(enabled: profile.notificationsEnabled, tasks: tasks);
    } on MissingPluginException {
      // No notification plugin on this platform. There is nothing to schedule.
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'notifications',
          context: ErrorDescription('while recomputing care reminders'),
        ),
      );
    }
  }

  final lifecycle = AppLifecycleListener(
    onResume: () => ref.invalidate(careScheduleProvider),
  );
  ref.onDispose(lifecycle.dispose);
  ref.listen(careScheduleProvider, (_, next) {
    final tasks = next.value;
    if (tasks != null) unawaited(sync(tasks));
  });
});
