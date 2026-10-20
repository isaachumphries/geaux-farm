import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../domain/weather.dart';
import '../domain/weather_format.dart';
import 'weather_icons.dart';

// Measured on the WX-01 export (2x, halved).
const _heroLedge = Color(0xFF1E5F9B);
const _statTile = Color(0xFF1D5E91);
const double _discSize = 84;
const double _sunSize = 60;
const double _statGap = AppSpacing.sm;
const double _tempSize = 52;

/// WX-01 section 1: today's date, the current temperature and condition, and
/// the humidity, cloud cover and UV-now tiles.
class WeatherHero extends StatelessWidget {
  const WeatherHero({super.key, required this.snapshot, required this.metric});

  final WeatherSnapshot snapshot;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final current = snapshot.current;
    final condition = current.condition;
    final today = todayRow(snapshot.days, current.time);
    final onBlue = AppText.bodySm.copyWith(color: AppColors.white);
    final range = today == null
        ? ''
        : ' · H ${displayTemp(today.tmaxF, metric: metric)}° / '
              'L ${displayTemp(today.tminF, metric: metric)}°';

    return GeauxCard(
      color: AppColors.tileSkyLedge,
      borderColor: null,
      ledgeColor: _heroLedge,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayOverline(current.time),
                      style: AppText.overline.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      '${displayTemp(current.temperatureF, metric: metric)}°',
                      style: AppText.display.copyWith(
                        fontSize: _tempSize,
                        height: 1.1,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${condition.label}$range', style: onBlue),
                  ],
                ),
              ),
              _ConditionDisc(iconName: condition.iconName),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Symbols.humidity_percentage_rounded,
                    label: 'Humidity',
                    value: '${current.relativeHumidity}%',
                  ),
                ),
                const SizedBox(width: _statGap),
                Expanded(
                  child: _StatTile(
                    icon: Symbols.cloud_rounded,
                    label: 'Cloud cover',
                    value: '${current.cloudCover}%',
                  ),
                ),
                const SizedBox(width: _statGap),
                Expanded(
                  child: _StatTile(
                    icon: Symbols.sunny_rounded,
                    label: 'UV now',
                    value:
                        '${current.uvIndex.round()} · ${uvLabel(current.uvIndex)}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The condition glyph: a gold sun inside a translucent ring for clear days,
/// the condition's Material Symbol on the same ring otherwise.
class _ConditionDisc extends StatelessWidget {
  const _ConditionDisc({required this.iconName});

  final String iconName;

  @override
  Widget build(BuildContext context) {
    final sun = iconName == 'clear_day';
    return Container(
      width: _discSize,
      height: _discSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.4),
      ),
      child: sun
          ? Container(
              width: _sunSize,
              height: _sunSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.geauxGold,
              ),
            )
          : Icon(
              weatherIcons[iconName],
              size: 44,
              fill: 1,
              color: AppColors.white,
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 2,
        AppSpacing.sm,
        AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: _statTile,
        borderRadius: BorderRadius.circular(AppRadii.card - 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: AppIconSize.xs,
                  fill: 1,
                  color: AppColors.white,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  style: AppText.caption.copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppText.cardTitle.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
