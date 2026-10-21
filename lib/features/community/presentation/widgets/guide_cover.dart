import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';

/// Height of a guide card's cover (CM-01 export: 242 px at 2x).
const double guideCoverHeight = 120;

const double _discSize = 60;
const double _discRing = 4;
const double _discStep = 54;

/// The cover of a guide card: the uploaded image from [url], or the
/// three-disc art the Figma draws when there is none (or it fails to load).
class GuideCover extends StatelessWidget {
  const GuideCover({super.key, this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    return SizedBox(
      height: guideCoverHeight,
      width: double.infinity,
      child: url == null || url.isEmpty
          ? const _CoverArt()
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _CoverArt(),
            ),
    );
  }
}

class _CoverArt extends StatelessWidget {
  const _CoverArt();

  // (tint, icon, ink, filled): the fruit is drawn as an outline.
  static const _discs = [
    (AppColors.tilePeach, Symbols.nutrition_rounded, AppColors.heat, 0.0),
    (AppColors.leaf100, Symbols.spa_rounded, AppColors.leaf700, 1.0),
    (
      AppColors.gold100,
      Symbols.local_fire_department_rounded,
      AppColors.goldLedge,
      1.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.tileSky,
      child: Center(
        child: SizedBox(
          width: _discStep * (_discs.length - 1) + _discSize,
          height: _discSize,
          child: Stack(
            children: [
              for (var i = 0; i < _discs.length; i++)
                Positioned(
                  left: _discStep * i,
                  child: Container(
                    width: _discSize,
                    height: _discSize,
                    decoration: BoxDecoration(
                      color: _discs[i].$1,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white,
                        width: _discRing,
                      ),
                    ),
                    child: Icon(
                      _discs[i].$2,
                      size: 32,
                      color: _discs[i].$3,
                      fill: _discs[i].$4,
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
