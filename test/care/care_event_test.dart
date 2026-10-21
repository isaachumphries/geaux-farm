import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';

CareEvent _event({
  String id = 'e1',
  String plantingId = 'p1',
  CareEventType type = CareEventType.water,
  DateTime? at,
  String? note,
  String? photoPath,
}) => CareEvent(
  id: id,
  plantingId: plantingId,
  type: type,
  at: at ?? DateTime(2026, 5, 3, 8),
  note: note,
  photoPath: photoPath,
);

void main() {
  group('CareEvent equality', () {
    test('same fields are equal and hash alike', () {
      final a = _event(note: 'soaked', photoPath: 'p.jpg');
      final b = _event(note: 'soaked', photoPath: 'p.jpg');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when any single field differs', () {
      final base = _event(note: 'n', photoPath: 'p');
      expect(base, isNot(equals(_event(id: 'e2', note: 'n', photoPath: 'p'))));
      expect(
        base,
        isNot(equals(_event(plantingId: 'p2', note: 'n', photoPath: 'p'))),
      );
      expect(
        base,
        isNot(
          equals(
            _event(type: CareEventType.fertilize, note: 'n', photoPath: 'p'),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            _event(at: DateTime(2026, 5, 4, 8), note: 'n', photoPath: 'p'),
          ),
        ),
      );
      expect(base, isNot(equals(_event(note: 'other', photoPath: 'p'))));
      expect(base, isNot(equals(_event(note: 'n'))));
    });

    test('null note differs from empty note', () {
      expect(_event(), isNot(equals(_event(note: ''))));
    });
  });
}
