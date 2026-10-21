// Issue #38: "Fall greens for Louisiana" must list kale, collards, Swiss
// chard and spinach in its plants section. The guide is the row of
// supabase/seed.sql, shown by the real CM-02 with the real catalog.
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/compat_badge.dart';

import '../helpers/app_fonts.dart';
import '../helpers/community_fixtures.dart';
import '../helpers/seed_guides.dart';
import 'guide_detail_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Fall greens for Louisiana lists its four plants', (
    tester,
  ) async {
    final fallGreens = seedGuide('Fall greens for Louisiana');
    expect(fallGreens.plantIds, [
      'kale',
      'collard-greens',
      'swiss-chard',
      'spinach',
    ]);
    final repo = FakeGuideRepository(guides: {fallGreens.id: fallGreens});
    await pumpGuideDetail(tester, repo, id: fallGreens.id, height: 4000);

    expect(find.text('Plants in this guide'), findsOneWidget);
    final names = ['Kale', 'Collard Greens', 'Swiss Chard', 'Spinach'];
    for (final name in names) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    // Exactly those four, each with a compatibility badge, top to bottom in
    // the order the guide lists them.
    expect(find.byType(CompatBadge), findsNWidgets(4));
    final tops = [for (final n in names) tester.getTopLeft(find.text(n)).dy];
    expect(tops, orderedEquals([...tops]..sort()));
    await unmount(tester);
  });

  testWidgets('the seed guide also shows its materials and steps', (
    tester,
  ) async {
    final fallGreens = seedGuide('Fall greens for Louisiana');
    final repo = FakeGuideRepository(guides: {fallGreens.id: fallGreens});
    await pumpGuideDetail(tester, repo, id: fallGreens.id, height: 4000);

    expect(find.text('Fall greens for Louisiana'), findsOneWidget);
    expect(find.text('Wait for cooler weather'), findsOneWidget);
    expect(find.textContaining('Frost cloth'), findsOneWidget);
    await unmount(tester);
  });
}
