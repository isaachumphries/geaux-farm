import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/care/domain/care_event.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/garden/domain/growth.dart';
import 'package:geaux_farm/features/garden/domain/planting.dart';
import 'package:geaux_farm/features/garden/domain/planting_copy.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';

import '../recommendations/fixtures/baton_rouge.dart';

/// Wednesday.
final _today = DateTime(2026, 10, 7);

Plant _kale([Map<String, dynamic> changes = const {}]) =>
    Plant.fromJson({...rawKale(), ...changes});

Planting _planting({String startMethod = 'transplant', DateTime? plantedOn}) =>
    Planting(
      id: 'p1',
      plantId: 'kale',
      spaceId: 's1',
      nickname: 'Mine',
      setup: GrowSetup.outdoor,
      inContainer: true,
      startMethod: startMethod,
      plantedOn: plantedOn,
      status: PlantingStatus.active,
      createdAt: DateTime(2026, 9, 1),
    );

CareEvent _event(CareEventType type, {String? note}) =>
    CareEvent(id: 'e', plantingId: 'p1', type: type, at: _today, note: note);

void main() {
  group('labels', () {
    test('where a planting grows reads "Space · Setup" (GD-01)', () {
      expect(
        whereLabel(SpaceType.balcony, GrowSetup.outdoor),
        'Balcony · Outdoors',
      );
      expect(
        whereLabel(SpaceType.windowsill, GrowSetup.indoor),
        'Windowsill · Indoors',
      );
      expect(
        whereLabel(SpaceType.smallYard, GrowSetup.greenhouse),
        'Yard bed · Greenhouse',
      );
      expect(
        whereLabel(SpaceType.largeYard, GrowSetup.outdoor),
        'Yard · Outdoors',
      );
      expect(
        whereLabel(SpaceType.communityPlot, GrowSetup.outdoor),
        'Community plot · Outdoors',
      );
    });

    test('an unknown space leaves just the setup', () {
      expect(whereLabel(null, GrowSetup.indoor), 'Indoors');
    });

    test('plant category nouns', () {
      expect(
        {for (final c in PlantCategory.values) c: categoryNoun(c)},
        {
          PlantCategory.vegetable: 'veggie',
          PlantCategory.herb: 'herb',
          PlantCategory.fruit: 'fruit',
          PlantCategory.flower: 'flower',
          PlantCategory.shrub: 'shrub',
          PlantCategory.houseplant: 'houseplant',
        },
      );
    });

    test('catalog task intervals', () {
      expect(everyLabel(1), 'Every day');
      expect(everyLabel(7), 'Every week');
      expect(everyLabel(14), 'Every 2 weeks');
      expect(everyLabel(30), 'Every month');
      expect(everyLabel(3), 'Every 3 days');
    });
  });

  group('stageLine', () {
    test('day 0 reads Planted today', () {
      expect(stageLine(GrowthStage.growing, _today, _today), 'Planted today');
    });

    test('later days read stage and day count', () {
      expect(
        stageLine(GrowthStage.growing, DateTime(2026, 9, 19), _today),
        'Growing · Day 18',
      );
      expect(
        stageLine(GrowthStage.readyToHarvest, DateTime(2026, 8, 1), _today),
        'Ready to harvest · Day 67',
      );
    });

    test('a planted date after today reads Planted today', () {
      expect(
        stageLine(GrowthStage.growing, DateTime(2026, 10, 9), _today),
        'Planted today',
      );
    });
  });

  group('maturityLine', () {
    final planted = _planting(plantedOn: DateTime(2026, 10, 1, 17));

    test('harvest plants show the window from the start method', () {
      // Kale transplant: 50-65 days from Oct 1.
      expect(maturityLine(_kale(), planted), 'Harvest window: Nov 20 – Dec 5');
    });

    test('the window follows the start method', () {
      // Kale seed: 55-75 days from Oct 1.
      final seed = _planting(
        startMethod: 'seed',
        plantedOn: DateTime(2026, 10, 1),
      );
      expect(maturityLine(_kale(), seed), 'Harvest window: Nov 25 – Dec 15');
    });

    test('bloom plants show when they bloom', () {
      final lavender = loadReferencePlants()['english-lavender']!;
      expect(maturityLine(lavender, planted), 'Blooms Nov 30 – Dec 30');
    });

    test('establish plants show when they settle in', () {
      expect(
        maturityLine(_kale({'maturityKind': 'establish'}), planted),
        'Settled in by Dec 5',
      );
    });

    test('foliage plants grow year-round, planted date or not', () {
      final foliage = _kale({'maturityKind': 'foliage'});
      expect(maturityLine(foliage, planted), 'Grows year-round');
      expect(maturityLine(foliage, _planting()), 'Grows year-round');
    });

    test('is null without a planted date or without start data', () {
      expect(maturityLine(_kale(), _planting()), isNull);
      expect(
        maturityLine(_kale({'starts': <Map<String, dynamic>>[]}), planted),
        isNull,
      );
    });
  });

  group('stageNote', () {
    test('every stage and category has a note', () {
      for (final stage in GrowthStage.values) {
        for (final c in PlantCategory.values) {
          final plant = _kale({'category': c.json});
          expect(stageNote(plant, stage), isNotEmpty, reason: '$stage $c');
        }
      }
    });

    test('notes that name the plant use its common name', () {
      final herb = _kale({'category': 'herb', 'commonName': 'Sweet Basil'});
      expect(stageNote(herb, GrowthStage.growing), contains('Sweet Basil'));
      expect(
        stageNote(_kale({'commonName': 'Kale'}), GrowthStage.readyToHarvest),
        startsWith('Kale is ready'),
      );
      expect(
        stageNote(_kale({'commonName': 'Azalea'}), GrowthStage.established),
        startsWith('Azalea has settled in'),
      );
      expect(
        stageNote(
          _kale({'category': 'flower', 'commonName': 'Zinnia'}),
          GrowthStage.sprouting,
        ),
        contains('Zinnia'),
      );
    });

    test('the note changes with the category within a stage', () {
      String note(String category, GrowthStage s) =>
          stageNote(_kale({'category': category}), s);
      expect(
        note('herb', GrowthStage.readyToHarvest),
        isNot(note('fruit', GrowthStage.readyToHarvest)),
      );
      expect(
        note('vegetable', GrowthStage.growing),
        isNot(note('houseplant', GrowthStage.growing)),
      );
      expect(
        note('vegetable', GrowthStage.sprouting),
        isNot(note('shrub', GrowthStage.sprouting)),
      );
    });
  });

  group('care log', () {
    test('event wording', () {
      expect(careEventLabel(_event(CareEventType.water)), 'Watered');
      expect(
        careEventLabel(_event(CareEventType.skipWater)),
        'Skipped watering',
      );
      expect(careEventLabel(_event(CareEventType.fertilize)), 'Fertilized');
      expect(careEventLabel(_event(CareEventType.prune)), 'Pruned');
      expect(careEventLabel(_event(CareEventType.harvest)), 'Harvested');
    });

    test('a note shows its text in quotes, or just Note without one', () {
      expect(careEventLabel(_event(CareEventType.note)), 'Note');
      expect(
        careEventLabel(_event(CareEventType.note, note: 'New leaves!')),
        '“New leaves!”',
      );
    });

    test('today shows the time, other days the weekday and date', () {
      expect(
        careLogDate(DateTime(2026, 10, 7, 6, 12), _today),
        'Today · 6:12 AM',
      );
      expect(
        careLogDate(DateTime(2026, 10, 7, 18, 5), _today),
        'Today · 6:05 PM',
      );
      expect(careLogDate(DateTime(2026, 10, 4, 8), _today), 'Sun, Oct 4');
    });
  });

  group('water and due wording', () {
    final yesterday = DateTime(2026, 10, 6);
    final tomorrow = DateTime(2026, 10, 8);
    final saturday = DateTime(2026, 10, 10);

    test('water chip (cards)', () {
      expect(waterChipLabel(yesterday, _today), 'Water now');
      expect(waterChipLabel(_today, _today), 'Water today');
      expect(waterChipLabel(tomorrow, _today), 'Water tomorrow');
      expect(waterChipLabel(saturday, _today), 'Water Sat');
    });

    test('next water chip (GD-02)', () {
      expect(nextWaterLabel(yesterday, _today), 'Water now');
      expect(nextWaterLabel(_today, _today), 'Next water today');
      expect(nextWaterLabel(tomorrow, _today), 'Next water tomorrow');
      expect(nextWaterLabel(saturday, _today), 'Next water Sat');
    });

    test('upcoming task due line', () {
      expect(
        dueLabel(DateTime(2026, 10, 5), _today),
        'Overdue since Mon, Oct 5',
      );
      expect(dueLabel(_today, _today), 'Due today');
      expect(dueLabel(tomorrow, _today), 'Due tomorrow');
      expect(dueLabel(saturday, _today), 'Due Sat, Oct 10');
    });

    test('a time of day on either date does not change the day count', () {
      expect(
        waterChipLabel(DateTime(2026, 10, 8, 1), DateTime(2026, 10, 7, 23)),
        'Water tomorrow',
      );
    });
  });
}
