import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/data/remix_payload.dart';
import 'package:geaux_farm/features/community/domain/guide.dart';

import '../../helpers/community_fixtures.dart';

// plan/07 § Remix: a draft with forked_from, "Remix of {title}" cut to 80,
// the content copied, the cover and step images left behind.

void main() {
  final original = testGuide(
    'g1',
    title: 'Fall greens for Louisiana',
    difficulty: 2,
    spaceTypes: const ['balcony', 'smallYard'],
    tags: const ['budget', 'fall'],
    cost: 40,
    setupMinutes: 90,
    coverPath: 'author-geauxfarm/cover.jpg',
    materials: const [
      GuideMaterial(name: 'Grow bag', qty: '2', estCostUsd: 12, url: 'x.test'),
      GuideMaterial(name: 'Potting mix', qty: '1 bag'),
    ],
    steps: const [
      GuideStep(title: 'Fill', body: 'Fill the bags.', imagePath: 'a/1.jpg'),
      GuideStep(title: 'Sow', body: 'Sow thinly.', imagePath: 'a/2.jpg'),
    ],
    plantIds: const ['kale', 'lettuce'],
  );

  test('points back at the original as a draft', () {
    final payload = buildRemixPayload(original);

    expect(payload['forked_from'], 'g1');
    expect(payload['status'], 'draft');
  });

  test('a short title is kept whole after the prefix', () {
    expect(
      buildRemixPayload(original)['title'],
      'Remix of Fall greens for Louisiana',
    );
  });

  test('a 75-character title becomes an 80-character remix title', () {
    final title = 'a' * 75;

    final remixTitle =
        buildRemixPayload(testGuide('g2', title: title))['title'] as String;

    expect(remixTitle, hasLength(80));
    expect(remixTitle, startsWith('Remix of '));
    expect(remixTitle, 'Remix of ${'a' * 71}');
  });

  test('a title that just fits is not cut', () {
    final remixTitle =
        buildRemixPayload(testGuide('g2', title: 'b' * 71))['title'] as String;

    expect(remixTitle, 'Remix of ${'b' * 71}');
  });

  test('copies the content columns', () {
    final payload = buildRemixPayload(original);

    expect(payload['summary'], original.summary);
    expect(payload['difficulty'], 2);
    expect(payload['space_types'], ['balcony', 'smallYard']);
    expect(payload['est_cost_usd'], 40);
    expect(payload['setup_minutes'], 90);
    expect(payload['plant_ids'], ['kale', 'lettuce']);
    expect(payload['tags'], ['budget', 'fall']);
    expect(payload['materials'], [
      {'name': 'Grow bag', 'qty': '2', 'estCostUsd': 12, 'url': 'x.test'},
      {'name': 'Potting mix', 'qty': '1 bag', 'estCostUsd': null, 'url': null},
    ]);
  });

  test('every step keeps its text and loses its image', () {
    expect(buildRemixPayload(original)['steps'], [
      {'title': 'Fill', 'body': 'Fill the bags.', 'imagePath': null},
      {'title': 'Sow', 'body': 'Sow thinly.', 'imagePath': null},
    ]);
  });

  test('the cover is not copied', () {
    final payload = buildRemixPayload(original);

    expect(payload.containsKey('cover_path'), isTrue);
    expect(payload['cover_path'], isNull);
  });

  test('sends no trigger-owned counter', () {
    final payload = buildRemixPayload(original);

    for (final key in [
      'star_count',
      'grow_count',
      'remix_count',
      'report_count',
    ]) {
      expect(payload.containsKey(key), isFalse, reason: key);
    }
  });
}
