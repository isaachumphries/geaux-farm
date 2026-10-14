import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/weather.dart';
import 'forecast_client.dart';

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

/// The last good snapshot, plus the error from the most recent refresh if
/// that refresh failed (the UI then shows the cached data with its age).
class WeatherState {
  const WeatherState(this.snapshot, {this.refreshError});

  final WeatherSnapshot snapshot;
  final Object? refreshError;
}

/// The [weatherProvider] key for a place: coordinates rounded to 2
/// decimals, so small GPS jitter reuses the same forecast.
(double lat, double lon) forecastLocation(double lat, double lon) =>
    ((lat * 100).round() / 100, (lon * 100).round() / 100);

/// Forecast for one `(lat, lon)` (already rounded to 2 decimals, see
/// [forecastLocation]).
///
/// Fetches on first build. [WeatherNotifier.refresh] refetches only when the
/// snapshot is stale (> 60 min) unless `force` is set (pull-to-refresh).
/// A build with no data that fails is an [AsyncError]; a later failed refresh
/// keeps the last snapshot and records `refreshError`.
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
  Future<WeatherState> build() async => WeatherState(await _fetch());

  Future<WeatherSnapshot> _fetch() {
    final now = ref.read(weatherClockProvider)();
    return ref
        .read(forecastClientProvider)
        .fetchForecast(location.$1, location.$2, fetchedAt: now);
  }

  /// App start/resume call this plainly; pull-to-refresh and Retry pass
  /// `force: true`. With no snapshot yet it always fetches.
  Future<void> refresh({bool force = false}) async {
    if (_inFlight) return;
    final previous = state.value?.snapshot;
    if (previous != null && !force) {
      final now = ref.read(weatherClockProvider)();
      if (!isStale(previous.fetchedAt, now)) return;
    }
    _inFlight = true;
    try {
      if (previous == null) state = const AsyncLoading();
      final snapshot = await _fetch();
      state = AsyncData(WeatherState(snapshot));
    } catch (e, st) {
      state = previous == null
          ? AsyncError(e, st)
          : AsyncData(WeatherState(previous, refreshError: e));
    } finally {
      _inFlight = false;
    }
  }
}
