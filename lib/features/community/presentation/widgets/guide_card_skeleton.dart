import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import 'guide_cover.dart';

/// Placeholder cards shown while the first page loads (CM-01 loading).
class GuideCardSkeletonList extends StatelessWidget {
  const GuideCardSkeletonList({super.key, required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // Nothing to scroll yet.
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      padding: const EdgeInsets.all(AppBorders.width),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.card - AppBorders.width),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: guideCoverHeight,
              width: double.infinity,
              child: ColoredBox(color: AppColors.stone200),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bar(width: 220, height: 18),
                  SizedBox(height: AppSpacing.md),
                  _Bar(width: 120, height: 14),
                  SizedBox(height: AppSpacing.md),
                  _Bar(width: 180, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.stone200,
        borderRadius: BorderRadius.circular(AppRadii.chip / 2),
      ),
    );
  }
}
