import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';

void main() {
  test('stored text matches care_events.type', () {
    expect(
      {for (final t in CareEventType.values) t: t.stored},
      {
        CareEventType.water: 'water',
        CareEventType.skipWater: 'skip_water',
        CareEventType.fertilize: 'fertilize',
        CareEventType.prune: 'prune',
        CareEventType.harvest: 'harvest',
        CareEventType.note: 'note',
      },
    );
  });

  test('fromStored round-trips and rejects unknown text', () {
    for (final t in CareEventType.values) {
      expect(CareEventType.fromStored(t.stored), t);
    }
    expect(() => CareEventType.fromStored('skipWater'), throwsFormatException);
  });
}
