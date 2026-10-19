import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geaux_farm/core/notifications/notification_plugin.dart';
import 'package:timezone/timezone.dart' as tz;

/// A [NotificationPlugin] that does nothing. App-level widget tests use it so
/// no OS notification call is made.
class InertNotificationPlugin implements NotificationPlugin {
  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {}

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<void> createChannels(
    List<AndroidNotificationChannel> channels,
  ) async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
  }) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<List<int>> pendingIds() async => const [];
}
