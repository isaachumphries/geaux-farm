import '../../domain/guide_validation.dart';

/// The five CM-03 steps, in order (plan/07 § Editor).
enum EditorStep {
  basics('Basics'),
  materials('Materials'),
  steps('Steps'),
  plants('Plants'),
  preview('Preview');

  const EditorStep(this.label);

  /// The step's name under its StepProgress dot.
  final String label;

  /// The step that edits [field], a [GuideField] key.
  static EditorStep forField(String field) => switch (field) {
    GuideField.materials => EditorStep.materials,
    GuideField.steps => EditorStep.steps,
    GuideField.plantIds => EditorStep.plants,
    _ => EditorStep.basics,
  };
}

/// The inline message under a field the last Save draft or Publish
/// blocked. plan/07 gives no error copy, so these name the rule from its
/// § Editor limits.
String guideFieldErrorText(GuideFieldError error) => switch (error) {
  GuideFieldError.titleMissing => 'Add a title',
  GuideFieldError.titleTooShort =>
    'Use at least $guideTitleMinLength characters',
  GuideFieldError.titleTooLong => 'Use at most $guideTitleMaxLength characters',
  GuideFieldError.summaryEmpty => 'Add a summary',
  GuideFieldError.summaryTooLong =>
    'Use at most $guideSummaryMaxLength characters',
  GuideFieldError.difficultyMissing ||
  GuideFieldError.difficultyOutOfRange => 'Pick a difficulty',
  GuideFieldError.spaceTypesEmpty => 'Pick at least one space',
  GuideFieldError.spaceTypeUnknown => 'Pick spaces from the list',
  GuideFieldError.materialsEmpty => 'Add at least one material',
  GuideFieldError.materialsTooMany =>
    'Use at most $guideMaterialsMax materials',
  GuideFieldError.materialNameEmpty => 'Every material needs a name',
  GuideFieldError.stepsEmpty => 'Add at least one step',
  GuideFieldError.stepsTooMany => 'Use at most $guideStepsMax steps',
  GuideFieldError.stepTitleEmpty => 'Every step needs a title',
  GuideFieldError.stepBodyTooLong =>
    'Keep each step to $guideStepBodyMaxLength characters',
  GuideFieldError.plantIdsTooMany => 'Pick at most $guidePlantIdsMax plants',
  GuideFieldError.tagsTooMany => 'Pick at most $guideTagsMax tags',
  GuideFieldError.tagUnknown => 'Pick tags from the list',
  GuideFieldError.costNegative => 'Cost can\'t be negative',
  GuideFieldError.setupMinutesNegative => 'Setup time can\'t be negative',
};
