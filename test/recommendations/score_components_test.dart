import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/domain/score_plant.dart';

void main() {
  group('light', () {
    test('partial vs [full] → 0.5', () {
      expect(lightFit(SunLevel.partial, [SunLevel.full]), 0.5);
    });
    test('full vs [partial, full] → 1', () {
      expect(lightFit(SunLevel.full, [SunLevel.partial, SunLevel.full]), 1);
    });
    test('shade vs [full] → 0', () {
      expect(lightFit(SunLevel.shade, [SunLevel.full]), 0);
    });
    test('nearest level wins: shade vs [shade, full] → 1', () {
      expect(lightFit(SunLevel.shade, [SunLevel.full, SunLevel.shade]), 1);
    });
  });

  group('experience', () {
    test('beginner vs expert plant → 0.2', () {
      expect(experienceFit(3, Experience.beginner), 0.2);
    });
    test('intermediate vs difficulty 3 → 0.5', () {
      expect(experienceFit(3, Experience.intermediate), 0.5);
    });
    test('beginner vs beginner → 1', () {
      expect(experienceFit(1, Experience.beginner), 1);
    });
    test('expert vs easy plant (d < 0) → 1', () {
      expect(experienceFit(1, Experience.expert), 1);
    });
  });

  group('care required days', () {
    final cases = {1: 7, 2: 4, 3: 3, 7: 1, 14: 1};
    cases.forEach((everyDays, required) {
      test('everyDays $everyDays → $required', () {
        expect(requiredCareDays(everyDays), required);
      });
    });
    test('fit = min(1, careDays / required)', () {
      expect(careFit(2, 4), 1);
      expect(careFit(1, 4), closeTo(4 / 7, 1e-9));
      expect(careFit(7, 0), 0);
    });
  });

  group('goals', () {
    test('S empty → 1', () {
      expect(goalsFit([Goal.hobby, Goal.other], [PlantPurpose.design]), 1);
    });
    test('S overlaps purposes → 1', () {
      expect(
        goalsFit([Goal.design], [PlantPurpose.food, PlantPurpose.design]),
        1,
      );
    });
    test('otherwise 0.3', () {
      expect(goalsFit([Goal.food, Goal.hobby], [PlantPurpose.design]), 0.3);
    });
  });
}
