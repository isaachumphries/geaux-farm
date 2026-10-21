import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import 'guide_hero.dart';

/// CM-02 while the guide loads: bars where the cover and stat row will be.
class GuideDetailSkeleton extends StatelessWidget {
  const GuideDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: guideHeroHeight,
            child: ColoredBox(color: AppColors.stone200),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: guideHeroHeight - AppRadii.sheet,
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.cream50,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadii.sheet),
                ),
              ),
              child: const SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bar(width: 280, height: 28),
                      SizedBox(height: AppSpacing.lg),
                      _Bar(width: 140, height: 20),
                      SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          _Bar(width: 104, height: 46, radius: AppRadii.pill),
                          SizedBox(width: AppSpacing.sm),
                          _Bar(width: 160, height: 46, radius: AppRadii.pill),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.width,
    required this.height,
    this.radius = AppRadii.chip,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.stone200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
