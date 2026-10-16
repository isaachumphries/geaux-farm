import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../climate/domain/climate_profile.dart';
import '../../domain/climate_reveal_format.dart';

/// The OB-02b card: zone, summer, winter, rain, humidity and frost lines,
/// each on a tinted icon tile.
class ClimateRevealCard extends StatelessWidget {
  const ClimateRevealCard({
    super.key,
    required this.profile,
    required this.lat,
  });

  final ClimateProfile profile;
  final double lat;

  @override
  Widget build(BuildContext context) {
    final frost = frostLine(profile.lastSpringFrostDoy, lat);
    final lines = [
      (
        Symbols.eco_rounded,
        AppColors.leaf100,
        AppColors.leaf700,
        zoneLine(profile),
      ),
      (
        Symbols.sunny_rounded,
        AppColors.gold100,
        AppColors.goldLedge,
        summerLine(profile),
      ),
      (
        Symbols.ac_unit_rounded,
        AppColors.tileSky,
        AppColors.frost,
        winterLine(profile),
      ),
      (
        Symbols.water_drop_rounded,
        AppColors.tileSky,
        AppColors.tileSkyLedge,
        rainLine(profile),
      ),
      (
        Symbols.humidity_percentage_rounded,
        AppColors.tilePeach,
        AppColors.heat,
        humidityLabel(profile.annualRhPct),
      ),
      if (frost != null)
        (
          Symbols.severe_cold_rounded,
          AppColors.tileSoil,
          AppColors.tileSoilLedge,
          frost,
        ),
    ];
    return GeauxCard(
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            _Line(
              icon: lines[i].$1,
              tile: lines[i].$2,
              iconColor: lines[i].$3,
              text: lines[i].$4,
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.tile,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color tile;
  final Color iconColor;
  final String text;

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
          child: Icon(icon, color: iconColor, fill: 1, size: AppIconSize.lg),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppText.body.copyWith(
              color: AppColors.soil900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
