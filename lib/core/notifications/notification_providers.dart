import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../db/app_database.dart';
import 'notification_plugin.dart';
import 'notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    FlutterNotificationPlugin(FlutterLocalNotificationsPlugin()),
    ref.watch(appDatabaseProvider),
    () async => (await FlutterTimezone.getLocalTimezone()).identifier,
  );
});
