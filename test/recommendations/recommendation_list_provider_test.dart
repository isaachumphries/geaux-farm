import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/recommendations/application/recommendation_list_provider.dart';
import 'package:geaux_farm/features/recommendations/application/recommendations_provider.dart';
import 'package:geaux_farm/features/recommendations/domain/recommendation_filter.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';

import 'fixtures/scored.dart';

// RC-01's screen state (plan/09 § State management). The filter rules
// themselves live in the domain and are covered by filters_test.dart.
void main() {
  final basil = scored(
    kaleWith({
      'id': 'basil',
      'commonName': 'Sweet Basil',
      'scientificName': 'Ocimum basilicum',
      'category': 'herb',
    }),
  );
  final lavender = scored(
    kaleWith({
      'id': 'lavender',
      'commonName': 'English Lavender',
      'scientificName': 'Lavandula angustifolia',
      'category': 'flower',
    }),
  );

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        recommendationsProvider.overrideWithValue(AsyncData([basil, lavender])),
      ],
    );
    addTearDown(container.dispose);
  });

  RecommendationListFilterNotifier notifier() =>
      container.read(recommendationListFilterProvider.notifier);

  List<String> ids() => [
    for (final ScoredPlant s
        in container.read(filteredRecommendationsProvider).requireValue)
      s.plant.id,
  ];

  test('opens on All with no search and everything showing', () {
    final filter = container.read(recommendationListFilterProvider);
    expect(filter.chip, RecommendationChip.all);
    expect(filter.query, '');
    expect(filter.isFiltered, isFalse);
    expect(ids(), ['basil', 'lavender']);
  });

  test('a chip narrows the list and replaces the previous chip', () {
    notifier().selectChip(RecommendationChip.flowers);
    expect(ids(), ['lavender']);

    notifier().selectChip(RecommendationChip.herbs);
    expect(ids(), ['basil']);
    expect(container.read(recommendationListFilterProvider).isFiltered, isTrue);
  });

  test('search is ANDed with the chip', () {
    notifier().selectChip(RecommendationChip.herbs);
    notifier().search('lavandula');
    expect(ids(), isEmpty);

    notifier().search('BASIL');
    expect(ids(), ['basil']);
  });

  test('whitespace-only search does not count as filtering', () {
    notifier().search('   ');
    expect(
      container.read(recommendationListFilterProvider).isFiltered,
      isFalse,
    );
    expect(ids(), ['basil', 'lavender']);
  });

  test('a loading recommendations list stays loading', () {
    final loading = ProviderContainer(
      overrides: [
        recommendationsProvider.overrideWithValue(const AsyncLoading()),
      ],
    );
    addTearDown(loading.dispose);

    expect(loading.read(filteredRecommendationsProvider).isLoading, isTrue);
  });
}
