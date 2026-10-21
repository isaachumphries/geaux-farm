import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../data/markets_provider.dart';
import '../domain/market.dart';

/// Shown when the search returns nothing (plan/08 § Markets, verbatim).
const marketsEmptyCopy =
    'No markets found nearby. Know one? Add it to OpenStreetMap.';

/// Shown when Overpass could not be reached.
const marketsErrorCopy = "Couldn't load markets.";

/// The Markets segment of LC-01: farmers markets near the profile
/// location, nearest first. #72 places this in the Local hub.
class MarketsList extends ConsumerWidget {
  const MarketsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markets = ref.watch(marketsProvider);
    return switch (markets) {
      AsyncData(:final value) when value.isEmpty => const GeauxEmptyState(
        message: marketsEmptyCopy,
        icon: Symbols.storefront_rounded,
      ),
      AsyncData(:final value) => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: value.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) => MarketRow(market: value[i]),
      ),
      AsyncError() => GeauxEmptyState(
        message: marketsErrorCopy,
        icon: Symbols.cloud_off_rounded,
        action: GeauxButton(
          label: 'Retry',
          variant: GeauxButtonVariant.text,
          onPressed: () => ref.read(marketsProvider.notifier).refresh(),
        ),
      ),
      _ => const Center(
        child: CircularProgressIndicator(color: AppColors.leaf500),
      ),
    };
  }
}

/// One market: name, distance, and whatever of hours and website the OSM
/// element carries. Tapping opens the platform's maps app.
class MarketRow extends ConsumerWidget {
  const MarketRow({super.key, required this.market});

  final Market market;

  /// "2.4 mi" — one decimal, as on the other distance rows.
  static String distanceLabel(double miles) => '${miles.toStringAsFixed(1)} mi';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hours = market.openingHours;
    final website = market.website;
    return GeauxCard(
      onTap: () => ref.read(marketsProvider.notifier).openInMaps(market),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  market.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(color: AppColors.soil900),
                ),
                if (hours != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _Line(icon: Symbols.schedule_rounded, text: hours),
                ],
                if (website != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _Line(icon: Symbols.link_rounded, text: website),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            distanceLabel(market.distanceMi),
            style: AppText.bodySm.copyWith(
              color: AppColors.soil600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppIconSize.xs, color: AppColors.leaf700),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(color: AppColors.soil600),
          ),
        ),
      ],
    );
  }
}
