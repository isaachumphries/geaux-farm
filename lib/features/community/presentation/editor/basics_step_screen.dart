import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../onboarding/domain/space.dart';
import '../../application/guide_editor_provider.dart';
import '../../domain/guide_labels.dart';
import '../../domain/guide_validation.dart';
import 'editor_widgets.dart';

/// Lines the summary field is tall when empty, and the most it grows to.
const _summaryMinLines = 3;
const _summaryMaxLines = 6;

/// CM-03a: title, summary, cover, difficulty, space types, cost, setup
/// time and tags. Every change goes straight into the editor's draft, so
/// leaving the step and coming back shows what was typed.
///
/// A body widget: the host owns the app bar and the Back/Next bar.
class BasicsStepScreen extends ConsumerStatefulWidget {
  const BasicsStepScreen({super.key, required this.guideId});

  final String guideId;

  @override
  ConsumerState<BasicsStepScreen> createState() => _BasicsStepScreenState();
}

class _BasicsStepScreenState extends ConsumerState<BasicsStepScreen> {
  late final TextEditingController _title;
  late final TextEditingController _summary;
  late final TextEditingController _cost;
  late final TextEditingController _setup;

  GuideEditorNotifier get _editor =>
      ref.read(guideEditorProvider(widget.guideId).notifier);

  @override
  void initState() {
    super.initState();
    // The draft outlives this screen: each visit starts from it.
    final draft = ref.read(guideEditorProvider(widget.guideId)).draft;
    _title = TextEditingController(text: draft.title);
    _summary = TextEditingController(text: draft.summary);
    _cost = TextEditingController(text: draft.estCostUsd?.toString());
    _setup = TextEditingController(text: draft.setupMinutes?.toString());
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _cost.dispose();
    _setup.dispose();
    super.dispose();
  }

  void _setTitle(String value) =>
      _editor.edit((draft) => draft.copyWith(title: value));

  void _setSummary(String value) =>
      _editor.edit((draft) => draft.copyWith(summary: value));

  void _setCost(String value) {
    final usd = int.tryParse(value);
    _editor.edit(
      (draft) => _withNumbers(draft, cost: usd, minutes: draft.setupMinutes),
    );
  }

  void _setSetup(String value) {
    final minutes = int.tryParse(value);
    _editor.edit(
      (draft) => _withNumbers(draft, cost: draft.estCostUsd, minutes: minutes),
    );
  }

  void _toggleSpace(SpaceType type) => _editor.edit(
    (draft) => draft.copyWith(
      spaceTypes: _toggled(
        [for (final space in SpaceType.values) space.name],
        draft.spaceTypes,
        type.name,
      ),
    ),
  );

  void _toggleTag(String tag) => _editor.edit(
    (draft) => draft.copyWith(tags: _toggled(guideTags, draft.tags, tag)),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guideEditorProvider(widget.guideId));
    final draft = state.draft;
    final errors = state.errors;
    final tagsFull = draft.tags.length >= guideTagsMax;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Basics', style: AppText.h1.copyWith(color: AppColors.soil900)),
          const SizedBox(height: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.xl,
            children: [
              EditorField(
                label: 'Title',
                labelsChild: true,
                error: errors[GuideField.title],
                child: GeauxTextField(
                  key: const ValueKey('guide-title'),
                  controller: _title,
                  maxLength: guideTitleMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  hasError: errors.containsKey(GuideField.title),
                  onChanged: _setTitle,
                ),
              ),
              EditorField(
                label: 'Summary',
                labelsChild: true,
                error: errors[GuideField.summary],
                child: GeauxTextField(
                  key: const ValueKey('guide-summary'),
                  controller: _summary,
                  maxLength: guideSummaryMaxLength,
                  minLines: _summaryMinLines,
                  maxLines: _summaryMaxLines,
                  textCapitalization: TextCapitalization.sentences,
                  hasError: errors.containsKey(GuideField.summary),
                  onChanged: _setSummary,
                ),
              ),
              const EditorField(
                label: 'Cover',
                child: EditorImageSlot(caption: 'Add cover photo'),
              ),
              EditorField(
                label: 'Difficulty',
                error: errors[GuideField.difficulty],
                child: GeauxSegmentedChoice<int?>(
                  options: [
                    for (
                      var level = guideDifficultyMin;
                      level <= guideDifficultyMax;
                      level++
                    )
                      (level, guideDifficultyLabel(level)),
                  ],
                  selected: draft.difficulty,
                  onSelected: (level) =>
                      _editor.edit((d) => d.copyWith(difficulty: level)),
                ),
              ),
              EditorField(
                label: 'Space',
                error: errors[GuideField.spaceTypes],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    for (final type in SpaceType.values)
                      GeauxSelectCard(
                        title: guideSpaceTypeLabel(type),
                        multiSelect: true,
                        selected: draft.spaceTypes.contains(type.name),
                        onTap: () => _toggleSpace(type),
                      ),
                  ],
                ),
              ),
              EditorField(
                label: 'Est. cost (USD)',
                labelsChild: true,
                error: errors[GuideField.estCostUsd],
                child: GeauxTextField(
                  key: const ValueKey('guide-cost'),
                  controller: _cost,
                  hintText: 'Optional',
                  maxLength: editorNumberMaxDigits,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  hasError: errors.containsKey(GuideField.estCostUsd),
                  onChanged: _setCost,
                ),
              ),
              EditorField(
                label: 'Setup time (minutes)',
                labelsChild: true,
                error: errors[GuideField.setupMinutes],
                child: GeauxTextField(
                  key: const ValueKey('guide-setup'),
                  controller: _setup,
                  hintText: 'Optional',
                  maxLength: editorNumberMaxDigits,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  hasError: errors.containsKey(GuideField.setupMinutes),
                  onChanged: _setSetup,
                ),
              ),
              EditorField(
                label: 'Tags',
                hint:
                    'Optional. Pick up to $guideTagsMax. '
                    '${draft.tags.length} of $guideTagsMax picked.',
                error: errors[GuideField.tags],
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final tag in guideTags)
                      _TagChip(
                        label: guideTagLabel(tag),
                        selected: draft.tags.contains(tag),
                        onTap: draft.tags.contains(tag) || !tagsFull
                            ? () => _toggleTag(tag)
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// [draft] with its two optional numbers replaced. [GuideDraft.copyWith]
/// keeps the old value for a null argument, so it cannot clear a number
/// the author deleted; this rebuilds the draft instead.
GuideDraft _withNumbers(GuideDraft draft, {int? cost, int? minutes}) =>
    GuideDraft(
      id: draft.id,
      title: draft.title,
      summary: draft.summary,
      coverPath: draft.coverPath,
      difficulty: draft.difficulty,
      spaceTypes: draft.spaceTypes,
      estCostUsd: cost,
      setupMinutes: minutes,
      materials: draft.materials,
      steps: draft.steps,
      plantIds: draft.plantIds,
      tags: draft.tags,
    );

/// [current] with [value] added or removed, in the order of [all]. A value
/// outside [all] drops out, which is how an author clears one a saved
/// guide holds that the pickers no longer offer.
List<String> _toggled(List<String> all, List<String> current, String value) => [
  for (final item in all)
    if (item == value ? !current.contains(item) : current.contains(item)) item,
];

/// One tag pill: leaf-700 when picked, like CM-01's filter chips. Without an
/// [onTap] it is dimmed and inert, because five tags are picked already.
/// The pill is 44 tall; the tap area around it is the 48 plan/01 asks for.
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Horizontal padding inside a CM-01 chip.
  static const double _paddingH = 14;
  static const double _disabledOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: Opacity(
                opacity: enabled ? 1 : _disabledOpacity,
                child: LedgeCapsule(
                  color: selected ? AppColors.leaf700 : AppColors.white,
                  borderColor: selected
                      ? AppColors.leaf700
                      : AppColors.stone200,
                  ledgeColor: selected
                      ? AppColors.leafLedge
                      : AppColors.stone200,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _paddingH,
                    vertical: AppSpacing.sm + 1,
                  ),
                  child: Text(
                    label,
                    style: AppText.bodySm.copyWith(
                      color: selected ? AppColors.white : AppColors.soil900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
