import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geaux_farm/core/notifications/notification_plugin.dart';
import 'package:timezone/timezone.dart' as tz;

/// One notification the plugin holds, as `zonedSchedule` received it.
class RecordedNotice {
  const RecordedNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.payload,
    required this.channelId,
  });

  final int id;
  final String title;
  final String body;
  final tz.TZDateTime scheduledDate;
  final String? payload;
  final String? channelId;
}

/// A [NotificationPlugin] that behaves like the OS list of pending
/// notifications and logs every call in order, so tests can check what is
/// pending and in which order calls happened. No OS call is made.
class RecordingNotificationPlugin implements NotificationPlugin {
  /// Ordered log: `schedule:<id>`, `cancel:<id>`, `cancelAll`, `pending`.
  final calls = <String>[];

  final _pending = <int, RecordedNotice>{};

  /// When true, `zonedSchedule` yields to the event loop first, which lets
  /// two overlapping recomputes interleave.
  bool yieldOnSchedule = false;

  /// Pending notifications by id.
  Map<int, RecordedNotice> get pendingById => Map.unmodifiable(_pending);

  List<String> get scheduleCalls => [
    for (final c in calls)
      if (c.startsWith('schedule:')) c,
  ];

  int get pendingCalls => calls.where((c) => c == 'pending').length;

  /// Puts a notification in the pending list without logging a call, as if an
  /// earlier session or another feature scheduled it.
  void seed(int id, String? payload) {
    _pending[id] = RecordedNotice(
      id: id,
      title: 'seed',
      body: 'seed',
      scheduledDate: tz.TZDateTime.utc(2030),
      payload: payload,
      channelId: null,
    );
  }

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
  Future<bool> requestPermission() async => true;

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
    if (yieldOnSchedule) await Future<void>.delayed(Duration.zero);
    calls.add('schedule:$id');
    _pending[id] = RecordedNotice(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      channelId: details.android?.channelId,
    );
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel:$id');
    _pending.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    calls.add('cancelAll');
    _pending.clear();
  }

  @override
  Future<List<({int id, String? payload})>> pending() async {
    calls.add('pending');
    return [for (final n in _pending.values) (id: n.id, payload: n.payload)];
  }
}
