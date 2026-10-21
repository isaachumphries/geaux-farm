import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../onboarding/domain/space.dart';
import '../../domain/guide_feed_query.dart';
import '../../domain/guide_labels.dart';
import 'feed_chip.dart';

/// Difficulty options in the filter sheet: any, then 1 to 3.
const _difficultyOptions = <(int?, String)>[
  (null, 'Any'),
  (1, 'Easy'),
  (2, 'Medium'),
  (3, 'Hard'),
];

/// Filters the sheet owns: difficulty and tags.
int _sheetFilterCount(GuideFeedQuery q) =>
    (q.difficulty == null ? 0 : 1) + q.tags.length;

/// The chip row under the tabs: "All", "Filters" for the sheet (difficulty
/// and tags), then one chip per space type. "Filters" sits next to "All" so
/// it is on screen without scrolling the row. Reports the new query through
/// [onChanged].
class FeedFilterRow extends StatelessWidget {
  const FeedFilterRow({
    super.key,
    required this.query,
    required this.onChanged,
  });

  final GuideFeedQuery query;
  final ValueChanged<GuideFeedQuery> onChanged;

  @override
  Widget build(BuildContext context) {
    final sheetCount = _sheetFilterCount(query);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          FeedChip(
            label: 'All',
            selected: query.spaceTypes.isEmpty,
            onTap: () => onChanged(query.copyWith(spaceTypes: const [])),
          ),
          FeedChip(
            label: sheetCount == 0 ? 'Filters' : 'Filters · $sheetCount',
            icon: Symbols.tune_rounded,
            selected: sheetCount > 0,
            onTap: () async {
              final next = await showModalBottomSheet<GuideFeedQuery>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _FilterSheet(initial: query),
              );
              if (next != null) onChanged(next);
            },
          ),
          for (final type in SpaceType.values)
            FeedChip(
              label: guideSpaceTypeLabel(type),
              selected: query.spaceTypes.contains(type.name),
              // One space type at a time; tapping it again clears it.
              onTap: () => onChanged(
                query.copyWith(
                  spaceTypes: query.spaceTypes.contains(type.name)
                      ? const []
                      : [type.name],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final GuideFeedQuery initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int? _difficulty = widget.initial.difficulty;
  late Set<String> _tags = {...widget.initial.tags};

  void _toggle(String tag) => setState(() {
    if (!_tags.remove(tag)) _tags.add(tag);
  });

  @override
  Widget build(BuildContext context) {
    final title = AppText.h2.copyWith(color: AppColors.soil900);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: title),
            const SizedBox(height: AppSpacing.lg),
            Text('Difficulty', style: AppText.label),
            const SizedBox(height: AppSpacing.sm),
            GeauxSegmentedChoice<int?>(
              options: _difficultyOptions,
              selected: _difficulty,
              onSelected: (d) => setState(() => _difficulty = d),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Tags', style: AppText.label),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in guideTags)
                  FeedChip(
                    label: guideTagLabel(tag),
                    selected: _tags.contains(tag),
                    onTap: () => _toggle(tag),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                GeauxButton(
                  label: 'Clear',
                  variant: GeauxButtonVariant.text,
                  onPressed: () => setState(() {
                    _difficulty = null;
                    _tags = {};
                  }),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GeauxButton(
                    label: 'Apply',
                    onPressed: () => Navigator.of(context).pop(
                      widget.initial
                          .withDifficulty(_difficulty)
                          .copyWith(
                            // Canonical order, so equal picks are equal
                            // queries.
                            tags: [
                              for (final t in guideTags)
                                if (_tags.contains(t)) t,
                            ],
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
