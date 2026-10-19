import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/app.dart';
import 'package:geaux_farm/app/router.dart';
import 'package:go_router/go_router.dart';

import '../helpers/app_harness.dart';
import '../helpers/inert_notification_plugin.dart';

/// Plugin fake that keeps the tap handler `init` registers, so a test can
/// simulate a tap, and that can report a launch payload.
class _TapPlugin extends InertNotificationPlugin {
  _TapPlugin({this.launch});

  final String? launch;
  void Function(String? payload)? _onTap;

  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {
    _onTap = onTap;
  }

  @override
  Future<String?> launchPayload() async => launch;

  /// Simulates the user tapping a notification carrying [payload].
  void tap(String? payload) {
    final onTap = _onTap;
    if (onTap == null) {
      throw StateError('init has not registered the tap handler');
    }
    onTap(payload);
  }
}

/// Pumps the whole app with [plugin] and returns its router.
Future<GoRouter> _pumpApp(WidgetTester tester, _TapPlugin plugin) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: appOverrides(
        profile: onboardedProfile,
        notificationPlugin: plugin,
      ),
      child: const GeauxFarmApp(),
    ),
  );
  // Profile stream, router, then the post-frame notification start.
  await tester.pump();
  await tester.pump();
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(GeauxFarmApp)))
      .read(goRouterProvider);
}

Uri _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri;

void main() {
  group('notification taps reach the router', () {
    testWidgets('a care payload opens that day on the care schedule', (
      tester,
    ) async {
      final plugin = _TapPlugin();
      final router = await _pumpApp(tester, plugin);

      plugin.tap('care?date=2026-05-14');
      await tester.pump();
      await tester.pump();

      expect(_location(router).toString(), '/care?date=2026-05-14');
    });

    testWidgets('a malformed care date opens the plain care schedule', (
      tester,
    ) async {
      final plugin = _TapPlugin();
      final router = await _pumpApp(tester, plugin);

      plugin.tap('care?date=bad');
      await tester.pump();
      await tester.pump();

      expect(_location(router).toString(), '/care');
    });

    testWidgets('a payload that launched the app is routed once it starts', (
      tester,
    ) async {
      final plugin = _TapPlugin(launch: 'care?date=2026-05-14');
      final router = await _pumpApp(tester, plugin);

      expect(_location(router).toString(), '/care?date=2026-05-14');
    });
  });
}
