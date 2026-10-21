import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/weather/domain/weather_staleness.dart';

// plan/06 § Caching and refresh: app start and resume refetch once the
// cache passes 60 minutes, and the offline banner appears once it passes
// 3 hours. Both boundaries are inclusive on the fresh side.
void main() {
  final fetched = DateTime(2026, 10, 13, 12);
  DateTime after(Duration d) => fetched.add(d);

  group('needsRefresh', () {
    test('59 min → no', () {
      expect(
        needsRefresh(fetched, after(const Duration(minutes: 59))),
        isFalse,
      );
    });
    test('exactly 60:00 → no', () {
      expect(
        needsRefresh(fetched, after(const Duration(minutes: 60))),
        isFalse,
      );
    });
    test('60:01 → yes', () {
      expect(
        needsRefresh(fetched, after(const Duration(minutes: 60, seconds: 1))),
        isTrue,
      );
    });
    test('61 min → yes', () {
      expect(needsRefresh(fetched, after(const Duration(minutes: 61))), isTrue);
    });
  });

  group('isOfflineStale', () {
    test('2 h → no', () {
      expect(isOfflineStale(fetched, after(const Duration(hours: 2))), isFalse);
    });
    test('exactly 3:00:00 → no', () {
      expect(isOfflineStale(fetched, after(const Duration(hours: 3))), isFalse);
    });
    test('3:00:01 → yes', () {
      expect(
        isOfflineStale(fetched, after(const Duration(hours: 3, seconds: 1))),
        isTrue,
      );
    });
    test('4 h → yes', () {
      expect(isOfflineStale(fetched, after(const Duration(hours: 4))), isTrue);
    });
  });
}
