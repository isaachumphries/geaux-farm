import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android manifest', () {
    late String manifest;

    setUpAll(() {
      manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
    });

    test('declares the notification and boot permissions', () {
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    });

    test('declares the plugin receivers for scheduled and boot alerts', () {
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
        ),
      );
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver',
        ),
      );
    });

    test('requests no exact-alarm permission', () {
      expect(manifest, isNot(contains('SCHEDULE_EXACT_ALARM')));
      expect(manifest, isNot(contains('USE_EXACT_ALARM')));
    });
  });

  group('onboarding never prompts for notifications', () {
    // Onboarding may ask for location, which is a different permission.
    // Each allowed `requestPermission(` call is listed here with its reason.
    const allowedRequestCalls = {
      'lib/features/onboarding/data/device_locator.dart':
          'Geolocator.requestPermission() asks for location, not notifications',
    };

    // Tokens that would mean a notification prompt or service in onboarding.
    const forbidden = [
      'NotificationService',
      'notificationServiceProvider',
      'notification_service',
      'notification_plugin',
      'notification_providers',
      'core/notifications',
      'flutter_local_notifications',
      'FlutterLocalNotificationsPlugin',
      'requestNotificationsPermission',
      'requestPermissions(',
    ];

    late List<File> dartFiles;

    setUpAll(() {
      dartFiles = Directory('lib/features/onboarding')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
    });

    test('scans a non-empty onboarding source tree', () {
      expect(dartFiles, isNotEmpty);
    });

    test('mentions no notification symbol', () {
      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        for (final token in forbidden) {
          expect(
            source,
            isNot(contains(token)),
            reason: '${file.path} mentions $token',
          );
        }
      }
    });

    test('calls requestPermission only on the allowlisted location path', () {
      for (final file in dartFiles) {
        final path = file.path.replaceAll(r'\', '/');
        final source = file.readAsStringSync();
        final lines = source
            .split('\n')
            .where((line) => line.contains('requestPermission('));
        if (lines.isEmpty) continue;

        expect(
          allowedRequestCalls.containsKey(path),
          isTrue,
          reason: '$path calls requestPermission( and is not allowlisted',
        );
        for (final line in lines) {
          expect(
            line,
            contains('Geolocator.requestPermission('),
            reason: '$path: only the Geolocator location call is allowed',
          );
        }
      }
    });
  });
}
