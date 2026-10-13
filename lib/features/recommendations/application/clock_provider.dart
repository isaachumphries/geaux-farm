import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The wall clock. Domain code takes explicit dates (plan/09), so screens
/// and providers read "now" through this; tests override it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Today's local date (midnight), from [clockProvider]. It moves to the
/// next date at local midnight, so anything watching it recomputes when the
/// calendar day changes.
final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);

class TodayNotifier extends Notifier<DateTime> {
  Timer? _midnight;

  @override
  DateTime build() {
    ref.onDispose(() => _midnight?.cancel());
    return _dateAndScheduleNext(ref.watch(clockProvider));
  }

  DateTime _dateAndScheduleNext(DateTime Function() clock) {
    final now = clock();
    _midnight?.cancel();
    _midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () => state = _dateAndScheduleNext(clock),
    );
    return DateTime(now.year, now.month, now.day);
  }
}
