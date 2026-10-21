import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../domain/weather.dart';
import '../domain/weather_format.dart';

/// WX-01 section 4: sunrise, sunset and daylight length for today.
class DayDetails extends StatelessWidget {
  const DayDetails({super.key, required this.today});

  final WeatherDay today;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DetailTile(
            icon: Symbols.wb_twilight_rounded,
            tile: AppColors.gold100,
            ink: AppColors.goldLedge,
            label: 'Sunrise',
            value: clockText(today.sunrise),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _DetailTile(
            icon: Symbols.bedtime_rounded,
            tile: AppColors.tileSoil,
            ink: const Color(0xFF7A4B2A),
            label: 'Sunset',
            value: clockText(today.sunset),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _DetailTile(
            icon: Symbols.schedule_rounded,
            tile: AppColors.leaf100,
            ink: AppColors.leaf700,
            label: 'Daylight',
            value: daylightText(today.daylightS),
          ),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.tile,
    required this.ink,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color tile;
  final Color ink;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tile,
              borderRadius: BorderRadius.circular(AppRadii.chip + 4),
            ),
            child: Icon(icon, size: AppIconSize.lg, fill: 1, color: ink),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppText.label.copyWith(
              color: AppColors.soil600,
              fontWeight: FontWeight.w500,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppText.h2.copyWith(color: AppColors.soil900),
            ),
          ),
        ],
      ),
    );
  }
}
