import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/app/widgets/widgets.dart';
import 'package:geaux_farm/features/care/application/care_schedule_provider.dart';
import 'package:geaux_farm/features/care/data/drift_care_schedule_repository.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/care/domain/care_schedule.dart';
import 'package:geaux_farm/features/care/domain/care_schedule_repository.dart';
import 'package:geaux_farm/features/care/domain/rain_hint.dart';
import 'package:geaux_farm/features/care/domain/slot.dart';
import 'package:geaux_farm/features/care/presentation/care_screen.dart';
import 'package:geaux_farm/features/care/presentation/widgets/day_selector.dart';
import 'package:geaux_farm/features/care/presentation/widgets/task_row.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';

/// Monday. Block 2 starts 10:00, block 5 starts 16:00.
final _now = DateTime(2026, 10, 5, 9);
final _today = DateTime(2026, 10, 5);

ScheduledCareTask _task(
  String name, {
  CareTaskKind kind = CareTaskKind.water,
  DateTime? due,
  required DateTime slot,
  bool outside = false,
  bool overdue = false,
  bool rainSkip = false,
  String? note,
}) => ScheduledCareTask(
  plantingId: 'p-$name',
  nickname: name,
  kind: kind,
  due: due ?? DateTime(slot.year, slot.month, slot.day),
  slot: CareSlot(start: slot, outsideFreeTimes: outside),
  overdue: overdue,
  rainSkip: rainSkip,
  note: note,
);

class _LoggedEvent {
  _LoggedEvent(this.plantingId, this.type, this.at, this.note);

  final String plantingId;
  final CareEventType type;
  final DateTime at;
  final String? note;
}

class _FakeRepo implements CareScheduleRepository {
  final logged = <_LoggedEvent>[];

  /// When set, writes wait on it, like a slow disk.
  Completer<void>? gate;

  @override
  Stream<List<CareEvent>> watchCareEvents() => const Stream.empty();

  @override
  Future<void> logCareEvent({
    required String plantingId,
    required CareEventType type,
    required DateTime at,
    String? note,
  }) async {
    logged.add(_LoggedEvent(plantingId, type, at, note));
    await gate?.future;
  }
}

/// The fake schedule the screen reads; tests replace it to simulate the
/// recompute that follows a logged event.
final _tasks = NotifierProvider<_Tasks, List<ScheduledCareTask>>(_Tasks.new);

class _Tasks extends Notifier<List<ScheduledCareTask>> {
  List<ScheduledCareTask> _initial = const [];

  @override
  List<ScheduledCareTask> build() => _initial;

  void set(List<ScheduledCareTask> tasks) => state = tasks;
}

Future<_FakeRepo> _pump(
  WidgetTester tester,
  List<ScheduledCareTask> tasks, {
  DateTime? date,
  _FakeRepo? repo,
}) async {
  repo ??= _FakeRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => _now),
        careScheduleRepositoryProvider.overrideWithValue(repo),
        _tasks.overrideWith(() => _Tasks().._initial = tasks),
        careScheduleProvider.overrideWith((ref) async => ref.watch(_tasks)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: CareScreen(date: date),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return repo;
}

DateTime _selected(WidgetTester tester) =>
    tester.widget<CareDaySelector>(find.byType(CareDaySelector)).selected;

TaskRowState _stateOf(WidgetTester tester, String title) => tester
    .widget<TaskRow>(
      find.ancestor(of: find.text(title), matching: find.byType(TaskRow)),
    )
    .state;

double _y(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  final tasks = [
    _task('Kale', slot: DateTime(2026, 10, 5, 10)),
    _task(
      'Basil',
      kind: CareTaskKind.fertilize,
      slot: DateTime(2026, 10, 5, 16),
    ),
    _task(
      'Mint',
      kind: CareTaskKind.prune,
      slot: DateTime(2026, 10, 5, 8),
    ).withOverdue(DateTime(2026, 10, 3)),
    _task(
      'Okra',
      kind: CareTaskKind.harvest,
      slot: DateTime(2026, 10, 5, 8),
      outside: true,
    ),
    _task('Fern', slot: DateTime(2026, 10, 6, 6)),
    _task('Chard', slot: DateTime(2026, 10, 7, 12)),
  ];

  group('day selection', () {
    testWidgets('selects today without a date', (tester) async {
      await _pump(tester, tasks);
      expect(_selected(tester), _today);
    });

    testWidgets('shows today and the next six days', (tester) async {
      await _pump(tester, tasks);
      final days = tester
          .widget<CareDaySelector>(find.byType(CareDaySelector))
          .days;
      expect(days, [for (var i = 0; i < 7; i++) DateTime(2026, 10, 5 + i)]);
    });

    testWidgets('/care?date=2026-10-07 selects 2026-10-07', (tester) async {
      await _pump(tester, tasks, date: DateTime(2026, 10, 7));
      expect(_selected(tester), DateTime(2026, 10, 7));
      expect(find.text('Water Chard'), findsOneWidget);
      expect(find.text('Water Kale'), findsNothing);
    });

    testWidgets('a date before today selects today', (tester) async {
      await _pump(tester, tasks, date: DateTime(2026, 9, 1));
      expect(_selected(tester), _today);
      expect(find.text('Water Kale'), findsOneWidget);
    });

    testWidgets('a date after today+6 selects today', (tester) async {
      await _pump(tester, tasks, date: DateTime(2026, 10, 12));
      expect(_selected(tester), _today);
    });

    testWidgets('a new date query replaces an earlier pick', (tester) async {
      Widget app(DateTime? date) => ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => _now),
          careScheduleProvider.overrideWith((ref) async => tasks),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: CareScreen(date: date),
        ),
      );
      await tester.pumpWidget(app(null));
      await tester.pump();
      await tester.tap(find.text('9'));
      await tester.pump();
      expect(_selected(tester), DateTime(2026, 10, 9));

      await tester.pumpWidget(app(DateTime(2026, 10, 7)));
      await tester.pump();
      expect(_selected(tester), DateTime(2026, 10, 7));
    });

    testWidgets('today+6 is allowed', (tester) async {
      await _pump(tester, tasks, date: DateTime(2026, 10, 11));
      expect(_selected(tester), DateTime(2026, 10, 11));
    });

    testWidgets('tapping a day loads its tasks', (tester) async {
      await _pump(tester, tasks);
      await tester.tap(find.text('7'));
      await tester.pump();
      expect(_selected(tester), DateTime(2026, 10, 7));
      expect(find.text('Water Chard'), findsOneWidget);
      expect(find.text('Water Kale'), findsNothing);
    });
  });

  group('sections', () {
    testWidgets('Overdue is above the time groups on today', (tester) async {
      await _pump(tester, tasks);
      expect(find.text('OVERDUE'), findsOneWidget);
      expect(_stateOf(tester, 'Prune Mint'), TaskRowState.overdue);
      expect(find.text('Overdue · 2 days'), findsOneWidget);
      expect(_y(tester, 'OVERDUE'), lessThan(_y(tester, '10:00 AM')));
      expect(_y(tester, 'Prune Mint'), lessThan(_y(tester, '10:00 AM')));
    });

    testWidgets('Overdue is absent on tomorrow', (tester) async {
      await _pump(tester, tasks, date: DateTime(2026, 10, 6));
      expect(find.text('OVERDUE'), findsNothing);
      expect(find.text('Prune Mint'), findsNothing);
      expect(find.text('Water Fern'), findsOneWidget);
    });

    testWidgets('groups are labelled by slot start, in order', (tester) async {
      await _pump(tester, tasks);
      expect(find.text('10:00 AM'), findsOneWidget);
      expect(find.text('4:00 PM'), findsOneWidget);
      expect(_y(tester, '10:00 AM'), lessThan(_y(tester, '4:00 PM')));
      expect(_y(tester, 'Water Kale'), greaterThan(_y(tester, '10:00 AM')));
      expect(_y(tester, 'Water Kale'), lessThan(_y(tester, '4:00 PM')));
      expect(_y(tester, 'Fertilize Basil'), greaterThan(_y(tester, '4:00 PM')));
    });

    testWidgets('Outside your free times is its own last group', (
      tester,
    ) async {
      await _pump(tester, tasks);
      final label = outsideFreeTimesCopy.toUpperCase();
      expect(find.text(label), findsOneWidget);
      expect(_y(tester, label), greaterThan(_y(tester, '4:00 PM')));
      expect(_y(tester, 'Harvest Okra'), greaterThan(_y(tester, label)));
      // Not also listed under 8:00 AM.
      expect(find.text('8:00 AM'), findsNothing);
    });

    testWidgets('a rain-skip water task shows its state', (tester) async {
      await _pump(tester, [
        _task('Kale', slot: DateTime(2026, 10, 5, 10), rainSkip: true),
      ]);
      expect(find.text(rainSkipCopy), findsOneWidget);
      expect(_stateOf(tester, 'Water Kale'), TaskRowState.rainSkip);
    });

    testWidgets('a plain task is due', (tester) async {
      await _pump(tester, tasks);
      expect(_stateOf(tester, 'Water Kale'), TaskRowState.due);
    });
  });

  group('swipe to done', () {
    testWidgets('logs one water event and the row shows done', (tester) async {
      final repo = await _pump(tester, tasks);
      await tester.drag(find.text('Water Kale'), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(repo.logged, hasLength(1));
      expect(repo.logged.single.plantingId, 'p-Kale');
      expect(repo.logged.single.type, CareEventType.water);
      expect(repo.logged.single.at, _now);
      expect(_stateOf(tester, 'Water Kale'), TaskRowState.done);
      expect(find.text('Done at 9:00 AM'), findsOneWidget);
      // Other rows are untouched.
      expect(_stateOf(tester, 'Fertilize Basil'), TaskRowState.due);
    });

    testWidgets('a second tap while the write is pending logs once', (
      tester,
    ) async {
      final repo = _FakeRepo()..gate = Completer<void>();
      await _pump(tester, tasks, repo: repo);
      final check = find.descendant(
        of: find.ancestor(
          of: find.text('Water Kale'),
          matching: find.byType(TaskRow),
        ),
        matching: find.byIcon(Symbols.check_rounded),
      );
      await tester.tap(check);
      await tester.pump();
      await tester.tap(check);
      await tester.pump();
      expect(repo.logged, hasLength(1));
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(_stateOf(tester, 'Water Kale'), TaskRowState.done);
      expect(repo.logged, hasLength(1));
    });

    testWidgets('a done row cannot be swiped again', (tester) async {
      final repo = await _pump(tester, tasks);
      await tester.drag(find.text('Water Kale'), const Offset(400, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.text('Water Kale'), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(repo.logged, hasLength(1));
    });

    testWidgets('swiping an overdue row logs its own type', (tester) async {
      final repo = await _pump(tester, tasks);
      await tester.drag(find.text('Prune Mint'), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(repo.logged.single.type, CareEventType.prune);
      expect(_stateOf(tester, 'Prune Mint'), TaskRowState.done);
    });

    testWidgets('swiping a rainSkip row logs water', (tester) async {
      final repo = await _pump(tester, [
        _task('Kale', slot: DateTime(2026, 10, 5, 10), rainSkip: true),
      ]);
      await tester.drag(find.text('Water Kale'), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(repo.logged.single.type, CareEventType.water);
      expect(_stateOf(tester, 'Water Kale'), TaskRowState.done);
    });

    testWidgets('an other task logs a note event with its note', (
      tester,
    ) async {
      final repo = await _pump(tester, [
        _task(
          'Kale',
          kind: CareTaskKind.other,
          slot: DateTime(2026, 10, 5, 10),
          note: 'Check for aphids',
        ),
      ]);
      await tester.drag(find.text('Check for aphids'), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(repo.logged.single.type, CareEventType.note);
      expect(repo.logged.single.note, 'Check for aphids');
    });

    testWidgets('the done row stays after the schedule recomputes', (
      tester,
    ) async {
      final repo = await _pump(tester, tasks);
      await tester.drag(find.text('Water Kale'), const Offset(400, 0));
      await tester.pumpAndSettle();

      // The logged event moves Kale's next water out of today.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CareScreen)),
      );
      container.read(_tasks.notifier).set([
        for (final t in tasks)
          if (t.nickname != 'Kale') t,
        _task('Kale', slot: DateTime(2026, 10, 8, 10)),
      ]);
      await tester.pump();
      await tester.pump();

      expect(_stateOf(tester, 'Water Kale'), TaskRowState.done);
      expect(repo.logged, hasLength(1));
    });
  });

  group('empty', () {
    testWidgets('a day with no tasks shows the empty state', (tester) async {
      await _pump(tester, tasks, date: DateTime(2026, 10, 9));
      expect(find.byType(GeauxEmptyState), findsOneWidget);
      expect(find.text(careEmptyCopy), findsOneWidget);
      expect(find.byType(TaskRow), findsNothing);
    });

    testWidgets('no tasks at all shows the empty state on today', (
      tester,
    ) async {
      await _pump(tester, const []);
      expect(find.byType(GeauxEmptyState), findsOneWidget);
      expect(find.text('Nothing due today.'), findsOneWidget);
    });
  });

  testWidgets('a day chip shows a dot only when it has tasks', (tester) async {
    await _pump(tester, tasks);
    final selector = tester.widget<CareDaySelector>(
      find.byType(CareDaySelector),
    );
    expect(selector.hasTasks(_today), isTrue);
    expect(selector.hasTasks(DateTime(2026, 10, 6)), isTrue);
    expect(selector.hasTasks(DateTime(2026, 10, 9)), isFalse);
  });
}

extension on ScheduledCareTask {
  ScheduledCareTask withOverdue(DateTime due) => ScheduledCareTask(
    plantingId: plantingId,
    nickname: nickname,
    kind: kind,
    due: due,
    slot: slot,
    overdue: true,
    note: note,
  );
}
