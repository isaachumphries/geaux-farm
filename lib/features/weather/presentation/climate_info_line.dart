import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// One "Your climate" row: a tinted icon tile beside one or more lines of
/// text. The frost row passes two lines; the others pass one.
class ClimateInfoLine extends StatelessWidget {
  const ClimateInfoLine({
    super.key,
    required this.icon,
    required this.tile,
    required this.ledge,
    required this.lines,
  });

  final IconData icon;
  final Color tile;
  final Color ledge;
  final List<String> lines;

  static const double _tile = 40;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: _tile,
          height: _tile,
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(AppRadii.chip + 4),
          ),
          child: Icon(icon, color: ledge, fill: 1, size: AppIconSize.lg),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.xs),
                Text(
                  lines[i],
                  style: AppText.body.copyWith(
                    color: AppColors.soil900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
