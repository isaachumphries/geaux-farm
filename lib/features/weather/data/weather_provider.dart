import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/weather.dart';
import '../domain/weather_staleness.dart';
import 'forecast_client.dart';
import 'weather_repository.dart';

/// The forecast client; override in tests with a `MockClient`-backed one.
final forecastClientProvider = Provider<OpenMeteoForecastClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OpenMeteoForecastClient(client);
});

/// Wall clock used for `fetchedAt` and staleness; override in tests.
final weatherClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final _refreshEvents = Provider<StreamController<DateTime>>((ref) {
  final controller = StreamController<DateTime>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

/// One event per successful save, carrying the fetch time. The care
/// recompute (#21) subscribes; this feature schedules nothing itself.
final weatherRefreshedProvider = StreamProvider<DateTime>(
  (ref) => ref.watch(_refreshEvents).stream,
);

/// The last good snapshot, plus the error from the most recent refresh if
/// that refresh failed (the UI then shows the cached data with its age).
class WeatherState {
  const WeatherState(
    this.snapshot, {
    this.refreshError,
    this.isOfflineStale = false,
  });

  final WeatherSnapshot snapshot;
  final Object? refreshError;

  /// True when a refresh failed and the cache behind [snapshot] is more
  /// than 3 hours old, which is when the UI adds the offline banner.
  final bool isOfflineStale;

  /// The daily rows, oldest first (7 past days, today, 6 ahead).
  List<WeatherDay> get days => snapshot.days;

  /// The `current` block of the last successful fetch.
  WeatherCurrent get current => snapshot.current;

  /// When that fetch happened.
  DateTime get fetchedAt => snapshot.fetchedAt;
}

/// The [weatherProvider] key for a place: coordinates rounded to 2
/// decimals, so small GPS jitter reuses the same forecast.
(double lat, double lon) forecastLocation(double lat, double lon) =>
    ((lat * 100).round() / 100, (lon * 100).round() / 100);

/// Forecast for one `(lat, lon)` (already rounded to 2 decimals, see
/// [forecastLocation]).
///
/// [WeatherNotifier.build] reads the Drift cache and fetches only when the
/// cache is missing or more than 60 minutes old.
/// [WeatherNotifier.refresh] follows the same rule unless `force` is set
/// (pull-to-refresh). A failed fetch with no cache is an [AsyncError]; a
/// failed fetch with one keeps the cached data and records `refreshError`.
final weatherProvider =
    AsyncNotifierProvider.family<
      WeatherNotifier,
      WeatherState,
      (double lat, double lon)
    >(
      WeatherNotifier.new,
      // One attempt per trigger: no automatic retries.
      retry: (_, _) => null,
    );

class WeatherNotifier extends AsyncNotifier<WeatherState> {
  WeatherNotifier(this.location);

  final (double lat, double lon) location;

  bool _inFlight = false;

  @override
  Future<WeatherState> build() async {
    final cached = await ref.read(weatherRepositoryProvider).loadCached();
    final now = ref.read(weatherClockProvider)();
    if (cached != null && !needsRefresh(cached.fetchedAt, now)) {
      return WeatherState(cached);
    }
    if (cached == null) return WeatherState(await _fetchAndSave());
    try {
      return WeatherState(await _fetchAndSave());
    } catch (error) {
      return WeatherState(
        cached,
        refreshError: error,
        isOfflineStale: isOfflineStale(cached.fetchedAt, now),
      );
    }
  }

  /// Fetches once, saves the payload, and announces the refresh.
  Future<WeatherSnapshot> _fetchAndSave() async {
    final now = ref.read(weatherClockProvider)();
    final snapshot = await ref
        .read(forecastClientProvider)
        .fetchForecast(location.$1, location.$2, fetchedAt: now);
    await ref.read(weatherRepositoryProvider).saveForecast(snapshot, now);
    ref.read(_refreshEvents).add(now);
    return snapshot;
  }

  /// App start/resume call this plainly; pull-to-refresh and Retry pass
  /// `force: true`. With no snapshot yet it always fetches.
  Future<void> refresh({bool force = false}) async {
    if (_inFlight) return;
    final previous = state.value?.snapshot;
    final now = ref.read(weatherClockProvider)();
    if (previous != null && !force && !needsRefresh(previous.fetchedAt, now)) {
      return;
    }
    _inFlight = true;
    try {
      if (previous == null) state = const AsyncLoading();
      state = AsyncData(WeatherState(await _fetchAndSave()));
    } catch (e, st) {
      state = previous == null
          ? AsyncError(e, st)
          : AsyncData(
              WeatherState(
                previous,
                refreshError: e,
                isOfflineStale: isOfflineStale(previous.fetchedAt, now),
              ),
            );
    } finally {
      _inFlight = false;
    }
  }
}
