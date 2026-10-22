import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../application/guide_editor_provider.dart';
import '../../domain/guide.dart';
import '../../domain/guide_validation.dart';
import 'editor_widgets.dart';

/// CM-03b: the materials a guide needs, one card each with a name, an
/// amount, an optional cost and an optional link. Every change goes
/// straight into the editor's draft.
///
/// A body widget: the host owns the app bar and the Back/Next bar.
class MaterialsStepScreen extends ConsumerStatefulWidget {
  const MaterialsStepScreen({super.key, required this.guideId});

  final String guideId;

  @override
  ConsumerState<MaterialsStepScreen> createState() =>
      _MaterialsStepScreenState();
}

/// One material's text controllers. The row, not its position, owns them,
/// so removing an earlier row leaves a later row's typing where it is.
class _MaterialRow {
  _MaterialRow(GuideMaterial material)
    : name = TextEditingController(text: material.name),
      qty = TextEditingController(text: material.qty),
      cost = TextEditingController(text: material.estCostUsd?.toString()),
      url = TextEditingController(text: material.url);

  _MaterialRow.blank() : this(const GuideMaterial(name: '', qty: ''));

  final key = UniqueKey();
  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController cost;
  final TextEditingController url;

  /// The material as typed. An empty link is no link.
  GuideMaterial toMaterial() {
    final link = url.text.trim();
    return GuideMaterial(
      name: name.text.trim(),
      qty: qty.text.trim(),
      estCostUsd: int.tryParse(cost.text),
      url: link.isEmpty ? null : link,
    );
  }

  void dispose() {
    name.dispose();
    qty.dispose();
    cost.dispose();
    url.dispose();
  }
}

class _MaterialsStepScreenState extends ConsumerState<MaterialsStepScreen> {
  late final List<_MaterialRow> _rows;

  GuideEditorNotifier get _editor =>
      ref.read(guideEditorProvider(widget.guideId).notifier);

  @override
  void initState() {
    super.initState();
    // The draft outlives this screen: each visit starts from it.
    final draft = ref.read(guideEditorProvider(widget.guideId)).draft;
    _rows = [for (final material in draft.materials) _MaterialRow(material)];
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
    final materials = [for (final row in _rows) row.toMaterial()];
    _editor.edit((draft) => draft.copyWith(materials: materials));
  }

  void _add() {
    setState(() => _rows.add(_MaterialRow.blank()));
    _sync();
  }

  void _remove(_MaterialRow row) {
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
          .select((state) => state.errors[GuideField.materials]),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Materials',
            style: AppText.h1.copyWith(color: AppColors.soil900),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (i, row) in _rows.indexed) ...[
            _MaterialCard(
              key: row.key,
              row: row,
              number: i + 1,
              nameBlocked:
                  error == GuideFieldError.materialNameEmpty &&
                  row.name.text.trim().isEmpty,
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
            label: 'Add material',
            variant: GeauxButtonVariant.secondary,
            icon: Symbols.add_rounded,
            onPressed: _rows.length >= guideMaterialsMax ? null : _add,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    super.key,
    required this.row,
    required this.number,
    required this.nameBlocked,
    required this.onChanged,
    required this.onRemove,
  });

  final _MaterialRow row;

  /// 1-based position, as the author counts.
  final int number;

  /// The last blocked publish named this material for having no name.
  final bool nameBlocked;
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
                  'Material $number',
                  style: AppText.body.copyWith(
                    color: AppColors.soil900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove material $number',
                onPressed: onRemove,
                style: editorIconButtonStyle,
                icon: const Icon(Symbols.delete_rounded),
              ),
            ],
          ),
          EditorField(
            compact: true,
            label: 'Name',
            labelsChild: true,
            child: GeauxTextField(
              key: const ValueKey('material-name'),
              controller: row.name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              hasError: nameBlocked,
              onChanged: (_) => onChanged(),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: EditorField(
                  compact: true,
                  label: 'Quantity',
                  labelsChild: true,
                  child: GeauxTextField(
                    key: const ValueKey('material-qty'),
                    controller: row.qty,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ),
              Expanded(
                child: EditorField(
                  compact: true,
                  label: 'Est. cost (USD)',
                  labelsChild: true,
                  child: GeauxTextField(
                    key: const ValueKey('material-cost'),
                    controller: row.cost,
                    hintText: 'Optional',
                    maxLength: editorNumberMaxDigits,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ),
            ],
          ),
          EditorField(
            compact: true,
            label: 'Link',
            labelsChild: true,
            child: GeauxTextField(
              key: const ValueKey('material-url'),
              controller: row.url,
              hintText: 'Optional',
              keyboardType: TextInputType.url,
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
