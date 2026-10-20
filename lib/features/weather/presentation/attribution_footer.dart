import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';

/// Opens a link outside the app; override in tests.
final linkOpenerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Open-Meteo's CC BY 4.0 credit, shown on WX-01 in every state.
const attributionText = 'Weather data by Open-Meteo.com (CC BY 4.0)';
final attributionUrl = Uri.parse('https://open-meteo.com/');

class AttributionFooter extends ConsumerWidget {
  const AttributionFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      link: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(linkOpenerProvider)(attributionUrl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Symbols.info_rounded,
                size: AppIconSize.xs,
                fill: 1,
                color: AppColors.soil600,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  attributionText,
                  style: AppText.label.copyWith(
                    color: AppColors.frost,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
