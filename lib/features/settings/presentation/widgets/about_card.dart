import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../weather/presentation/attribution_footer.dart';

/// USDA zone credit (plan/06 § Attribution and terms).
const zoneAttributionText = 'Hardiness zones: phzmapi.org / USDA';

/// The About group on ST-01 Settings: the data credits the app must keep
/// visible. Open-Meteo's links to its site, as on WX-01.
class AboutCard extends ConsumerWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GeauxCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            link: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref.read(linkOpenerProvider)(attributionUrl),
              child: _Line(
                icon: Symbols.partly_cloudy_day_rounded,
                text: attributionText,
                color: AppColors.leaf700,
                trailing: Symbols.open_in_new_rounded,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.stone200),
          const _Line(
            icon: Symbols.public_rounded,
            text: zoneAttributionText,
            color: AppColors.soil900,
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.text,
    required this.color,
    this.trailing,
  });

  final IconData icon;
  final String text;
  final Color color;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.md, color: AppColors.soil600),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text, style: AppText.bodySm.copyWith(color: color)),
          ),
          if (trailing != null)
            Icon(trailing, size: AppIconSize.sm, color: AppColors.soil600),
        ],
      ),
    );
  }
}
