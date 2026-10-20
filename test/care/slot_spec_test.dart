// Scheduling into free time (plan/05 § Scheduling into free time, and the
// slotFor rows of § Tests): block hours, day and week wrap, the 14-day
// candidate window, and the "Outside your free times" fallback.
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/slot.dart';

import '../helpers/care_fixtures.dart';

// 2026-05-04 is a Monday. careFree keys are ISO weekdays (1 = Monday).
final _mon = DateTime(2026, 5, 4);

DateTime _at(int dayOffset, [int hour = 0, int minute = 0]) =>
    DateTime(_mon.year, _mon.month, _mon.day + dayOffset, hour, minute);

void main() {
  group('plan/05 § Tests rows', () {
    test('due Thu, Mon/Wed/Sat block 6, now Mon 20:30 → Wed 18:00', () {
      final a = careFree({
        1: [6],
        3: [6],
        6: [6],
      });
      expect(slotFor(_at(3), a, _at(0, 20, 30)), _at(2, 18));
    });

    test("due today, today's only block already past → next one", () {
      final a = careFree({
        1: [0],
      });
      expect(slotFor(_at(0), a, _at(0, 9)), _at(7, 6));
    });

    test('blocks 0 and 6 every day, due Fri, now Wed → Fri 06:00', () {
      final a = careFree({
        for (var d = 1; d <= 7; d++) d: [0, 6],
      });
      expect(slotFor(_at(4), a, _at(2, 12)), _at(4, 6));
    });
  });

  group('block start hour = 6 + 2·block', () {
    for (final b in [0, 3, 7]) {
      test('block $b starts at ${6 + 2 * b}:00', () {
        final a = careFree({
          1: [b],
        });
        expect(slotFor(_at(0), a, _at(0)), _at(0, 6 + 2 * b));
      });
    }
  });

  test('day wrap: after the last block starts, today has no slot', () {
    final a = careFree({
      1: [7],
      2: [7],
    });
    expect(slotFor(_at(0), a, _at(0, 20, 1)), _at(1, 20));
  });

  test('week wrap backward: due Mon, picks the Sunday before it', () {
    // Saturday 20:00 is also free, so stepping back two days would show.
    final a = careFree({
      6: [7],
      7: [0],
    });
    expect(slotFor(_at(7), a, _at(5, 7)), _at(6, 6));
  });

  test('week wrap forward: Sunday night past due rolls to Monday', () {
    final a = careFree({
      1: [0],
    });
    expect(slotFor(_at(6), a, _at(6, 21)), _at(7, 6));
  });

  group('14-day candidate window', () {
    final a = careFree({
      6: [0],
      7: [0],
      1: [0],
    });

    test('a task due on day 13 can land on day 13', () {
      expect(slotFor(_at(13), a, _at(0, 7)), _at(13, 6));
    });

    test('a task due on day 14 is capped back to day 13', () {
      expect(slotFor(_at(14), a, _at(0, 7)), _at(13, 6));
    });
  });

  group('Outside your free times', () {
    test('uses 08:00 on an overdue due date', () {
      expect(
        findSlot(_at(-3), careFree({}), _at(0, 7)),
        CareSlot(start: _at(-3, 8), outsideFreeTimes: true),
      );
    });

    test('uses 08:00 on a due date past the window', () {
      expect(
        findSlot(_at(20, 15), careFree({}), _at(0, 7)),
        CareSlot(start: _at(20, 8), outsideFreeTimes: true),
      );
    });
  });
}
