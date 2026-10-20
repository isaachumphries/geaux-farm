import 'package:drift/drift.dart' show Value;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/app_database.dart';
import 'notification_channels.dart';
import 'notification_plugin.dart';

/// Local notifications: one-time setup, the single OS permission prompt, and
/// scheduling. Features schedule through this service, never the plugin.
class NotificationService {
  NotificationService(this._plugin, this._db, this._localTimezone);

  final NotificationPlugin _plugin;
  final AppDatabase _db;
  final Future<String> Function() _localTimezone;

  Future<void>? _init;
  void Function(String? payload)? _onTap;
  String? _pendingPayload;

  /// Sets up timezone data, the plugin, and the Android channels. Calls share
  /// one run; a failed run clears so the next call retries. [onTap] receives
  /// every payload, including one that launched the app.
  Future<void> init({void Function(String? payload)? onTap}) {
    if (onTap != null) {
      _onTap = onTap;
      final pending = _pendingPayload;
      _pendingPayload = null;
      if (pending != null) onTap(pending);
    }
    return _init ??= _initialize().onError((Object error, StackTrace stack) {
      _init = null;
      Error.throwWithStackTrace(error, stack);
    });
  }

  Future<void> _initialize() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await _localTimezone()));
    } on tz.LocationNotFoundException {
      // Keep timezone's UTC default. Schedules still fire at the right instant.
    }
    await _plugin.initialize(onTap: _handleTap);
    await _plugin.createChannels(notificationChannels);
    final launchPayload = await _plugin.launchPayload();
    if (launchPayload != null) _handleTap(launchPayload);
  }

  void _handleTap(String? payload) {
    final onTap = _onTap;
    if (onTap == null) {
      _pendingPayload = payload;
    } else {
      onTap(payload);
    }
  }

  /// The only path that shows the OS permission prompt. Records that the
  /// prompt was asked, whatever the answer, so PD-03 does not ask again.
  Future<bool> requestPermission() async {
    await init();
    final granted = await _plugin.requestPermission();
    await markPermissionAsked();
    return granted;
  }

  /// Records that the user has answered the PD-03 pre-prompt without showing
  /// the OS prompt ("Not now"). Reminders can be turned on in Settings.
  Future<void> markPermissionAsked() async {
    final update = _db.update(_db.userProfileTable)
      ..where((t) => t.id.equals(1));
    await update.write(
      const UserProfileTableCompanion(notificationPermissionAsked: Value(true)),
    );
  }

  /// Schedules a notification on [channel]. Always inexact: exact alarms need
  /// a permission this app does not request.
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required AndroidNotificationChannel channel,
    String? payload,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: channel.importance,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<List<({int id, String? payload})>> pending() async {
    await init();
    return _plugin.pending();
  }
}
