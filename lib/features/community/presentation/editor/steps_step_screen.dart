import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../application/guide_editor_provider.dart';
import '../../domain/guide.dart';
import '../../domain/guide_validation.dart';
import 'editor_widgets.dart';

/// Lines a step's details are tall when empty, and the most they grow to.
const _bodyMinLines = 3;
const _bodyMaxLines = 8;

/// CM-03c: the steps of a guide, one numbered card each with a title,
/// details and a photo slot. Every change goes straight into the editor's
/// draft.
///
/// A body widget: the host owns the app bar and the Back/Next bar.
class StepsStepScreen extends ConsumerStatefulWidget {
  const StepsStepScreen({super.key, required this.guideId});

  final String guideId;

  @override
  ConsumerState<StepsStepScreen> createState() => _StepsStepScreenState();
}

/// One step's text controllers. The row, not its position, owns them, so
/// removing an earlier step leaves a later step's typing where it is.
class _StepRow {
  _StepRow(GuideStep step)
    : title = TextEditingController(text: step.title),
      body = TextEditingController(text: step.body),
      imagePath = step.imagePath;

  _StepRow.blank() : this(const GuideStep(title: '', body: ''));

  final key = UniqueKey();
  final TextEditingController title;
  final TextEditingController body;

  /// Not editable until #55 uploads images, but kept so editing the text
  /// of a step never drops the photo it already has.
  final String? imagePath;

  GuideStep toStep() => GuideStep(
    title: title.text.trim(),
    body: body.text.trim(),
    imagePath: imagePath,
  );

  void dispose() {
    title.dispose();
    body.dispose();
  }
}

class _StepsStepScreenState extends ConsumerState<StepsStepScreen> {
  late final List<_StepRow> _rows;

  GuideEditorNotifier get _editor =>
      ref.read(guideEditorProvider(widget.guideId).notifier);

  @override
  void initState() {
    super.initState();
    // The draft outlives this screen: each visit starts from it.
    final draft = ref.read(guideEditorProvider(widget.guideId)).draft;
    _rows = [for (final step in draft.steps) _StepRow(step)];
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  /// Writes the rows, as they read now, into the draft.
  void _sync() {
    final steps = [for (final row in _rows) row.toStep()];
    _editor.edit((draft) => draft.copyWith(steps: steps));
  }

  void _add() {
    setState(() => _rows.add(_StepRow.blank()));
    _sync();
  }

  void _remove(_StepRow row) {
    setState(() => _rows.remove(row));
    _sync();
    // The row's fields leave the tree on the next frame, so its
    // controllers must outlive this one.
    WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(
      guideEditorProvider(widget.guideId)
          .select((state) => state.errors[GuideField.steps]),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Steps', style: AppText.h1.copyWith(color: AppColors.soil900)),
          const SizedBox(height: AppSpacing.lg),
          for (final (i, row) in _rows.indexed) ...[
            _StepCard(
              key: row.key,
              row: row,
              number: i + 1,
              titleBlocked:
                  error == GuideFieldError.stepTitleEmpty &&
                  row.title.text.trim().isEmpty,
              onChanged: _sync,
              onRemove: () => _remove(row),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (error != null) ...[
            EditorErrorText(error),
            const SizedBox(height: AppSpacing.md),
          ],
          GeauxButton(
            label: 'Add step',
            variant: GeauxButtonVariant.secondary,
            icon: Symbols.add_rounded,
            onPressed: _rows.length >= guideStepsMax ? null : _add,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    super.key,
    required this.row,
    required this.number,
    required this.titleBlocked,
    required this.onChanged,
    required this.onRemove,
  });

  final _StepRow row;

  /// 1-based position, as the author counts.
  final int number;

  /// The last blocked publish named this step for having no title.
  final bool titleBlocked;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Step $number',
                  style: AppText.body.copyWith(
                    color: AppColors.soil900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove step $number',
                onPressed: onRemove,
                style: editorIconButtonStyle,
                icon: const Icon(Symbols.delete_rounded),
              ),
            ],
          ),
          EditorField(
            compact: true,
            label: 'Title',
            labelsChild: true,
            child: GeauxTextField(
              key: const ValueKey('step-title'),
              controller: row.title,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              hasError: titleBlocked,
              onChanged: (_) => onChanged(),
            ),
          ),
          EditorField(
            compact: true,
            label: 'Details',
            labelsChild: true,
            child: GeauxTextField(
              key: const ValueKey('step-body'),
              controller: row.body,
              maxLength: guideStepBodyMaxLength,
              minLines: _bodyMinLines,
              maxLines: _bodyMaxLines,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => onChanged(),
            ),
          ),
          const EditorImageSlot(caption: 'Add step photo', compact: true),
        ],
      ),
    );
  }
}
