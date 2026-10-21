import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../domain/weather.dart';
import '../domain/weather_format.dart';
import 'weather_icons.dart';

/// WX-01 section 3: seven columns starting with today, each with weekday,
/// condition icon, high, low and rain chance. Today sits on a gold chip.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.days, required this.metric});

  /// Up to seven rows; the first is today.
  final List<WeatherDay> days;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: _DayColumn(day: days[i], today: i == 0, metric: metric),
            ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.today,
    required this.metric,
  });

  final WeatherDay day;
  final bool today;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final condition = WeatherCondition.of(day.weatherCode, isDay: true);
    final prob = day.precipProb;
    final likely = prob != null && prob >= likelyRainPct;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: today ? AppColors.gold100 : null,
        borderRadius: BorderRadius.circular(AppRadii.card - 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            today ? 'Today' : weekdayShort(DateTime.parse(day.date)),
            maxLines: 1,
            style: AppText.label.copyWith(
              color: AppColors.soil600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Icon(
            weatherIcons[condition.iconName],
            size: AppIconSize.xl,
            fill: 1,
            color: weatherIconColor(condition.iconName),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${displayTemp(day.tmaxF, metric: metric)}°',
            style: AppText.cardTitle.copyWith(color: AppColors.soil900),
          ),
          Text(
            '${displayTemp(day.tminF, metric: metric)}°',
            style: AppText.body.copyWith(color: AppColors.soil600),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Symbols.water_drop_rounded,
                  size: AppIconSize.xs - 2,
                  fill: 1,
                  color: AppColors.frost,
                ),
                Text(
                  prob == null ? '—' : '$prob%',
                  style: AppText.caption.copyWith(
                    color: likely ? AppColors.frost : AppColors.soil600,
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
