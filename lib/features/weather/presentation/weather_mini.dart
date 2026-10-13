import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../data/weather_provider.dart';
import '../domain/weather.dart';

/// WeatherMini for one location, wired to [weatherProvider].
///
/// [onTap] opens WX-01 once that screen exists; null hides the chevron.
class WeatherMiniCard extends ConsumerWidget {
  const WeatherMiniCard({
    super.key,
    required this.lat,
    required this.lon,
    this.onTap,
  });

  final double lat;
  final double lon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = weatherProvider((lat, lon));
    return WeatherMini(
      state: ref.watch(provider),
      now: ref.watch(weatherClockProvider)(),
      onRetry: () => ref.read(provider.notifier).refresh(force: true),
      onTap: onTap,
    );
  }
}

/// Home's compact weather card (Figma HM-01 top card). Stateless: takes the
/// provider state so it can be tested and placed without a provider scope.
class WeatherMini extends StatelessWidget {
  const WeatherMini({
    super.key,
    required this.state,
    required this.now,
    required this.onRetry,
    this.onTap,
  });

  final AsyncValue<WeatherState> state;

  /// Used for the "Updated … ago" line after a failed refresh.
  final DateTime now;
  final VoidCallback onRetry;
  final VoidCallback? onTap;

  static const errorCopy = 'Weather unavailable — check your connection';

  @override
  Widget build(BuildContext context) {
    final data = state.value;
    final Widget child;
    if (data != null) {
      child = _Data(state: data, now: now, showChevron: onTap != null);
    } else if (state.hasError) {
      child = _Error(onRetry: onRetry);
    } else {
      child = const SizedBox(
        height: _tileSize,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.leaf500),
        ),
      );
    }
    return GeauxCard(onTap: data != null ? onTap : null, child: child);
  }
}

const double _tileSize = 56;
const double _rowIconSize = 18;

/// "Updated 5 min ago" / "Updated 2 h ago".
String updatedAgo(DateTime fetchedAt, DateTime now) {
  final age = now.difference(fetchedAt);
  final minutes = age.isNegative ? 0 : age.inMinutes;
  if (minutes < 60) return 'Updated $minutes min ago';
  return 'Updated ${minutes ~/ 60} h ago';
}

const _icons = <String, IconData>{
  'clear_day': Symbols.clear_day,
  'clear_night': Symbols.clear_night,
  'partly_cloudy_day': Symbols.partly_cloudy_day,
  'cloud': Symbols.cloud,
  'foggy': Symbols.foggy,
  'rainy_light': Symbols.rainy_light,
  'rainy': Symbols.rainy,
  'weather_snowy': Symbols.weather_snowy,
  'thunderstorm': Symbols.thunderstorm,
};

Color _iconColor(String iconName) => switch (iconName) {
  'clear_day' || 'partly_cloudy_day' => AppColors.geauxGold,
  'clear_night' => AppColors.tigerPurple,
  'rainy_light' || 'rainy' || 'thunderstorm' => AppColors.frost,
  _ => AppColors.soil600,
};

class _Data extends StatelessWidget {
  const _Data({
    required this.state,
    required this.now,
    required this.showChevron,
  });

  final WeatherState state;
  final DateTime now;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final current = state.snapshot.current;
    final condition = current.condition;
    final today = todayRow(state.snapshot.days, current.time);
    final rowText = AppText.body.copyWith(color: AppColors.soil600);

    return Row(
      children: [
        Container(
          width: _tileSize,
          height: _tileSize,
          decoration: BoxDecoration(
            color: AppColors.gold100,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Icon(
            _icons[condition.iconName],
            size: 32,
            fill: 1,
            color: _iconColor(condition.iconName),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${current.temperatureF.round()}°',
                    style: AppText.h1.copyWith(color: AppColors.soil900),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      condition.label,
                      style: rowText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (today != null)
                Wrap(
                  spacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Stat(
                      icon: Symbols.thermostat,
                      color: AppColors.heat,
                      text:
                          'H ${today.tmaxF.round()} / L ${today.tminF.round()}',
                      style: rowText,
                    ),
                    _Stat(
                      icon: Symbols.water_drop,
                      color: AppColors.frost,
                      text: today.precipProb == null
                          ? '—'
                          : '${today.precipProb}%',
                      style: rowText,
                    ),
                    _Stat(
                      icon: Symbols.sunny,
                      color: AppColors.geauxGold,
                      text: today.uvMax == null
                          ? 'UV —'
                          : 'UV ${today.uvMax!.round()}',
                      style: rowText,
                    ),
                  ],
                ),
              if (state.refreshError != null)
                Text(
                  updatedAgo(state.snapshot.fetchedAt, now),
                  style: AppText.caption.copyWith(color: AppColors.soil600),
                ),
            ],
          ),
        ),
        if (showChevron)
          const Icon(Symbols.chevron_right, color: AppColors.soil600),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.text,
    required this.style,
  });

  final IconData icon;
  final Color color;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: _rowIconSize, fill: 1, color: color),
      const SizedBox(width: 2),
      Text(text, style: style),
    ],
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          WeatherMini.errorCopy,
          style: AppText.bodySm.copyWith(color: AppColors.soil600),
        ),
      ),
      GeauxButton(
        label: 'Retry',
        onPressed: onRetry,
        variant: GeauxButtonVariant.text,
      ),
    ],
  );
}
