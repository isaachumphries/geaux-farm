import 'package:flutter/material.dart';

import '../theme.dart';
import 'card.dart';

/// A row of equal-width ledge chips; exactly one is selected.
class GeauxSegmentedChoice<T> extends StatelessWidget {
  const GeauxSegmentedChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              selected: options[i].$1 == selected,
              inMutuallyExclusiveGroup: true,
              child: GeauxCard(
                onTap: () => onSelected(options[i].$1),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.md,
                ),
                color: options[i].$1 == selected
                    ? AppColors.leaf100
                    : AppColors.white,
                borderColor: options[i].$1 == selected
                    ? AppColors.leaf500
                    : AppColors.stone200,
                ledgeColor: options[i].$1 == selected
                    ? AppColors.leaf500
                    : AppColors.stone200,
                child: Text(
                  options[i].$2,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySm.copyWith(
                    color: options[i].$1 == selected
                        ? AppColors.leaf700
                        : AppColors.soil900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
