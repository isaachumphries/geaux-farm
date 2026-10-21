import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/local/data/markets_provider.dart';
import 'package:geaux_farm/features/local/data/overpass_client.dart';
import 'package:geaux_farm/features/local/domain/map_links.dart';
import 'package:geaux_farm/features/local/domain/market.dart';
import 'package:geaux_farm/features/onboarding/data/default_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// plan/08 § Markets: the list is cached in memory for 24 h, so a second
// read inside the window never calls Overpass (AGENTS.md § 7: no tight
// loops, no re-query while the cache is valid).

final _fixture = {
  'elements': [
    {
      'type': 'node',
      'id': 3001,
      'lat': 29.95,
      'lon': -90.07,
      'tags': {'amenity': 'marketplace', 'name': 'Crescent City'},
    },
  ],
};

/// The plan's Baton Rouge fixture location, which the default profile
/// already carries.
UserProfile _profile() => defaultUserProfile;

void main() {
  late DateTime now;
  late int calls;
  late bool fail;
  late ProviderContainer container;
  late List<Uri> launched;

  setUp(() {
    MarketsNotifier.resetCache();
    addTearDown(MarketsNotifier.resetCache);
    now = DateTime(2026, 10, 20, 9);
    calls = 0;
    fail = false;
    launched = [];
    container = ProviderContainer(
      overrides: [
        marketsClockProvider.overrideWithValue(() => now),
        mapPlatformProvider.overrideWithValue(MapPlatform.android),
        mapLauncherProvider.overrideWithValue((uri) async {
          launched.add(uri);
          return true;
        }),
        userProfileProvider.overrideWith((ref) => Stream.value(_profile())),
        overpassClientProvider.overrideWithValue(
          OverpassMarketsClient(
            AppHttpClient(
              MockClient((_) async {
                calls++;
                return fail
                    ? http.Response('down', 503)
                    : http.Response(jsonEncode(_fixture), 200);
              }),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  /// Keeps the provider listened to while its first build runs: a
  /// non-autoDispose provider with no listener is torn down before
  /// `.future` resolves.
  Future<List<Market>> read() {
    final sub = container.listen(marketsProvider, (_, _) {});
    addTearDown(sub.close);
    return container.read(marketsProvider.future);
  }

  test('the first read fetches and returns the markets', () async {
    final markets = await read();

    expect(calls, 1);
    expect(markets.single.name, 'Crescent City');
  });

  test('a second read inside 24 h never calls the network', () async {
    await read();
    container.invalidate(marketsProvider);
    now = now.add(const Duration(hours: 23, minutes: 59));

    final markets = await read();

    expect(calls, 1);
    expect(markets.single.name, 'Crescent City');
  });

  test('exactly 24 h still uses the cache; past it refetches', () async {
    await read();
    container.invalidate(marketsProvider);
    now = now.add(const Duration(hours: 24));
    await read();
    expect(calls, 1);

    container.invalidate(marketsProvider);
    now = now.add(const Duration(seconds: 1));
    await read();
    expect(calls, 2);
  });

  test('refresh ignores the cache', () async {
    await read();
    await container.read(marketsProvider.notifier).refresh();

    expect(calls, 2);
  });

  test('a failed fetch is an error state with no retry', () async {
    fail = true;
    final sub = container.listen(marketsProvider, (_, _) {});
    addTearDown(sub.close);

    await expectLater(read(), throwsA(isA<NetworkException>()));

    expect(calls, 1);
    expect(container.read(marketsProvider).hasError, isTrue);
  });

  test('a failed fetch caches nothing, so Retry really retries', () async {
    fail = true;
    final sub = container.listen(marketsProvider, (_, _) {});
    addTearDown(sub.close);
    await expectLater(read(), throwsA(isA<NetworkException>()));

    fail = false;
    await container.read(marketsProvider.notifier).refresh();

    expect(calls, 2);
    expect(container.read(marketsProvider).requireValue, hasLength(1));
  });

  test('a row tap launches the platform maps URL once', () async {
    final markets = await read();

    await container.read(marketsProvider.notifier).openInMaps(markets.single);

    expect(launched, [Uri.parse('geo:29.95,-90.07?q=Crescent+City')]);
  });
}
