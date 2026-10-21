import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/http.dart';
import '../../onboarding/data/profile_providers.dart';
import '../domain/map_links.dart';
import '../domain/market.dart';
import 'overpass_client.dart';

/// How long a fetched market list stays good. Overpass asks callers not to
/// re-query needlessly (AGENTS.md § 7), and markets rarely move.
const marketsCacheTtl = Duration(hours: 24);

/// The Overpass client; override in tests with a mocked HTTP layer.
final overpassClientProvider = Provider<OverpassMarketsClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OverpassMarketsClient(AppHttpClient(client));
});

/// Wall clock used for cache ages; override in tests.
final marketsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Which maps scheme to build; override in tests.
final mapPlatformProvider = Provider<MapPlatform>(
  (ref) => !kIsWeb && Platform.isIOS ? MapPlatform.ios : MapPlatform.android,
);

/// Opens a maps deep link; override in tests.
final mapLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// One cached fetch.
class _CachedMarkets {
  const _CachedMarkets(this.markets, this.fetchedAt);

  final List<Market> markets;
  final DateTime fetchedAt;
}

/// Markets near the profile location, nearest first.
///
/// The list is held in memory for [marketsCacheTtl]; a read inside that
/// window never touches the network. Nothing is written to the device:
/// plan/08 keeps this cache in memory only.
final marketsProvider = AsyncNotifierProvider<MarketsNotifier, List<Market>>(
  MarketsNotifier.new,
  // One attempt per trigger; Retry is the user's job (plan/09 § Errors).
  retry: (_, _) => null,
);

class MarketsNotifier extends AsyncNotifier<List<Market>> {
  /// Survives a provider rebuild, so moving between tabs does not refetch.
  static _CachedMarkets? _cache;

  /// Drops the cache; tests and a location change use it.
  static void resetCache() => _cache = null;

  @override
  Future<List<Market>> build() async {
    final profile = await ref.watch(userProfileProvider.future);
    return _load(profile.lat, profile.lon);
  }

  Future<List<Market>> _load(double lat, double lon) async {
    final now = ref.read(marketsClockProvider)();
    final cached = _cache;
    // Inclusive on the fresh side, like the weather rule: exactly 24:00:00
    // old is still served from memory, 24:00:01 refetches.
    if (cached != null && now.difference(cached.fetchedAt) <= marketsCacheTtl) {
      return cached.markets;
    }
    final markets = await ref
        .read(overpassClientProvider)
        .fetchMarkets(lat, lon);
    _cache = _CachedMarkets(markets, now);
    return markets;
  }

  /// Refetches, ignoring the cache. Retry and pull-to-refresh call it.
  Future<void> refresh() async {
    resetCache();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(userProfileProvider.future);
      return _load(profile.lat, profile.lon);
    });
  }

  /// Opens [market] in the platform's maps app. One launch per tap.
  Future<bool> openInMaps(Market market) {
    final url = marketMapUrl(
      platform: ref.read(mapPlatformProvider),
      name: market.name,
      lat: market.lat,
      lon: market.lon,
    );
    return ref.read(mapLauncherProvider)(url);
  }
}
