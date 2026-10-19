import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Daily care reminders (plan/05).
const careRemindersChannel = AndroidNotificationChannel(
  'care_reminders',
  'Care reminders',
);

/// Frost and weather warnings (plan/06).
const weatherAlertsChannel = AndroidNotificationChannel(
  'weather_alerts',
  'Weather alerts',
  importance: Importance.high,
);

/// Every Android channel the app posts to. [NotificationService.init]
/// creates them once per process.
const notificationChannels = [careRemindersChannel, weatherAlertsChannel];
