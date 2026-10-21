import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recommendation_filter.dart';
import '../domain/scored_plant.dart';
import 'recommendations_provider.dart';

/// RC-01's screen state: the active chip and the search box's text.
class RecommendationListFilter {
  const RecommendationListFilter({
    this.chip = RecommendationChip.all,
    this.query = '',
  });

  final RecommendationChip chip;
  final String query;

  /// True once the user has narrowed the list, which is what tells "no
  /// matches" apart from an empty catalog.
  bool get isFiltered =>
      chip != RecommendationChip.all || query.trim().isNotEmpty;

  RecommendationListFilter copyWith({
    RecommendationChip? chip,
    String? query,
  }) => RecommendationListFilter(
    chip: chip ?? this.chip,
    query: query ?? this.query,
  );

  @override
  bool operator ==(Object other) =>
      other is RecommendationListFilter &&
      other.chip == chip &&
      other.query == query;

  @override
  int get hashCode => Object.hash(chip, query);
}

/// The chip and search text RC-01 is showing. One chip is active at a
/// time, so selecting one replaces the previous selection.
final recommendationListFilterProvider =
    NotifierProvider<
      RecommendationListFilterNotifier,
      RecommendationListFilter
    >(RecommendationListFilterNotifier.new);

class RecommendationListFilterNotifier
    extends Notifier<RecommendationListFilter> {
  @override
  RecommendationListFilter build() => const RecommendationListFilter();

  void selectChip(RecommendationChip chip) =>
      state = state.copyWith(chip: chip);

  void search(String query) => state = state.copyWith(query: query);
}

/// [recommendationsProvider] narrowed by the active chip and search text,
/// in the provider's order. Nothing is re-sorted here (plan/04 § Filters).
final filteredRecommendationsProvider = Provider<AsyncValue<List<ScoredPlant>>>(
  (ref) {
    final filter = ref.watch(recommendationListFilterProvider);
    return ref
        .watch(recommendationsProvider)
        .whenData(
          (items) =>
              applyRecommendationFilter(items, filter.chip, filter.query),
        );
  },
);
