import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../domain/guide.dart';

/// A section heading over its [child] (CM-02: Materials, Steps, Plants in
/// this guide).
class GuideSection extends StatelessWidget {
  const GuideSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Text(title, style: AppText.h2.copyWith(color: AppColors.soil900)),
        child,
      ],
    );
  }
}

/// The materials in one card: each name followed by its quantity.
class GuideMaterials extends StatelessWidget {
  const GuideMaterials({super.key, required this.materials});

  final List<GuideMaterial> materials;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          for (final material in materials)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8, right: AppSpacing.md),
                  child: SizedBox.square(
                    dimension: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.leaf500,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: material.name,
                      children: [
                        if (material.qty.isNotEmpty)
                          TextSpan(
                            text: '  ${material.qty}',
                            style: TextStyle(color: AppColors.soil600),
                          ),
                      ],
                    ),
                    style: AppText.body.copyWith(color: AppColors.soil900),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The numbered steps, one card each.
class GuideSteps extends StatelessWidget {
  const GuideSteps({super.key, required this.steps});

  final List<GuideStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        for (final (i, step) in steps.indexed)
          GeauxCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.md,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.leaf700,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: AppText.label.copyWith(color: AppColors.white),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: AppText.body.copyWith(
                          color: AppColors.soil900,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (step.body.isNotEmpty)
                        Text(
                          step.body,
                          style: AppText.body.copyWith(
                            color: AppColors.soil900,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
