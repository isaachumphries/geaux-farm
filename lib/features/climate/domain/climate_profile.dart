/// How the hardiness zone was obtained: USDA lookup or computed from the
/// annual extreme minimum.
enum ZoneSource { usda, computed }

/// Monthly climate normals in imperial units.
class ClimateMonth {
  const ClimateMonth({
    required this.month,
    required this.avgLowF,
    required this.avgHighF,
    required this.precipIn,
    required this.rhPct,
    required this.cloudPct,
    required this.sunshineHours,
  });

  /// 1–12.
  final int month;
  final double avgLowF, avgHighF, precipIn, rhPct, cloudPct, sunshineHours;

  double get meanF => (avgLowF + avgHighF) / 2;
}

class ClimateProfile {
  const ClimateProfile({
    required this.months,
    required this.annualExtremeMinF,
    required this.annualPrecipIn,
    required this.annualRhPct,
    required this.zone,
    required this.zoneSource,
    this.lastSpringFrostDoy,
    this.firstFallFrostDoy,
    required this.computedAt,
  });

  /// Index 0 = January.
  final List<ClimateMonth> months;
  final double annualExtremeMinF, annualPrecipIn, annualRhPct;
  final String zone;
  final ZoneSource zoneSource;
  final int? lastSpringFrostDoy, firstFallFrostDoy;
  final DateTime computedAt;
}
