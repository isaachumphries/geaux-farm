import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/care/domain/rain_hint.dart';
import 'package:geaux_farm/features/care/presentation/widgets/task_row.dart';

Future<void> _pump(WidgetTester tester, TaskRow row) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Center(child: row)),
  ),
);

TaskRow _row(
  TaskRowType type,
  TaskRowState state, {
  VoidCallback? onDone,
  String? note,
}) => TaskRow(
  type: type,
  state: state,
  plantName: 'Kale',
  note: note,
  overdueDays: 2,
  doneAt: '6:12 AM',
  onDone: onDone,
);

void main() {
  const titles = {
    TaskRowType.water: 'Water Kale',
    TaskRowType.fertilize: 'Fertilize Kale',
    TaskRowType.prune: 'Prune Kale',
    TaskRowType.harvest: 'Harvest Kale',
  };

  group('every type renders in every state', () {
    for (final MapEntry(key: type, value: title) in titles.entries) {
      for (final state in TaskRowState.values) {
        testWidgets('${type.name} ${state.name}', (tester) async {
          await _pump(tester, _row(type, state));
          expect(find.text(title), findsOneWidget);
          switch (state) {
            case TaskRowState.due:
              expect(find.textContaining('Overdue'), findsNothing);
              expect(find.text(rainSkipCopy), findsNothing);
              expect(find.textContaining('Done'), findsNothing);
            case TaskRowState.overdue:
              expect(find.text('Overdue · 2 days'), findsOneWidget);
            case TaskRowState.rainSkip:
              expect(find.text(rainSkipCopy), findsOneWidget);
            case TaskRowState.done:
              expect(find.text('Done at 6:12 AM'), findsOneWidget);
          }
        });
      }
    }
  });

  testWidgets('rainSkip shows the exact copy', (tester) async {
    await _pump(tester, _row(TaskRowType.water, TaskRowState.rainSkip));
    expect(find.text('Rain expected tomorrow — consider skipping'), findsOne);
  });

  testWidgets('overdue by one day says "1 day"', (tester) async {
    await _pump(
      tester,
      const TaskRow(
        type: TaskRowType.water,
        state: TaskRowState.overdue,
        plantName: 'Kale',
        overdueDays: 1,
      ),
    );
    expect(find.text('Overdue · 1 day'), findsOneWidget);
  });

  testWidgets('a done row is struck through', (tester) async {
    await _pump(tester, _row(TaskRowType.water, TaskRowState.done));
    final title = tester.widget<Text>(find.text('Water Kale'));
    expect(title.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('an other task is titled by its note', (tester) async {
    await _pump(
      tester,
      _row(TaskRowType.other, TaskRowState.due, note: 'Check for aphids'),
    );
    expect(find.text('Check for aphids'), findsOneWidget);
    expect(find.text('Kale'), findsOneWidget);
  });

  group('swipe right', () {
    for (final state in [
      TaskRowState.due,
      TaskRowState.overdue,
      TaskRowState.rainSkip,
    ]) {
      testWidgets('marks a ${state.name} row done once', (tester) async {
        var done = 0;
        await _pump(
          tester,
          _row(TaskRowType.water, state, onDone: () => done++),
        );
        await tester.drag(find.byType(TaskRow), const Offset(400, 0));
        await tester.pumpAndSettle();
        expect(done, 1);
      });
    }

    testWidgets('left swipe does nothing', (tester) async {
      var done = 0;
      await _pump(
        tester,
        _row(TaskRowType.water, TaskRowState.due, onDone: () => done++),
      );
      await tester.drag(find.byType(TaskRow), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(done, 0);
    });

    testWidgets('a done row ignores a swipe', (tester) async {
      var done = 0;
      await _pump(
        tester,
        _row(TaskRowType.water, TaskRowState.done, onDone: () => done++),
      );
      await tester.drag(find.byType(TaskRow), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(done, 0);
      expect(find.byType(Dismissible), findsNothing);
    });
  });

  testWidgets('tapping the check marks the row done', (tester) async {
    var done = 0;
    await _pump(
      tester,
      _row(TaskRowType.water, TaskRowState.due, onDone: () => done++),
    );
    await tester.tap(find.byIcon(Symbols.check_rounded));
    expect(done, 1);
  });
}
