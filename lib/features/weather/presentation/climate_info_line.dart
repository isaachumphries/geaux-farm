import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// One "Your climate" row: a tinted icon tile beside a small [label] and one
/// or more value lines. [detail] follows the first line in a muted weight
/// ("Humid" then "· 75% average").
class ClimateInfoLine extends StatelessWidget {
  const ClimateInfoLine({
    super.key,
    required this.icon,
    required this.tile,
    required this.ledge,
    required this.label,
    required this.lines,
    this.detail,
    this.divided = false,
  });

  final IconData icon;
  final Color tile;
  final Color ledge;
  final String label;
  final List<String> lines;
  final String? detail;

  /// Draws the 2 px stone rule above the row (every row but the first).
  final bool divided;

  static const double _tile = 36;

  @override
  Widget build(BuildContext context) {
    final value = AppText.body.copyWith(
      color: AppColors.soil900,
      fontWeight: FontWeight.w700,
    );
    final row = Row(
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
              Text(
                label,
                style: AppText.label.copyWith(
                  color: AppColors.soil600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              for (var i = 0; i < lines.length; i++)
                if (i == 0 && detail != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(lines[i], style: value),
                      Flexible(
                        child: Text(
                          ' · $detail',
                          style: value.copyWith(
                            color: AppColors.soil600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    lines[i],
                    style: i == 0
                        ? value
                        : AppText.bodySm.copyWith(color: AppColors.soil600),
                  ),
            ],
          ),
        ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (divided)
          const Divider(
            height: AppBorders.width,
            thickness: AppBorders.width,
            color: AppColors.stone200,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: row,
        ),
      ],
    );
  }
}
