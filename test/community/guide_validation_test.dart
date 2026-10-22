import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/domain/guide.dart';
import 'package:geaux_farm/features/community/domain/guide_validation.dart';

// plan/07 § Editor: "Save draft" needs a title (and, on the first insert,
// a 5-80 title plus a difficulty); "Publish" needs title 5-80, summary
// 1-280, a difficulty, and at least one space type, material and step.
// The lengths mirror the guides check constraints in 0001_init.sql.

GuideMaterial _material([String name = 'Potting soil']) =>
    GuideMaterial(name: name, qty: '1 bag');

GuideStep _step({String title = 'Fill the bucket', String body = 'Do it.'}) =>
    GuideStep(title: title, body: body);

/// A draft that passes every publish rule, so each test can break exactly
/// one thing.
GuideDraft valid({
  String? id = 'g1',
  String? title,
  String? summary,
  int? difficulty = 2,
  List<String>? spaceTypes,
  List<GuideMaterial>? materials,
  List<GuideStep>? steps,
  List<String> plantIds = const [],
  List<String> tags = const [],
  int? estCostUsd,
  int? setupMinutes,
}) => GuideDraft(
  id: id,
  title: title ?? 'Bucket tomatoes',
  summary: summary ?? 'A cheap way to grow tomatoes on a balcony.',
  difficulty: difficulty,
  spaceTypes: spaceTypes ?? const ['balcony'],
  materials: materials ?? [_material()],
  steps: steps ?? [_step()],
  plantIds: plantIds,
  tags: tags,
  estCostUsd: estCostUsd,
  setupMinutes: setupMinutes,
);

void main() {
  group('validateSaveDraft', () {
    test('once the row exists a 5-80 title is enough, with no difficulty', () {
      expect(validateSaveDraft(GuideDraft(id: 'g1', title: 'a' * 5)), isEmpty);
      expect(validateSaveDraft(GuideDraft(id: 'g1', title: 'a' * 80)), isEmpty);
    });

    // The guides.title check constraint applies to updates too: a later
    // save with a short title is refused by the database (23514).
    test('a saved draft still needs the title length: 4 fails, 81 fails', () {
      expect(validateSaveDraft(GuideDraft(id: 'g1', title: 'a' * 4)), {
        GuideField.title: GuideFieldError.titleTooShort,
      });
      expect(validateSaveDraft(GuideDraft(id: 'g1', title: 'a' * 81)), {
        GuideField.title: GuideFieldError.titleTooLong,
      });
    });

    test('no title is blocked, saved or not', () {
      expect(validateSaveDraft(const GuideDraft(id: 'g1')), {
        GuideField.title: GuideFieldError.titleMissing,
      });
      expect(validateSaveDraft(const GuideDraft()), {
        GuideField.title: GuideFieldError.titleMissing,
      });
    });

    test('a whitespace-only title counts as missing', () {
      expect(validateSaveDraft(const GuideDraft(id: 'g1', title: '   ')), {
        GuideField.title: GuideFieldError.titleMissing,
      });
    });

    group('the first save also needs a difficulty and a 5-80 title', () {
      test('5 characters passes, 4 fails', () {
        expect(
          validateSaveDraft(
            GuideDraft(id: null, title: 'a' * 5, difficulty: 1),
          ),
          isEmpty,
        );
        expect(
          validateSaveDraft(
            GuideDraft(id: null, title: 'a' * 4, difficulty: 1),
          ),
          {GuideField.title: GuideFieldError.titleTooShort},
        );
      });

      test('80 characters passes, 81 fails', () {
        expect(
          validateSaveDraft(
            GuideDraft(id: null, title: 'a' * 80, difficulty: 1),
          ),
          isEmpty,
        );
        expect(
          validateSaveDraft(
            GuideDraft(id: null, title: 'a' * 81, difficulty: 1),
          ),
          {GuideField.title: GuideFieldError.titleTooLong},
        );
      });

      test('a missing difficulty fails', () {
        expect(validateSaveDraft(const GuideDraft(title: 'Bucket tomatoes')), {
          GuideField.difficulty: GuideFieldError.difficultyMissing,
        });
      });

      test(
        'an empty summary is fine: the column stores it as an empty string',
        () {
          expect(
            validateSaveDraft(
              const GuideDraft(title: 'Bucket tomatoes', difficulty: 1),
            ),
            isEmpty,
          );
        },
      );
    });
  });

  group('validatePublish', () {
    test('a complete draft publishes', () {
      expect(validatePublish(valid()), isEmpty);
    });

    group('title 5-80', () {
      test('5 passes, 4 fails', () {
        expect(validatePublish(valid(title: 'a' * 5)), isEmpty);
        expect(validatePublish(valid(title: 'a' * 4)), {
          GuideField.title: GuideFieldError.titleTooShort,
        });
      });
      test('80 passes, 81 fails', () {
        expect(validatePublish(valid(title: 'a' * 80)), isEmpty);
        expect(validatePublish(valid(title: 'a' * 81)), {
          GuideField.title: GuideFieldError.titleTooLong,
        });
      });
    });

    group('summary 1-280', () {
      test('1 passes, 0 fails', () {
        expect(validatePublish(valid(summary: 'a')), isEmpty);
        expect(validatePublish(valid(summary: '')), {
          GuideField.summary: GuideFieldError.summaryEmpty,
        });
      });
      test('280 passes, 281 fails', () {
        expect(validatePublish(valid(summary: 'a' * 280)), isEmpty);
        expect(validatePublish(valid(summary: 'a' * 281)), {
          GuideField.summary: GuideFieldError.summaryTooLong,
        });
      });
    });

    group('difficulty 1-3', () {
      test('1 and 3 pass', () {
        expect(validatePublish(valid(difficulty: 1)), isEmpty);
        expect(validatePublish(valid(difficulty: 3)), isEmpty);
      });
      test('0 and 4 fail', () {
        expect(validatePublish(valid(difficulty: 0)), {
          GuideField.difficulty: GuideFieldError.difficultyOutOfRange,
        });
        expect(validatePublish(valid(difficulty: 4)), {
          GuideField.difficulty: GuideFieldError.difficultyOutOfRange,
        });
      });
      test('null is reported as missing, not out of range', () {
        expect(validatePublish(valid(difficulty: null)), {
          GuideField.difficulty: GuideFieldError.difficultyMissing,
        });
      });
    });

    group('space types', () {
      test('1 passes, 0 fails', () {
        expect(validatePublish(valid(spaceTypes: ['windowsill'])), isEmpty);
        expect(validatePublish(valid(spaceTypes: [])), {
          GuideField.spaceTypes: GuideFieldError.spaceTypesEmpty,
        });
      });
      test('every SpaceType name is accepted', () {
        expect(
          validatePublish(
            valid(
              spaceTypes: [
                'windowsill',
                'balcony',
                'smallYard',
                'largeYard',
                'communityPlot',
              ],
            ),
          ),
          isEmpty,
        );
      });
      test('an unknown name fails', () {
        expect(validatePublish(valid(spaceTypes: ['rooftop'])), {
          GuideField.spaceTypes: GuideFieldError.spaceTypeUnknown,
        });
      });
    });

    group('materials 1-30', () {
      test('1 and 30 pass', () {
        expect(validatePublish(valid(materials: [_material()])), isEmpty);
        expect(
          validatePublish(
            valid(materials: [for (var i = 0; i < 30; i++) _material()]),
          ),
          isEmpty,
        );
      });
      test('0 and 31 fail', () {
        expect(validatePublish(valid(materials: [])), {
          GuideField.materials: GuideFieldError.materialsEmpty,
        });
        expect(
          validatePublish(
            valid(materials: [for (var i = 0; i < 31; i++) _material()]),
          ),
          {GuideField.materials: GuideFieldError.materialsTooMany},
        );
      });
      test('a nameless material fails', () {
        expect(validatePublish(valid(materials: [_material('  ')])), {
          GuideField.materials: GuideFieldError.materialNameEmpty,
        });
      });
    });

    group('steps 1-20', () {
      test('1 and 20 pass', () {
        expect(validatePublish(valid(steps: [_step()])), isEmpty);
        expect(
          validatePublish(valid(steps: [for (var i = 0; i < 20; i++) _step()])),
          isEmpty,
        );
      });
      test('0 and 21 fail', () {
        expect(validatePublish(valid(steps: [])), {
          GuideField.steps: GuideFieldError.stepsEmpty,
        });
        expect(
          validatePublish(valid(steps: [for (var i = 0; i < 21; i++) _step()])),
          {GuideField.steps: GuideFieldError.stepsTooMany},
        );
      });
      test('a titleless step fails', () {
        expect(validatePublish(valid(steps: [_step(title: ' ')])), {
          GuideField.steps: GuideFieldError.stepTitleEmpty,
        });
      });
    });

    group('step body up to 1000', () {
      test('1000 passes, 1001 fails', () {
        expect(
          validatePublish(valid(steps: [_step(body: 'a' * 1000)])),
          isEmpty,
        );
        expect(validatePublish(valid(steps: [_step(body: 'a' * 1001)])), {
          GuideField.steps: GuideFieldError.stepBodyTooLong,
        });
      });
    });

    group('plant ids 0-10', () {
      test('0 and 10 pass', () {
        expect(validatePublish(valid(plantIds: [])), isEmpty);
        expect(
          validatePublish(
            valid(plantIds: [for (var i = 0; i < 10; i++) 'plant-$i']),
          ),
          isEmpty,
        );
      });
      test('11 fails', () {
        expect(
          validatePublish(
            valid(plantIds: [for (var i = 0; i < 11; i++) 'plant-$i']),
          ),
          {GuideField.plantIds: GuideFieldError.plantIdsTooMany},
        );
      });
    });

    group('tags 0-5 from the fixed list', () {
      test('0 and 5 pass', () {
        expect(validatePublish(valid(tags: [])), isEmpty);
        expect(
          validatePublish(
            valid(tags: ['vertical', 'containers', 'budget', 'kids', 'indoor']),
          ),
          isEmpty,
        );
      });
      test('6 fails', () {
        expect(
          validatePublish(
            valid(
              tags: [
                'vertical',
                'containers',
                'budget',
                'kids',
                'indoor',
                'louisiana',
              ],
            ),
          ),
          {GuideField.tags: GuideFieldError.tagsTooMany},
        );
      });
      test('budget is in the list, orchids is not', () {
        expect(validatePublish(valid(tags: ['budget'])), isEmpty);
        expect(validatePublish(valid(tags: ['orchids'])), {
          GuideField.tags: GuideFieldError.tagUnknown,
        });
      });
    });

    group('optional numbers are 0 or more', () {
      test('null and 0 pass, negative fails', () {
        expect(validatePublish(valid(estCostUsd: null)), isEmpty);
        expect(validatePublish(valid(estCostUsd: 0, setupMinutes: 0)), isEmpty);
        expect(validatePublish(valid(estCostUsd: -1)), {
          GuideField.estCostUsd: GuideFieldError.costNegative,
        });
        expect(validatePublish(valid(setupMinutes: -1)), {
          GuideField.setupMinutes: GuideFieldError.setupMinutesNegative,
        });
      });
    });

    test('every broken field is reported at once, keyed by field', () {
      final errors = validatePublish(
        const GuideDraft(
          id: 'g1',
          title: 'no',
          summary: '',
          spaceTypes: [],
          materials: [],
          steps: [],
        ),
      );
      expect(
        errors.keys,
        containsAll(<String>[
          GuideField.title,
          GuideField.summary,
          GuideField.difficulty,
          GuideField.spaceTypes,
          GuideField.materials,
          GuideField.steps,
        ]),
      );
    });
  });

  group('GuideDraft', () {
    test('isSaved follows the server-generated id', () {
      expect(const GuideDraft().isSaved, isFalse);
      expect(const GuideDraft(id: 'g1').isSaved, isTrue);
    });

    test('copyWith replaces only what it is given', () {
      final draft = valid(tags: ['budget']);
      final next = draft.copyWith(title: 'New title');
      expect(next.title, 'New title');
      expect(next.summary, draft.summary);
      expect(next.tags, ['budget']);
      expect(next.id, draft.id);
    });

    test('copyWith can clear the optional numbers and the cover', () {
      final draft = valid(
        estCostUsd: 40,
        setupMinutes: 90,
      ).copyWith(coverPath: 'g1/cover.jpg');
      final cleared = draft.copyWith(
        clearEstCostUsd: true,
        clearSetupMinutes: true,
        clearCoverPath: true,
      );
      expect(cleared.estCostUsd, isNull);
      expect(cleared.setupMinutes, isNull);
      expect(cleared.coverPath, isNull);
      expect(cleared.title, draft.title);
      expect(cleared.id, draft.id);
    });
  });
}
