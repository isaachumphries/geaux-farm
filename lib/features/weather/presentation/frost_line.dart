import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../onboarding/domain/climate_reveal_format.dart';
import '../domain/frost_copy.dart';
import 'climate_info_line.dart';

/// The WX-01 frost row. Shows the last spring frost, and the first fall frost
/// on a second line. Renders nothing when `lat < 0`, as OB-02b does.
class FrostLine extends StatelessWidget {
  const FrostLine({
    super.key,
    required this.lastSpringFrostDoy,
    required this.firstFallFrostDoy,
    required this.lat,
  });

  final int? lastSpringFrostDoy;
  final int? firstFallFrostDoy;
  final double lat;

  @override
  Widget build(BuildContext context) {
    final spring = frostLine(lastSpringFrostDoy, lat);
    if (spring == null) return const SizedBox.shrink();
    final fall = fallFrostLine(firstFallFrostDoy, lat);
    return ClimateInfoLine(
      icon: Symbols.severe_cold_rounded,
      tile: AppColors.tileSoil,
      ledge: AppColors.tileSoilLedge,
      lines: [spring, if (fall != null) fall],
    );
  }
}
