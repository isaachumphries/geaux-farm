/// Cache-age rules for the forecast (plan/06 § Caching and refresh).
///
/// Pure: the caller passes `now`. The 60-minute rule also keeps the app
/// inside Open-Meteo's free non-commercial terms (AGENTS.md § 7).
library;

/// A cache older than this is refetched on app start or resume.
const refreshAfter = Duration(minutes: 60);

/// A cache older than this is shown behind the offline banner.
const offlineStaleAfter = Duration(hours: 3);

/// True when the last successful fetch is more than 60 minutes old.
/// Exactly 60:00 is still fresh; 60:01 is not.
bool needsRefresh(DateTime fetchedAt, DateTime now) =>
    now.difference(fetchedAt) > refreshAfter;

/// True when the cache is more than 3 hours old, which is when the UI adds
/// the offline "Showing saved weather" banner. Exactly 3:00:00 is not stale.
bool isOfflineStale(DateTime fetchedAt, DateTime now) =>
    now.difference(fetchedAt) > offlineStaleAfter;
