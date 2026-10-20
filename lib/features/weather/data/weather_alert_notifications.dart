import 'package:timezone/timezone.dart' as tz;

import '../../../core/notifications/notification_channels.dart';
import '../../../core/notifications/notification_payload.dart';
import '../../../core/notifications/notification_service.dart';
import '../domain/garden_alerts.dart';

/// Owns the frost-eve notifications on this device (plan/06).
///
/// Every [replace] cancels the weather alerts still pending, then schedules
/// the new set, so a refresh that clears a frost also clears its notice.
class WeatherAlertScheduler {
  WeatherAlertScheduler(this._service);

  final NotificationService _service;

  /// Tail of the replace queue, so an older, slower run can't finish after
  /// a newer one and bring back a stale notice.
  Future<void> _queue = Future.value();

  Future<void> replace(List<FrostNotice> notices) {
    final run = _queue.then((_) => _replace(notices));
    _queue = run.catchError((Object _) {});
    return run;
  }

  Future<void> _replace(List<FrostNotice> notices) async {
    for (final notice in await _service.pending()) {
      if (isWeatherAlertId(notice.id)) await _service.cancel(notice.id);
    }
    for (final n in notices.take(weatherAlertBudget)) {
      await _service.zonedSchedule(
        id: n.id,
        // plan/06 gives no title, so the channel's name is used.
        title: weatherAlertsChannel.name,
        body: n.body,
        scheduledDate: tz.TZDateTime(
          tz.local,
          n.at.year,
          n.at.month,
          n.at.day,
          n.at.hour,
          n.at.minute,
        ),
        channel: weatherAlertsChannel,
        payload: weatherAlertPayload,
      );
    }
  }
}
