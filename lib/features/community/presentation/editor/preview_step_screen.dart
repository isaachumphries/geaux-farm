import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../catalog/data/catalog_provider.dart';
import '../../../catalog/domain/plant.dart';
import '../../../catalog/presentation/plant_art.dart';
import '../../../onboarding/domain/space.dart';
import '../../application/community_feed_provider.dart';
import '../../application/guide_detail_provider.dart';
import '../../application/guide_editor_provider.dart';
import '../../domain/guide_labels.dart';
import '../../domain/guide_validation.dart';
import '../sign_in_sheet.dart';
import '../widgets/guide_info_row.dart';
import '../widgets/guide_sections.dart';
import 'editor_copy.dart';

/// CM-03e: the guide as CM-02 will show it, the reasons Publish was
/// blocked, and the Save draft and Publish buttons.
///
/// A body widget: the host owns the app bar and the Back/Next bar.
/// [onEditStep] sends the author to the step that holds a blocked field.
class PreviewStepScreen extends ConsumerWidget {
  const PreviewStepScreen({
    super.key,
    required this.guideId,
    required this.onEditStep,
  });

  final String guideId;
  final ValueChanged<EditorStep> onEditStep;

  /// Saves the draft once the user is signed in; a signed-out user sees
  /// CM-04 first and nothing is written.
  Future<void> _saveDraft(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context);
    return requireSignIn(
      context,
      ref,
      reason: SignInAction.publish,
      action: () async {
        final id = await container
            .read(guideEditorProvider(guideId).notifier)
            .saveDraft();
        if (id != null) {
          messenger.showSnackBar(const SnackBar(content: Text('Draft saved')));
        } else if (context.mounted) {
          await _askToSignIn(context, container);
        }
      },
    );
  }

  /// Publishes once the user is signed in, then opens the guide on CM-02.
  Future<void> _publish(BuildContext context, WidgetRef ref) {
    final container = ProviderScope.containerOf(context);
    return requireSignIn(
      context,
      ref,
      reason: SignInAction.publish,
      action: () async {
        final id = await container
            .read(guideEditorProvider(guideId).notifier)
            .publish();
        if (id == null) {
          if (context.mounted) await _askToSignIn(context, container);
          return;
        }
        // The feed and CM-02 may hold the guide from before this publish.
        container.invalidate(communityFeedProvider);
        container.invalidate(guideDetailProvider(id));
        if (context.mounted) context.go('/community/guide/$id');
        // The editor's draft is published: a later New guide starts blank
        // instead of updating this one.
        container.invalidate(guideEditorProvider(guideId));
      },
    );
  }

  /// A write the server refused as signed out (an expired session): the
  /// other failures show on the host's banner.
  Future<void> _askToSignIn(
    BuildContext context,
    ProviderContainer container,
  ) async {
    final error = container.read(guideEditorProvider(guideId)).writeError;
    if (isSignInRequired(error)) {
      await showSignInSheet(context, reason: SignInAction.publish);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(guideEditorProvider(guideId));
    final draft = state.draft;
    final busy = state.saving || state.loading;
    final catalog = {
      for (final plant in ref.watch(catalogProvider).value ?? const <Plant>[])
        plant.id: plant,
    };
    final spaces = [
      for (final name in draft.spaceTypes)
        if (SpaceType.values.asNameMap()[name] case final type?)
          guideSpaceTypeLabel(type),
    ];
    final plants = [
      for (final id in draft.plantIds)
        if (catalog[id] != null) catalog[id]!,
    ];
    final title = draft.title.trim();
    final summary = draft.summary.trim();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xl,
        children: [
          Text(
            title.isEmpty ? 'Untitled guide' : title,
            style: AppText.h1.copyWith(
              color: title.isEmpty ? AppColors.soil600 : AppColors.soil900,
            ),
          ),
          GuideInfoRow.draft(
            estCostUsd: draft.estCostUsd,
            setupMinutes: draft.setupMinutes,
            difficulty: draft.difficulty,
          ),
          if (spaces.isNotEmpty || draft.tags.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final label in spaces) _Pill(label: label),
                for (final tag in draft.tags) _Pill(label: guideTagLabel(tag)),
              ],
            ),
          if (summary.isNotEmpty)
            Text(
              summary,
              style: AppText.body.copyWith(color: AppColors.soil600),
            ),
          GuideSection(
            title: 'Materials',
            child: draft.materials.isEmpty
                ? const _Nothing()
                : GuideMaterials(materials: draft.materials),
          ),
          GuideSection(
            title: 'Steps',
            child: draft.steps.isEmpty
                ? const _Nothing()
                : GuideSteps(steps: draft.steps),
          ),
          if (plants.isNotEmpty)
            GuideSection(
              title: 'Plants in this guide',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: [for (final plant in plants) _PlantRow(plant: plant)],
              ),
            ),
          if (state.errors.isNotEmpty)
            _Blockers(errors: state.errors, onEditStep: onEditStep),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              if (state.canSaveDraft)
                GeauxButton(
                  label: 'Save draft',
                  variant: GeauxButtonVariant.secondary,
                  onPressed: busy || title.isEmpty
                      ? null
                      : () => _saveDraft(context, ref),
                ),
              GeauxButton(
                label: 'Publish',
                onPressed: busy ? null : () => _publish(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// A section the author has not filled in yet.
class _Nothing extends StatelessWidget {
  const _Nothing();

  @override
  Widget build(BuildContext context) {
    return Text('—', style: AppText.body.copyWith(color: AppColors.soil600));
  }
}

/// A space type or tag the guide will carry.
class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return LedgeCapsule(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: AppText.bodySm.copyWith(
          color: AppColors.soil900,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A catalog plant in the guide, as a card like CM-02's but without the
/// viewer's compatibility, which is not the author's to show.
class _PlantRow extends StatelessWidget {
  const _PlantRow({required this.plant});

  final Plant plant;

  static const double _artSize = 48;

  @override
  Widget build(BuildContext context) {
    return GeauxCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          PlantTile(category: plant.category, size: _artSize),
          Expanded(
            child: Text(
              plant.commonName,
              style: AppText.body.copyWith(
                color: AppColors.soil900,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Why Publish or Save draft is blocked: one row per field, with a way
/// back to the step that holds it.
class _Blockers extends StatelessWidget {
  const _Blockers({required this.errors, required this.onEditStep});

  final Map<String, GuideFieldError> errors;
  final ValueChanged<EditorStep> onEditStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Text(
          'Fix these first',
          style: AppText.h2.copyWith(color: AppColors.soil900),
        ),
        for (final MapEntry(:key, :value) in errors.entries)
          GeauxCard(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.xs,
            ),
            borderColor: AppColors.error,
            ledgeColor: AppColors.error,
            child: Row(
              spacing: AppSpacing.sm,
              children: [
                const Icon(
                  Symbols.error_rounded,
                  size: AppIconSize.lg,
                  color: AppColors.error,
                  fill: 1,
                ),
                Expanded(
                  child: Text(
                    guideFieldErrorText(value),
                    style: AppText.body.copyWith(color: AppColors.soil900),
                  ),
                ),
                GeauxButton(
                  label: 'Edit',
                  variant: GeauxButtonVariant.text,
                  onPressed: () => onEditStep(EditorStep.forField(key)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
