import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../climate/domain/climate_profile.dart';
import '../../onboarding/domain/climate_reveal_format.dart';
import '../domain/weather_format.dart';
import 'climate_chart.dart';
import 'climate_info_line.dart';
import 'frost_line.dart';

/// WX-01 section 5 body: the monthly chart card and the zone, frost,
/// humidity and rain rows. The frost row is the only cut-candidate piece
/// ([FrostLine]).
class ClimateSection extends StatelessWidget {
  const ClimateSection({
    super.key,
    required this.profile,
    required this.city,
    required this.lat,
    required this.metric,
    required this.currentMonth,
  });

  final ClimateProfile profile;
  final String city;
  final double lat;
  final bool metric;

  /// 1–12.
  final int currentMonth;

  static const zoneSourceCopy = {
    ZoneSource.usda: 'USDA',
    ZoneSource.computed: 'Estimated from 5 years of local data',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly averages from 5 years of $city weather.',
          style: AppText.bodySm.copyWith(color: AppColors.soil600),
        ),
        const SizedBox(height: AppSpacing.md),
        GeauxCard(
          child: ClimateChart(
            profile: profile,
            metric: metric,
            currentMonth: currentMonth,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GeauxCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              ClimateInfoLine(
                icon: Symbols.location_on_rounded,
                tile: AppColors.leaf100,
                ledge: AppColors.leaf700,
                label: 'Hardiness zone',
                lines: [
                  'Zone ${profile.zone}',
                  zoneSourceCopy[profile.zoneSource]!,
                ],
              ),
              FrostLine(
                lastSpringFrostDoy: profile.lastSpringFrostDoy,
                firstFallFrostDoy: profile.firstFallFrostDoy,
                lat: lat,
              ),
              ClimateInfoLine(
                icon: Symbols.waves_rounded,
                tile: AppColors.tileSky,
                ledge: AppColors.frost,
                label: 'Humidity',
                lines: [humidityLabel(profile.annualRhPct)],
                detail: '${profile.annualRhPct.round()}% average',
                divided: true,
              ),
              ClimateInfoLine(
                icon: Symbols.umbrella_rounded,
                tile: AppColors.tileSoil,
                ledge: AppColors.tileSoilLedge,
                label: 'Rain',
                lines: [annualRainText(profile.annualPrecipIn, metric: metric)],
                divided: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
