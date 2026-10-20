// plan/04 § Scoring: Light (20), Space (15), Goals (10) rules that the
// worked example doesn't separate.
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';
import 'package:geaux_farm/features/recommendations/domain/score_plant.dart';

import 'fixtures/baton_rouge.dart';
import 'fixtures/scored.dart';

Space spaceOf(SpaceType type, {int areaSqFt = 32, SunLevel? sun}) => Space(
  id: type.name,
  type: type,
  areaSqFt: areaSqFt,
  sun: sun ?? SunLevel.partial,
  rainExposed: true,
  inContainerDefault: true,
);

void main() {
  group('user sun level per setup', () {
    test('outdoor uses space.sun for every space type', () {
      for (final type in SpaceType.values) {
        expect(
          userSun(spaceOf(type, sun: SunLevel.shade), GrowSetup.outdoor),
          SunLevel.shade,
          reason: type.name,
        );
      }
    });
    test('indoor windowsill uses space.sun', () {
      expect(
        userSun(
          spaceOf(SpaceType.windowsill, sun: SunLevel.full),
          GrowSetup.indoor,
        ),
        SunLevel.full,
      );
      expect(
        userSun(
          spaceOf(SpaceType.windowsill, sun: SunLevel.shade),
          GrowSetup.indoor,
        ),
        SunLevel.shade,
      );
    });
    test('indoor elsewhere is partial regardless of space.sun', () {
      for (final type in SpaceType.values.skip(1)) {
        for (final sun in [SunLevel.shade, SunLevel.full]) {
          expect(
            userSun(spaceOf(type, sun: sun), GrowSetup.indoor),
            SunLevel.partial,
            reason: '${type.name} ${sun.name}',
          );
        }
      }
    });
    test('greenhouse is always full', () {
      for (final type in SpaceType.values) {
        expect(
          userSun(spaceOf(type, sun: SunLevel.shade), GrowSetup.greenhouse),
          SunLevel.full,
          reason: type.name,
        );
      }
    });
  });

  group('space fit', () {
    double space(
      Map<String, dynamic> plantSpace,
      SpaceType type,
      int area,
      GrowSetup setup,
    ) => scorePlant(
      kaleWith({'space': plantSpace}),
      UserContext(
        profile: workedExampleProfile,
        space: spaceOf(type, areaSqFt: area),
        climate: batonRougeClimate,
      ),
      setup,
      workedExampleDate,
    ).fits['space']!;
    Map<String, dynamic> needs({
      num sqFt = 4,
      bool containerOk = true,
      bool indoorOk = true,
    }) => {
      'sqFtPerPlant': sqFt,
      'containerOk': containerOk,
      'indoorOk': indoorOk,
    };

    test('ratio area / sqFtPerPlant below 1', () {
      expect(space(needs(), SpaceType.smallYard, 1, GrowSetup.outdoor), 0.25);
      expect(space(needs(), SpaceType.smallYard, 3, GrowSetup.outdoor), 0.75);
    });
    test('ratio caps at 1', () {
      expect(space(needs(), SpaceType.smallYard, 4, GrowSetup.outdoor), 1);
      expect(space(needs(), SpaceType.largeYard, 400, GrowSetup.outdoor), 1);
    });
    test('outdoor windowsill and balcony need containerOk', () {
      for (final type in [SpaceType.windowsill, SpaceType.balcony]) {
        expect(
          space(needs(containerOk: false), type, 32, GrowSetup.outdoor),
          0,
          reason: type.name,
        );
        expect(space(needs(), type, 2, GrowSetup.outdoor), 0.5);
      }
    });
    test('yards and plots ignore containerOk', () {
      for (final type in [
        SpaceType.smallYard,
        SpaceType.largeYard,
        SpaceType.communityPlot,
      ]) {
        expect(
          space(needs(containerOk: false), type, 2, GrowSetup.outdoor),
          0.5,
          reason: type.name,
        );
      }
    });
    test('indoor needs indoorOk, then uses the ratio', () {
      expect(
        space(
          needs(indoorOk: false),
          SpaceType.largeYard,
          32,
          GrowSetup.indoor,
        ),
        0,
      );
      // indoorOk wins over containerOk on a balcony.
      expect(
        space(
          needs(containerOk: false),
          SpaceType.balcony,
          2,
          GrowSetup.indoor,
        ),
        0.5,
      );
    });
    test('greenhouse on a balcony follows the container rule', () {
      expect(
        space(
          needs(containerOk: false, indoorOk: true),
          SpaceType.balcony,
          32,
          GrowSetup.greenhouse,
        ),
        0,
      );
    });
  });

  group('goals fit: S = goals ∩ {food, design}', () {
    test('design goal and a food-only plant → 0.3', () {
      expect(goalsFit([Goal.design], [PlantPurpose.food]), 0.3);
    });
    test('food goal and a design-only plant → 0.3', () {
      expect(goalsFit([Goal.food], [PlantPurpose.design]), 0.3);
    });
    test('both goals and either purpose → 1', () {
      expect(goalsFit([Goal.food, Goal.design], [PlantPurpose.design]), 1);
      expect(goalsFit([Goal.food, Goal.design], [PlantPurpose.food]), 1);
    });
    test('no goals at all → 1', () {
      expect(goalsFit(const [], [PlantPurpose.design]), 1);
    });
  });
}
