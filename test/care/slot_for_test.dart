import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/slot.dart';

import '../helpers/care_fixtures.dart';

// 2026-05-03 Sun, 05-04 Mon, 05-05 Tue, 05-06 Wed, 05-07 Thu.
// Block b starts at 06:00 + 2h × b: block 1 is 08:00, block 3 is 12:00.
void main() {
  group('slotFor', () {
    test('uses the earliest free block on the latest free day up to due', () {
      final a = careFree({
        1: [4],
        3: [1, 5],
      });
      expect(
        slotFor(DateTime(2026, 5, 6), a, DateTime(2026, 5, 4, 7)),
        DateTime(2026, 5, 6, 8),
      );
    });

    test('moves to the first free block after now when none is by due', () {
      final a = careFree({
        4: [3],
      });
      expect(
        slotFor(DateTime(2026, 5, 6), a, DateTime(2026, 5, 4, 7)),
        DateTime(2026, 5, 7, 12),
      );
    });

    test('skips a block that started before now', () {
      final a = careFree({
        1: [1, 2],
      });
      expect(
        slotFor(DateTime(2026, 5, 4), a, DateTime(2026, 5, 4, 9)),
        DateTime(2026, 5, 4, 10),
      );
    });

    test('counts a block that starts exactly at now', () {
      final a = careFree({
        1: [2],
      });
      expect(
        slotFor(DateTime(2026, 5, 4), a, DateTime(2026, 5, 4, 10)),
        DateTime(2026, 5, 4, 10),
      );
    });

    test('an overdue task takes the earliest free block from today', () {
      final a = careFree({
        4: [3],
      });
      expect(
        slotFor(DateTime(2026, 5, 3), a, DateTime(2026, 5, 4, 7)),
        DateTime(2026, 5, 7, 12),
      );
    });

    test('caps the search at the 14-day window', () {
      // Due 06-30 is past the window, which ends Sun 05-17. The search starts
      // there and walks back to Mon 05-11, the latest free Monday inside it.
      final a = careFree({
        1: [1],
      });
      expect(
        slotFor(DateTime(2026, 6, 30), a, DateTime(2026, 5, 4, 7)),
        DateTime(2026, 5, 11, 8),
      );
    });
  });

  group('findSlot', () {
    test('flags 08:00 on the due date when no block is free in the window', () {
      expect(
        findSlot(DateTime(2026, 5, 6), careFree({}), DateTime(2026, 5, 4, 7)),
        CareSlot(start: DateTime(2026, 5, 6, 8), outsideFreeTimes: true),
      );
    });

    test('is not flagged when a free block is found', () {
      final slot = findSlot(
        DateTime(2026, 5, 6),
        careFree({
          3: [0],
        }),
        DateTime(2026, 5, 4, 7),
      );
      expect(slot.outsideFreeTimes, isFalse);
      expect(slot.start, DateTime(2026, 5, 6, 6));
    });
  });
}
