import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../climate/data/climate_provider.dart';
import '../../onboarding/data/profile_providers.dart';
import '../../onboarding/domain/user_profile.dart';
import '../data/weather_provider.dart';
import '../domain/weather.dart';
import '../domain/weather_format.dart';
import 'attribution_footer.dart';
import 'climate_section.dart';
import 'day_details.dart';
import 'week_strip.dart';
import 'weather_hero.dart';
import 'weather_mini.dart';

/// WX-01: current conditions, the 7-day strip, today's sun times, "Your
/// climate", and the Open-Meteo credit (plan/06 § Weather UI). Garden alerts
/// (section 2) arrive with #29 and are absent until then.
class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  static const offlineCopy = 'Showing saved weather';
  static const climateErrorCopy = 'Climate data unavailable';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: profile == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.leaf500),
              )
            : _Body(profile: profile),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = forecastLocation(profile.lat, profile.lon);
    final provider = weatherProvider(location);
    final weather = ref.watch(provider);
    final now = ref.watch(weatherClockProvider)();
    final metric = profile.units == 'metric';
    final month = weather.value?.snapshot.current.time.month ?? now.month;

    return RefreshIndicator(
      color: AppColors.leaf500,
      onRefresh: () => ref.read(provider.notifier).refresh(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          _Header(city: profile.city),
          const SizedBox(height: AppSpacing.md),
          ..._weatherSections(
            weather: weather,
            now: now,
            metric: metric,
            onRetry: () => ref.read(provider.notifier).refresh(force: true),
          ),
          const _SectionTitle('Your climate'),
          const SizedBox(height: AppSpacing.sm),
          _climate(ref, month: month, metric: metric),
          const SizedBox(height: AppSpacing.md),
          const AttributionFooter(),
        ],
      ),
    );
  }

  List<Widget> _weatherSections({
    required AsyncValue<WeatherState> weather,
    required DateTime now,
    required bool metric,
    required VoidCallback onRetry,
  }) {
    final data = weather.value;
    if (data == null) {
      return [
        if (weather.hasError)
          _Unavailable(
            message: WeatherMini.errorCopy,
            retryLabel: 'Retry',
            onRetry: onRetry,
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.leaf500),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
      ];
    }

    final snapshot = data.snapshot;
    final today = todayRow(snapshot.days, snapshot.current.time);
    final week = nextSevenDays(snapshot.days, snapshot.current.time);
    final offline =
        data.refreshError != null &&
        showsOfflineBanner(snapshot.fetchedAt, now);
    return [
      if (offline) ...[
        const GeauxAlertBanner(
          message: WeatherScreen.offlineCopy,
          icon: Symbols.cloud_off_rounded,
          accent: AppColors.soil600,
          tint: AppColors.gold100,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      WeatherHero(snapshot: snapshot, metric: metric),
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(
          updatedAgo(snapshot.fetchedAt, now),
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: AppColors.soil600),
        ),
      ),
      if (week.isNotEmpty) ...[
        const _SectionTitle('Next 7 days'),
        const SizedBox(height: AppSpacing.md),
        WeekStrip(days: week, metric: metric),
      ],
      if (today != null) ...[
        const SizedBox(height: AppSpacing.lg),
        DayDetails(today: today),
      ],
    ];
  }

  Widget _climate(WidgetRef ref, {required int month, required bool metric}) {
    final climate = ref.watch(climateProvider);
    final profileData = climate.value;
    if (profileData != null) {
      return ClimateSection(
        profile: profileData,
        city: profile.city,
        lat: profile.lat,
        metric: metric,
        currentMonth: month,
      );
    }
    if (climate.hasError) {
      return _Unavailable(
        message: WeatherScreen.climateErrorCopy,
        retryLabel: 'Retry',
        onRetry: () => ref.read(climateProvider.notifier).rebuild(),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(child: CircularProgressIndicator(color: AppColors.leaf500)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg + AppSpacing.xs),
    child: Text(title, style: AppText.h2.copyWith(color: AppColors.soil900)),
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => GeauxCard(
    child: Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: AppText.bodySm.copyWith(color: AppColors.soil600),
          ),
        ),
        GeauxButton(
          label: retryLabel,
          onPressed: onRetry,
          variant: GeauxButtonVariant.text,
        ),
      ],
    ),
  );
}

/// Back button, title, and the city pill.
class _Header extends StatelessWidget {
  const _Header({required this.city});

  final String city;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          label: 'Back',
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _back(context),
            child: const SizedBox.square(
              dimension: AppSpacing.minTouchTarget,
              child: _Capsule(
                padding: EdgeInsets.zero,
                child: Center(
                  child: Icon(
                    Symbols.chevron_left_rounded,
                    size: AppIconSize.xl,
                    color: AppColors.soil900,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Weather',
            textAlign: TextAlign.center,
            style: AppText.h1.copyWith(color: AppColors.soil900),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: _Capsule(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              6,
              AppSpacing.md,
              6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Symbols.location_on_rounded,
                  size: AppIconSize.md,
                  color: AppColors.leaf700,
                  fill: 1,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySm.copyWith(
                      color: AppColors.soil900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// White ledge capsule: 2 px stone border with a stone ledge underneath.
class _Capsule extends StatelessWidget {
  const _Capsule({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppRadii.pill));
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.stone200,
        borderRadius: radius,
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppBorders.ledge - AppBorders.width,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: radius,
            border: Border.all(
              color: AppColors.stone200,
              width: AppBorders.width,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
