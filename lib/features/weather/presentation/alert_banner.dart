import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../domain/garden_alerts.dart';

/// plan/01 `AlertBanner` types.
enum AlertBannerType { frost, heat, rain, uv, offline }

/// A garden alert or the offline notice, in the shared banner container.
/// Each type has its own icon and tone; the copy comes from the alert rules
/// (plan/06 § Garden alerts) or is [offlineCopy].
class AlertBanner extends StatelessWidget {
  const AlertBanner._({super.key, required this.type, required this.message});

  /// The banner for one evaluated [alert].
  factory AlertBanner.alert(GardenAlert alert, {Key? key}) => AlertBanner._(
    key: key,
    type: switch (alert.type) {
      GardenAlertType.frost => AlertBannerType.frost,
      GardenAlertType.heat => AlertBannerType.heat,
      GardenAlertType.rain => AlertBannerType.rain,
      GardenAlertType.uv => AlertBannerType.uv,
    },
    message: alert.message,
  );

  /// Shown when the forecast on screen is the saved one (#27).
  const AlertBanner.offline({Key? key})
    : this._(key: key, type: AlertBannerType.offline, message: offlineCopy);

  static const offlineCopy = 'Showing saved weather';

  final AlertBannerType type;
  final String message;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color accent, Color tint) = switch (type) {
      AlertBannerType.frost => (
        Symbols.ac_unit_rounded,
        AppColors.frost,
        AppColors.tileSky,
      ),
      AlertBannerType.heat => (
        Symbols.thermostat_rounded,
        AppColors.heat,
        AppColors.tilePeach,
      ),
      AlertBannerType.rain => (
        Symbols.umbrella_rounded,
        AppColors.tileSkyLedge,
        AppColors.tileSky,
      ),
      AlertBannerType.uv => (
        Symbols.wb_sunny_rounded,
        AppColors.goldLedge,
        AppColors.gold100,
      ),
      AlertBannerType.offline => (
        Symbols.cloud_off_rounded,
        AppColors.soil600,
        AppColors.gold100,
      ),
    };
    // The copy reads "Frost Thu: cover or ..."; the part up to the colon is
    // the banner's bold title. Offline has no colon and shows as one line.
    final colon = message.indexOf(': ');
    return GeauxAlertBanner(
      lead: colon < 0 ? null : message.substring(0, colon + 1),
      message: colon < 0 ? message : message.substring(colon + 2),
      icon: icon,
      accent: accent,
      tint: tint,
    );
  }
}
