import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/domain/guide_labels.dart';

void main() {
  group('guideSetupLabel', () {
    test('minutes under an hour read in minutes', () {
      expect(guideSetupLabel(45), '~45 min');
      expect(guideSetupLabel(0), '~0 min');
    });

    test('whole hours read as hours, one hour singular', () {
      expect(guideSetupLabel(60), '~1 hour');
      expect(guideSetupLabel(120), '~2 hours');
    });

    test('other times round to the nearest half hour', () {
      expect(guideSetupLabel(90), '~1.5 hours');
      expect(guideSetupLabel(100), '~1.5 hours');
      expect(guideSetupLabel(140), '~2.5 hours');
      expect(guideSetupLabel(74), '~1 hour');
      expect(guideSetupLabel(75), '~1.5 hours');
    });

    test('no setup time reads as a dash', () {
      expect(guideSetupLabel(null), '—');
    });
  });

  group('guideCostLabel', () {
    test('dollars, or a dash when the author gave none', () {
      expect(guideCostLabel(35), '\$35');
      expect(guideCostLabel(0), '\$0');
      expect(guideCostLabel(null), '—');
    });
  });
}
