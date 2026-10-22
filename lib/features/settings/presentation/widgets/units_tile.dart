import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../onboarding/data/profile_providers.dart';
import '../../../onboarding/data/profile_writer.dart';

/// The Units row on ST-01 Settings: °F/in or °C/mm for every reading the
/// app shows. Storage stays in °F and inches (plan/06 § Units).
class UnitsTile extends ConsumerWidget {
  const UnitsTile({super.key});

  static const double _tile = 36;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units =
        ref.watch(userProfileProvider.select((p) => p.value?.units)) ??
        'imperial';
    return GeauxCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: _tile,
                height: _tile,
                decoration: BoxDecoration(
                  color: AppColors.leaf100,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: const Icon(
                  Symbols.thermostat_rounded,
                  color: AppColors.leaf700,
                  size: AppIconSize.lg,
                  fill: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Units',
                  style: AppText.body.copyWith(color: AppColors.soil900),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GeauxSegmentedChoice<String>(
            options: const [('imperial', '°F / in'), ('metric', '°C / mm')],
            selected: units,
            onSelected: (value) {
              if (value != units) {
                ref.read(profileWriterProvider).setUnits(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
