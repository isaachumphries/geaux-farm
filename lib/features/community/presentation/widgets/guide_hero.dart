import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';

/// Height of the hero band; the sheet with the title overlaps its bottom
/// [AppRadii.sheet] (CM-02 export: the sheet starts ~256 dp from the top).
const double guideHeroHeight = 280;

const double _artWidth = 296;

/// Sunlit disc behind the art, sampled from the CM-02 export.
const _disc = Color(0xFFFBE59A);

/// The top of CM-02: the guide's cover from [url], or the three plant tiles
/// the Figma draws when it has none (or the image fails to load).
class GuideHero extends StatelessWidget {
  const GuideHero({super.key, this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    return SizedBox(
      height: guideHeroHeight,
      width: double.infinity,
      child: url == null || url.isEmpty
          ? const _HeroArt()
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _HeroArt(),
            ),
    );
  }
}

class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: AppColors.gold100,
        child: Stack(
          children: [
            const Positioned(
              right: -80,
              top: -90,
              child: SizedBox.square(
                dimension: 300,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _disc,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 98,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: _artWidth,
                  height: 120,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: 22,
                        child: _Tile(
                          size: 92,
                          tint: AppColors.tilePeach,
                          icon: Symbols.nutrition_rounded,
                          ink: AppColors.heat,
                          filled: false,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 26,
                        child: _Tile(
                          size: 96,
                          tint: AppColors.cream50,
                          icon: Symbols.park_rounded,
                          ink: AppColors.leaf700,
                        ),
                      ),
                      Positioned(
                        left: 82,
                        top: 0,
                        child: _Tile(
                          size: 120,
                          tint: AppColors.leaf100,
                          icon: Symbols.spa_rounded,
                          ink: AppColors.leaf700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.size,
    required this.tint,
    required this.icon,
    required this.ink,
    this.filled = true,
  });

  final double size;
  final Color tint;
  final IconData icon;
  final Color ink;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Center(
          child: Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: const BoxDecoration(
              color: AppColors.artHalo,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: size * 0.42,
              color: ink,
              fill: filled ? 1 : 0,
            ),
          ),
        ),
      ),
    );
  }
}
