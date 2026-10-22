import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../domain/guide_validation.dart';
import '../widgets/guide_cover.dart' show guideCoverHeight;
import 'editor_copy.dart';

/// Digits a cost or setup time can have: 999,999 is far past any guide and
/// well inside the `int` columns they are stored in.
const int editorNumberMaxDigits = 6;

/// Keeps an [IconButton] at the 48 square plan/01 asks for. On its own it
/// is 40 wherever the theme does not pad touch targets: desktop and web.
final editorIconButtonStyle = IconButton.styleFrom(
  minimumSize: const Size.square(AppSpacing.minTouchTarget),
);

/// A label over one control and, under it, the message for the field the
/// last blocked Save draft or Publish named. A [compact] label is the small
/// one inside a list row; the default is a section title.
class EditorField extends StatelessWidget {
  const EditorField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.error,
    this.compact = false,
    this.labelsChild = false,
  });

  final String label;
  final Widget child;

  /// A line of guidance between the label and the control.
  final String? hint;
  final GuideFieldError? error;
  final bool compact;

  /// True when [child] is one text field: a screen reader then announces
  /// [label] as the field's name, not as a line of its own before it.
  final bool labelsChild;

  @override
  Widget build(BuildContext context) {
    final hint = this.hint;
    final error = this.error;
    final title = Text(
      label,
      style: compact
          ? AppText.label.copyWith(color: AppColors.soil600)
          : AppText.cardTitle.copyWith(color: AppColors.soil900),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        labelsChild ? ExcludeSemantics(child: title) : title,
        if (hint != null)
          Text(hint, style: AppText.bodySm.copyWith(color: AppColors.soil600)),
        labelsChild ? Semantics(label: label, child: child) : child,
        if (error != null) EditorErrorText(error),
      ],
    );
  }
}

/// The message for one blocked field, announced when it appears.
class EditorErrorText extends StatelessWidget {
  const EditorErrorText(this.error, {super.key});

  final GuideFieldError error;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        guideFieldErrorText(error),
        style: AppText.bodySm.copyWith(color: AppColors.error),
      ),
    );
  }
}

/// The slot for a guide's cover or a step's photo. Picking and uploading an
/// image is #55, so until then the slot is drawn greyed and does nothing,
/// and says so to a screen reader. A [compact] slot is one touch target
/// tall; the default is as tall as a guide card's cover.
class EditorImageSlot extends StatelessWidget {
  const EditorImageSlot({
    super.key,
    required this.caption,
    this.compact = false,
  });

  final String caption;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const icon = Icon(
      Symbols.add_photo_alternate_rounded,
      size: AppIconSize.xl,
      color: AppColors.soil600,
    );
    final label = Text(
      caption,
      style: AppText.bodySm.copyWith(
        color: AppColors.soil600,
        fontWeight: FontWeight.w700,
      ),
    );
    return Semantics(
      button: true,
      enabled: false,
      label: caption,
      hint: 'Photo upload is coming soon',
      excludeSemantics: true,
      child: GeauxCard(
        padding: EdgeInsets.zero,
        color: AppColors.stone200,
        borderColor: null,
        ledgeColor: AppColors.stone200,
        child: SizedBox(
          height: compact ? AppSpacing.minTouchTarget : guideCoverHeight,
          child: Center(
            child: compact
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpacing.sm,
                    children: [icon, label],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpacing.xs,
                    children: [icon, label],
                  ),
          ),
        ),
      ),
    );
  }
}
