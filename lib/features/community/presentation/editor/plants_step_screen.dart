import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../catalog/data/catalog_provider.dart';
import '../../../catalog/domain/plant.dart';
import '../../../catalog/presentation/plant_art.dart';
import '../../application/guide_editor_provider.dart';
import '../../domain/guide_validation.dart';
import 'editor_copy.dart';

/// How faint a result is once ten plants are picked and it cannot be added.
const double _disabledOpacity = 0.5;

/// CM-03d: pick 0–10 plants from the catalog for the guide. Only catalog
/// ids can be added, so a guide never points at a plant that does not exist.
///
/// A body widget: the host owns the app bar and the Back/Next bar.
class PlantsStepScreen extends ConsumerStatefulWidget {
  const PlantsStepScreen({super.key, required this.guideId});

  final String guideId;

  @override
  ConsumerState<PlantsStepScreen> createState() => _PlantsStepScreenState();
}

class _PlantsStepScreenState extends ConsumerState<PlantsStepScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    ref.read(guideEditorProvider(widget.guideId).notifier).edit((draft) {
      final ids = draft.plantIds;
      return draft.copyWith(
        plantIds: ids.contains(id)
            ? [
                for (final other in ids)
                  if (other != id) other,
              ]
            : [...ids, id],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(
      guideEditorProvider(widget.guideId).select((s) => s.draft.plantIds),
    );
    final error = ref.watch(
      guideEditorProvider(widget.guideId)
          .select((s) => s.errors[GuideField.plantIds]),
    );
    final catalog = ref.watch(catalogProvider);

    final plants = catalog.value;
    if (plants == null) {
      if (catalog.hasError) {
        return GeauxEmptyState(
          icon: Symbols.cloud_off_rounded,
          message: "Couldn't load plants.",
          action: GeauxButton(
            label: 'Retry',
            variant: GeauxButtonVariant.text,
            onPressed: () => ref.invalidate(catalogProvider),
          ),
        );
      }
      return const Center(
        child: CircularProgressIndicator(color: AppColors.leaf500),
      );
    }

    final byId = {for (final plant in plants) plant.id: plant};
    final query = _query.trim().toLowerCase();
    final results = [
      for (final plant in plants)
        if (plant.commonName.toLowerCase().contains(query)) plant,
    ];
    final full = selected.length >= guidePlantIdsMax;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              Text(
                'Plants in this guide',
                style: AppText.h1.copyWith(color: AppColors.soil900),
              ),
              Text(
                'Optional. Pick up to $guidePlantIdsMax plants from the '
                'catalog. ${selected.length} of $guidePlantIdsMax picked.',
                style: AppText.body.copyWith(color: AppColors.soil600),
              ),
              if (selected.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final id in selected)
                      _SelectedChip(
                        key: ValueKey('chip-$id'),
                        label: byId[id]?.commonName ?? id,
                        onRemove: () => _toggle(id),
                      ),
                  ],
                ),
              if (error != null)
                Text(
                  guideFieldErrorText(error),
                  style: AppText.bodySm.copyWith(color: AppColors.error),
                ),
              GeauxTextField(
                controller: _search,
                hintText: 'Search plants',
                prefixIcon: Symbols.search_rounded,
                textInputAction: TextInputAction.search,
                hasError: error != null,
                onChanged: (value) => setState(() => _query = value),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        if (results.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'No plants match "${_query.trim()}".',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.soil600),
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final plant = results[i];
              final picked = selected.contains(plant.id);
              final enabled = picked || !full;
              return _PlantResult(
                key: ValueKey('plant-${plant.id}'),
                plant: plant,
                selected: picked,
                enabled: enabled,
                onTap: () => _toggle(plant.id),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      ],
    );
  }
}

/// One catalog plant in the picker: a check toggles it, and it is faint
/// and inert once the guide already has ten other plants.
class _PlantResult extends StatelessWidget {
  const _PlantResult({
    super.key,
    required this.plant,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Plant plant;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = GeauxSelectCard(
      title: plant.commonName,
      subtitle: plant.scientificName,
      icon: plantArtStyle(plant.category).icon,
      multiSelect: true,
      selected: selected,
      onTap: onTap,
    );
    if (enabled) return card;
    return Semantics(
      enabled: false,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: _disabledOpacity,
          child: IgnorePointer(child: card),
        ),
      ),
    );
  }
}

/// A picked plant with a way to take it out again.
class _SelectedChip extends StatelessWidget {
  const _SelectedChip({super.key, required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Remove $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRemove,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: LedgeCapsule(
              color: AppColors.leaf100,
              borderColor: AppColors.leaf500,
              ledgeColor: AppColors.leaf500,
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.sm,
                top: AppSpacing.sm,
                bottom: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xs,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodySm.copyWith(
                        color: AppColors.leaf700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Symbols.close_rounded,
                    size: AppIconSize.md,
                    color: AppColors.leaf700,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
