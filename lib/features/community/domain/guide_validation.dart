/// Pure draft model and publish rules for the guide editor (plan/07
/// § Editor). No Flutter, no Supabase: the editor and the repository both
/// validate through here.
library;

import '../../onboarding/domain/space.dart';
import 'guide.dart';
import 'guide_labels.dart';

/// Title length, from the `guides.title` check constraint in 0001_init.sql.
const int guideTitleMinLength = 5;
const int guideTitleMaxLength = 80;

/// Summary length on publish. The column allows `''`, which is what a
/// draft stores; publish requires at least one character.
const int guideSummaryMinLength = 1;
const int guideSummaryMaxLength = 280;

const int guideDifficultyMin = 1;
const int guideDifficultyMax = 3;

const int guideMaterialsMax = 30;
const int guideStepsMax = 20;
const int guideStepBodyMaxLength = 1000;
const int guidePlantIdsMax = 10;
const int guideTagsMax = 5;

/// Why one field is not valid. The domain stays copy-free: the editor maps
/// each code to the message on its CM-03 frame.
enum GuideFieldError {
  titleTooShort,
  titleTooLong,
  titleMissing,
  summaryEmpty,
  summaryTooLong,
  difficultyMissing,
  difficultyOutOfRange,
  spaceTypesEmpty,
  spaceTypeUnknown,
  materialsEmpty,
  materialsTooMany,
  materialNameEmpty,
  stepsEmpty,
  stepsTooMany,
  stepTitleEmpty,
  stepBodyTooLong,
  plantIdsTooMany,
  tagsTooMany,
  tagUnknown,
  costNegative,
  setupMinutesNegative,
}

/// Field names the editor keys its inline errors by. They match the
/// `guides` columns so a reviewer can line them up with plan/07's schema.
abstract final class GuideField {
  static const title = 'title';
  static const summary = 'summary';
  static const difficulty = 'difficulty';
  static const spaceTypes = 'spaceTypes';
  static const materials = 'materials';
  static const steps = 'steps';
  static const plantIds = 'plantIds';
  static const tags = 'tags';
  static const estCostUsd = 'estCostUsd';
  static const setupMinutes = 'setupMinutes';
}

/// A guide being written. [id] is null until the first save, because
/// `guides.id` is server-generated (plan/07 § Editor).
class GuideDraft {
  const GuideDraft({
    this.id,
    this.title = '',
    this.summary = '',
    this.coverPath,
    this.difficulty,
    this.spaceTypes = const [],
    this.estCostUsd,
    this.setupMinutes,
    this.materials = const [],
    this.steps = const [],
    this.plantIds = const [],
    this.tags = const [],
  });

  /// Null before the first save.
  final String? id;
  final String title;
  final String summary;
  final String? coverPath;

  /// Null until the author picks one; 1 to 3 once set.
  final int? difficulty;

  /// `SpaceType` names.
  final List<String> spaceTypes;
  final int? estCostUsd;
  final int? setupMinutes;
  final List<GuideMaterial> materials;
  final List<GuideStep> steps;
  final List<String> plantIds;
  final List<String> tags;

  /// True once the draft exists as a row, which decides whether a save is
  /// an insert or an update.
  bool get isSaved => id != null;

  /// A copy with the given fields replaced. A null argument keeps the old
  /// value, so the optional [coverPath], [estCostUsd] and [setupMinutes]
  /// are cleared with their `clear` flags, which win over a value.
  GuideDraft copyWith({
    String? id,
    String? title,
    String? summary,
    String? coverPath,
    int? difficulty,
    List<String>? spaceTypes,
    int? estCostUsd,
    int? setupMinutes,
    List<GuideMaterial>? materials,
    List<GuideStep>? steps,
    List<String>? plantIds,
    List<String>? tags,
    bool clearCoverPath = false,
    bool clearEstCostUsd = false,
    bool clearSetupMinutes = false,
  }) => GuideDraft(
    id: id ?? this.id,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    coverPath: clearCoverPath ? null : coverPath ?? this.coverPath,
    difficulty: difficulty ?? this.difficulty,
    spaceTypes: spaceTypes ?? this.spaceTypes,
    estCostUsd: clearEstCostUsd ? null : estCostUsd ?? this.estCostUsd,
    setupMinutes: clearSetupMinutes ? null : setupMinutes ?? this.setupMinutes,
    materials: materials ?? this.materials,
    steps: steps ?? this.steps,
    plantIds: plantIds ?? this.plantIds,
    tags: tags ?? this.tags,
  );
}

/// Errors blocking "Save draft" (plan/07 § Editor): a 5–80 title is enough.
/// The `guides.title` check constraint applies to updates as well as
/// inserts, so a saved draft needs it too. The first save also needs a
/// difficulty, which the column requires on insert.
///
/// An empty result means the save may go ahead.
Map<String, GuideFieldError> validateSaveDraft(GuideDraft draft) {
  final errors = <String, GuideFieldError>{};
  if (draft.title.trim().isEmpty) {
    errors[GuideField.title] = GuideFieldError.titleMissing;
    return errors;
  }
  final title = _titleError(draft.title);
  if (title != null) errors[GuideField.title] = title;
  if (draft.isSaved) return errors;
  final difficulty = _difficultyError(draft.difficulty);
  if (difficulty != null) errors[GuideField.difficulty] = difficulty;
  return errors;
}

/// Errors blocking "Publish" (plan/07 § Editor): title 5–80, summary
/// 1–280, a difficulty, and at least one space type, material, and step.
/// The list caps and the tag list are checked too, so a draft can never
/// publish content the editor could not have produced.
///
/// An empty result means the publish may go ahead.
Map<String, GuideFieldError> validatePublish(GuideDraft draft) {
  final errors = <String, GuideFieldError>{};

  final title = _titleError(draft.title);
  if (title != null) errors[GuideField.title] = title;

  final summary = draft.summary.trim();
  if (summary.length < guideSummaryMinLength) {
    errors[GuideField.summary] = GuideFieldError.summaryEmpty;
  } else if (summary.length > guideSummaryMaxLength) {
    errors[GuideField.summary] = GuideFieldError.summaryTooLong;
  }

  final difficulty = _difficultyError(draft.difficulty);
  if (difficulty != null) errors[GuideField.difficulty] = difficulty;

  if (draft.spaceTypes.isEmpty) {
    errors[GuideField.spaceTypes] = GuideFieldError.spaceTypesEmpty;
  } else if (!draft.spaceTypes.every(_spaceTypeNames.contains)) {
    errors[GuideField.spaceTypes] = GuideFieldError.spaceTypeUnknown;
  }

  if (draft.materials.isEmpty) {
    errors[GuideField.materials] = GuideFieldError.materialsEmpty;
  } else if (draft.materials.length > guideMaterialsMax) {
    errors[GuideField.materials] = GuideFieldError.materialsTooMany;
  } else if (draft.materials.any((m) => m.name.trim().isEmpty)) {
    errors[GuideField.materials] = GuideFieldError.materialNameEmpty;
  }

  if (draft.steps.isEmpty) {
    errors[GuideField.steps] = GuideFieldError.stepsEmpty;
  } else if (draft.steps.length > guideStepsMax) {
    errors[GuideField.steps] = GuideFieldError.stepsTooMany;
  } else if (draft.steps.any((s) => s.title.trim().isEmpty)) {
    errors[GuideField.steps] = GuideFieldError.stepTitleEmpty;
  } else if (draft.steps.any((s) => s.body.length > guideStepBodyMaxLength)) {
    errors[GuideField.steps] = GuideFieldError.stepBodyTooLong;
  }

  if (draft.plantIds.length > guidePlantIdsMax) {
    errors[GuideField.plantIds] = GuideFieldError.plantIdsTooMany;
  }

  if (draft.tags.length > guideTagsMax) {
    errors[GuideField.tags] = GuideFieldError.tagsTooMany;
  } else if (!draft.tags.every(guideTags.contains)) {
    errors[GuideField.tags] = GuideFieldError.tagUnknown;
  }

  final cost = draft.estCostUsd;
  if (cost != null && cost < 0) {
    errors[GuideField.estCostUsd] = GuideFieldError.costNegative;
  }
  final minutes = draft.setupMinutes;
  if (minutes != null && minutes < 0) {
    errors[GuideField.setupMinutes] = GuideFieldError.setupMinutesNegative;
  }

  return errors;
}

GuideFieldError? _titleError(String title) {
  final trimmed = title.trim();
  if (trimmed.length < guideTitleMinLength) {
    return GuideFieldError.titleTooShort;
  }
  if (trimmed.length > guideTitleMaxLength) return GuideFieldError.titleTooLong;
  return null;
}

GuideFieldError? _difficultyError(int? difficulty) {
  if (difficulty == null) return GuideFieldError.difficultyMissing;
  if (difficulty < guideDifficultyMin || difficulty > guideDifficultyMax) {
    return GuideFieldError.difficultyOutOfRange;
  }
  return null;
}

final Set<String> _spaceTypeNames = {
  for (final type in SpaceType.values) type.name,
};
