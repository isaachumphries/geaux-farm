import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/care/domain/care_tasks.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';

final _planted = DateTime(2026, 5, 1);

Planting _planting({String id = 'p1', DateTime? plantedOn}) => Planting(
  id: id,
  plantId: 'cherry-tomato',
  spaceId: 's1',
  nickname: 'Tomato',
  setup: GrowSetup.outdoor,
  inContainer: false,
  startMethod: 'transplant',
  plantedOn: plantedOn ?? _planted,
  status: PlantingStatus.active,
  createdAt: DateTime(2026, 4, 1),
);

CareEvent _event(
  CareEventType type,
  DateTime at, {
  String plantingId = 'p1',
  String? note,
}) => CareEvent(
  id: '${type.name}-${at.toIso8601String()}',
  plantingId: plantingId,
  type: type,
  at: at,
  note: note,
);

void main() {
  const prune = CareTask(
    type: TaskType.prune,
    everyDays: 7,
    note: 'Tie to the stake',
  );
  const fertilize = CareTask(
    type: TaskType.fertilize,
    everyDays: 14,
    note: 'Tomato fertilizer',
  );
  const harvest = CareTask(
    type: TaskType.harvest,
    everyDays: 3,
    note: 'Pick ripe fruit',
  );
  const other = CareTask(
    type: TaskType.other,
    everyDays: 5,
    note: 'Check for hornworms',
  );

  group('planCareTask due day', () {
    test('with no events, counts from planting day', () {
      final t = planCareTask(_planting(), prune, const []);
      expect(t.due, DateTime(2026, 5, 8));
      expect(t.kind, TaskType.prune);
      expect(t.plantingId, 'p1');
      expect(t.note, 'Tie to the stake');
    });

    test('restarts from the last matching event', () {
      final events = [
        _event(CareEventType.prune, DateTime(2026, 5, 3, 9)),
        _event(CareEventType.prune, DateTime(2026, 5, 4, 18)),
      ];
      final t = planCareTask(_planting(), prune, events);
      expect(t.due, DateTime(2026, 5, 11));
    });

    test('ignores events on other plantings', () {
      final events = [
        _event(CareEventType.prune, DateTime(2026, 5, 6), plantingId: 'p2'),
      ];
      final t = planCareTask(_planting(), prune, events);
      expect(t.due, DateTime(2026, 5, 8));
    });

    test('fertilize is not reset by a prune event', () {
      final events = [_event(CareEventType.prune, DateTime(2026, 5, 6))];
      final t = planCareTask(_planting(), fertilize, events);
      expect(t.due, DateTime(2026, 5, 15));
    });

    test('fertilize restarts from its own last event', () {
      final events = [_event(CareEventType.fertilize, DateTime(2026, 5, 10))];
      final t = planCareTask(_planting(), fertilize, events);
      expect(t.due, DateTime(2026, 5, 24));
    });

    test('other task is reset only by a note with the same text', () {
      final events = [
        _event(
          CareEventType.note,
          DateTime(2026, 5, 4),
          note: 'Something else',
        ),
        _event(CareEventType.note, DateTime(2026, 5, 6), note: other.note),
      ];
      final t = planCareTask(_planting(), other, events);
      expect(t.due, DateTime(2026, 5, 11));
      expect(t.note, 'Check for hornworms');
    });

    test('harvest is reset by a harvest event', () {
      final events = [_event(CareEventType.harvest, DateTime(2026, 5, 20))];
      final t = planCareTask(_planting(), harvest, events);
      expect(t.due, DateTime(2026, 5, 23));
    });

    test('event time of day does not shift the due day', () {
      final late = [_event(CareEventType.prune, DateTime(2026, 5, 3, 23, 59))];
      final early = [_event(CareEventType.prune, DateTime(2026, 5, 3, 0, 1))];
      expect(
        planCareTask(_planting(), prune, late).due,
        planCareTask(_planting(), prune, early).due,
      );
    });

    test('throws when planting has no plantedOn and no event', () {
      final unplanted = Planting(
        id: 'p1',
        plantId: 'cherry-tomato',
        spaceId: 's1',
        nickname: 'Tomato',
        setup: GrowSetup.outdoor,
        inContainer: false,
        startMethod: 'transplant',
        status: PlantingStatus.planned,
        createdAt: DateTime(2026, 4, 1),
      );
      expect(
        () => planCareTask(unplanted, prune, const []),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('showsCareTask', () {
    test('harvest is hidden before maturity', () {
      expect(showsCareTask(harvest, 0.99), isFalse);
      expect(showsCareTask(harvest, 0), isFalse);
    });

    test('harvest is shown at full progress', () {
      expect(showsCareTask(harvest, 1), isTrue);
    });

    test('non-harvest tasks are always shown', () {
      expect(showsCareTask(prune, 0), isTrue);
      expect(showsCareTask(fertilize, 0.5), isTrue);
      expect(showsCareTask(other, 0), isTrue);
    });
  });

  group('PlantingTask equality', () {
    test('equal fields compare equal', () {
      final a = planCareTask(_planting(), prune, const []);
      final b = planCareTask(_planting(), prune, const []);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different due day is not equal', () {
      final a = planCareTask(_planting(), prune, const []);
      final b = planCareTask(
        _planting(),
        prune,
        [_event(CareEventType.prune, DateTime(2026, 5, 3))],
      );
      expect(a == b, isFalse);
    });
  });
}
