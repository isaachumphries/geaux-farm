import 'package:flutter/material.dart';

import '../theme.dart';

/// A row of labeled step dots: finished steps leaf-500, the current step
/// leaf-700 and larger, later steps stone-200.
class GeauxStepProgress extends StatelessWidget {
  const GeauxStepProgress({
    super.key,
    required this.labels,
    required this.current,
  }) : assert(current >= 0 && current < labels.length);

  final List<String> labels;

  /// Index into [labels] of the active step.
  final int current;

  static const double _dot = 10;
  static const double _activeDot = 14;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${current + 1} of ${labels.length}: ${labels[current]}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _StepDot(
                label: labels[i],
                done: i < current,
                active: i == current,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.leaf700
        : done
        ? AppColors.leaf500
        : AppColors.stone200;
    final size = active ? GeauxStepProgress._activeDot : GeauxStepProgress._dot;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: GeauxStepProgress._activeDot,
          child: Center(
            child: Container(
              key: ValueKey('step-dot-$label'),
              width: size,
              height: size,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption.copyWith(
            color: active ? AppColors.leaf700 : AppColors.soil600,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
