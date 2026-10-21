import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_payload.dart';
import '../core/notifications/notification_providers.dart';
import 'router.dart';

/// Starts notifications after the first frame, keeping timezone and plugin
/// work off the startup path. Notification taps route through [goRouterProvider].
///
/// Watched once by the root widget. Plugin-less hosts (widget tests, desktop)
/// throw [MissingPluginException], which is ignored.
final notificationStartupProvider = Provider<void>((ref) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!ref.mounted) return;
    try {
      await ref
          .read(notificationServiceProvider)
          .init(
            onTap: (payload) {
              if (!ref.mounted) return;
              ref.read(goRouterProvider).go(routeForPayload(payload));
            },
          );
    } on MissingPluginException {
      // No notification plugin on this host; nothing to start.
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'notifications',
          context: ErrorDescription('while starting notifications'),
        ),
      );
    }
  });
});
