import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../domain/plant.dart';

/// The tint, glyph, and glyph color a plant category is drawn with on
/// cards and tiles (HM-01, RC-01, GD-01).
typedef PlantArtStyle = ({Color tint, IconData icon, Color ink});

PlantArtStyle plantArtStyle(PlantCategory category) => switch (category) {
  PlantCategory.vegetable => (
    tint: AppColors.leaf100,
    icon: Symbols.eco_rounded,
    ink: AppColors.leaf500,
  ),
  PlantCategory.herb => (
    tint: AppColors.leaf100,
    icon: Symbols.spa_rounded,
    ink: AppColors.leaf700,
  ),
  PlantCategory.flower => (
    tint: AppColors.tileSky,
    icon: Symbols.local_florist_rounded,
    ink: AppColors.tileSkyLedge,
  ),
  PlantCategory.fruit => (
    tint: AppColors.tilePeach,
    icon: Symbols.nutrition_rounded,
    ink: AppColors.heat,
  ),
  PlantCategory.shrub => (
    tint: AppColors.tileSoil,
    icon: Symbols.park_rounded,
    ink: AppColors.tileSoilLedge,
  ),
  PlantCategory.houseplant => (
    tint: AppColors.leaf100,
    icon: Symbols.potted_plant_rounded,
    ink: AppColors.leaf700,
  ),
};

/// A rounded square in the category tint with a halo disc and the category
/// glyph, as on the GD-01 planting cards.
class PlantTile extends StatelessWidget {
  const PlantTile({super.key, required this.category, this.size = 64});

  final PlantCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = plantArtStyle(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      padding: EdgeInsets.all(size / 10),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.artHalo,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(style.icon, size: size * 0.45, color: style.ink, fill: 1),
        ),
      ),
    );
  }
}
