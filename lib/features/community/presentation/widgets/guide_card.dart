import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../domain/guide.dart';
import '../../domain/guide_labels.dart';
import 'guide_cover.dart';

const double _statIcon = AppIconSize.sm;
const double _avatarSize = 20;
const double _growMarkSize = 14;
const double _bodyInset = 14;

/// A guide in the feed (CM-01): cover, title, author, and the star / grow /
/// remix counts with cost and difficulty. [coverUrl] is the public URL of
/// the guide's cover, if it has one.
class GuideCard extends StatelessWidget {
  const GuideCard({super.key, required this.guide, this.coverUrl, this.onTap});

  final Guide guide;
  final String? coverUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cost = guide.estCostUsd;
    return GeauxCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppBorders.width),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.card - AppBorders.width),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GuideCover(url: coverUrl),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _bodyInset,
                AppSpacing.md,
                _bodyInset,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guide.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle.copyWith(color: AppColors.soil900),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Container(
                        width: _avatarSize,
                        height: _avatarSize,
                        decoration: const BoxDecoration(
                          color: AppColors.tileSkyLedge,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '@${guide.authorUsername}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySm.copyWith(
                            color: AppColors.soil600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _Stat(
                        icon: const Icon(
                          Symbols.star_rounded,
                          size: _statIcon,
                          color: AppColors.geauxGold,
                          fill: 1,
                        ),
                        text: '${guide.starCount}',
                      ),
                      _Stat(
                        icon: const _GrowMark(),
                        text: '${guide.growCount}',
                      ),
                      _Stat(
                        icon: const Icon(
                          Symbols.call_split_rounded,
                          size: _statIcon,
                          color: AppColors.tileSkyLedge,
                        ),
                        text: '${guide.remixCount}',
                      ),
                      if (cost != null)
                        _Stat(
                          icon: const Icon(
                            Symbols.payments_rounded,
                            size: _statIcon,
                            color: AppColors.soil600,
                            fill: 1,
                          ),
                          text: '\$$cost',
                        ),
                      _Stat(
                        icon: const Icon(
                          Symbols.signal_cellular_alt_rounded,
                          size: _statIcon,
                          color: AppColors.soil600,
                        ),
                        text: guideDifficultyLabel(guide.difficulty),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: AppSpacing.xs + 2),
        Text(text, style: AppText.bodySm.copyWith(color: AppColors.soil900)),
      ],
    );
  }
}

/// The green flower tile that marks "growing this" counts.
class _GrowMark extends StatelessWidget {
  const _GrowMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _growMarkSize,
      height: _growMarkSize,
      decoration: BoxDecoration(
        color: AppColors.leaf500,
        borderRadius: BorderRadius.circular(AppRadii.chip / 2),
      ),
      child: const Icon(
        Symbols.local_florist_rounded,
        size: _growMarkSize - 4,
        color: AppColors.white,
        fill: 1,
      ),
    );
  }
}
