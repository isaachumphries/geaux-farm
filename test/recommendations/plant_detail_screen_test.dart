import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/catalog/data/catalog_provider.dart';
import 'package:geaux_farm/features/catalog/data/catalog_repository.dart';
import 'package:geaux_farm/features/catalog/domain/plant.dart';
import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';
import 'package:geaux_farm/features/onboarding/data/profile_providers.dart';
import 'package:geaux_farm/features/recommendations/application/clock_provider.dart';
import 'package:geaux_farm/features/recommendations/application/plant_detail_provider.dart';
import 'package:geaux_farm/features/recommendations/domain/scored_plant.dart';
import 'package:geaux_farm/features/recommendations/presentation/plant_detail_screen.dart';
import 'package:geaux_farm/features/recommendations/presentation/widgets/compat_badge.dart';
import 'package:geaux_farm/features/weather/presentation/attribution_footer.dart';

import '../helpers/file_asset_bundle.dart';
import '../helpers/fixed_climate.dart';
import 'fixtures/baton_rouge.dart' as fx;
import 'fixtures/scored.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Cold enough that no month suits basil outdoors.
final _coldClimate = ClimateProfile(
  months: [
    for (var m = 1; m <= 12; m++)
      ClimateMonth(
        month: m,
        avgLowF: 10,
        avgHighF: 30,
        precipIn: 3,
        rhPct: 70,
        cloudPct: 50,
        sunshineHours: 150,
      ),
  ],
  annualExtremeMinF: -5,
  annualPrecipIn: 40,
  annualRhPct: 70,
  zone: '5a',
  zoneSource: ZoneSource.computed,
  computedAt: DateTime.utc(2026, 10, 7),
);

List<Override> _overrides({ClimateProfile? climate, DateTime? now}) => [
  assetBundleProvider.overrideWithValue(FileAssetBundle()),
  clockProvider.overrideWithValue(() => now ?? DateTime(2026, 10, 7, 9)),
  userProfileProvider.overrideWith(
    (ref) => Stream.value(fx.workedExampleProfile),
  ),
  primarySpaceProvider.overrideWith((ref) => Stream.value(fx.balcony(32))),
  climateProvider.overrideWith(() => FixedClimate(climate)),
];

Future<void> _pump(
  WidgetTester tester, {
  required String plantId,
  required List<Override> overrides,
  ValueChanged<ScoredPlant>? onGrow,
}) async {
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: PlantDetailScreen(plantId: plantId, onGrow: onGrow),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<PlantDetailView?> _readView(String id, List<Override> overrides) async {
  final container = ProviderContainer(overrides: overrides);
  try {
    return await container.read(plantDetailProvider(id).future);
  } finally {
    container.dispose();
  }
}

Future<PlantDetailView> _view(
  WidgetTester tester,
  String id,
  List<Override> overrides,
) async {
  return (await tester.runAsync(() => _readView(id, overrides)))!;
}

Future<Plant> _plant(WidgetTester tester, String id) async {
  final plants = (await tester.runAsync(() => loadPlants(FileAssetBundle())))!;
  return plants.firstWhere((p) => p.id == id);
}

void main() {
  testWidgets('english-lavender shows score, bars, care, and season', (
    tester,
  ) async {
    final plant = await _plant(tester, 'english-lavender');
    await _pump(tester, plantId: 'english-lavender', overrides: _overrides());

    expect(find.text(plant.commonName), findsOneWidget);
    expect(find.text('74 · Good fit'), findsOneWidget);
    expect(find.text('Why it fits'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('50%'), findsNWidgets(2));
    expect(find.text('100%'), findsNWidgets(2));
    expect(find.text('Daily care'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Weekly care'), findsOneWidget);
    expect(find.text('~5m'), findsOneWidget);
    expect(find.text('Low care'), findsOneWidget);
    expect(find.text('Perennial'), findsOneWidget);
    expect(find.text('Evergreen'), findsOneWidget);
    expect(find.text('Indoor / greenhouse'), findsNothing);
  });

  testWidgets('header shows scientific name and category under the name', (
    tester,
  ) async {
    await _pump(tester, plantId: 'kale', overrides: _overrides());
    expect(
      find.text('Brassica oleracea var. sabellica · Vegetable'),
      findsOneWidget,
    );
    final name = tester.getTopLeft(find.text('Kale')).dy;
    final line = tester.getTopLeft(
      find.text('Brassica oleracea var. sabellica · Vegetable'),
    );
    final badge = tester.getTopLeft(find.textContaining('Great fit')).dy;
    expect(line.dy, greaterThan(name));
    expect(badge, greaterThan(line.dy));

    await _pump(tester, plantId: 'english-lavender', overrides: _overrides());
    expect(find.text('Lavandula angustifolia · Flower'), findsOneWidget);
  });

  testWidgets('time to grow, daily, and weekly care show as stat cards', (
    tester,
  ) async {
    await _pump(tester, plantId: 'kale', overrides: _overrides());
    expect(find.text('Time to grow'), findsOneWidget);
    expect(find.text('Harvest in 50–65 days'), findsOneWidget);
    expect(find.text('Daily care'), findsOneWidget);
    expect(find.text('~2m'), findsOneWidget);
    expect(find.text('Weekly care'), findsOneWidget);
    expect(find.text('~10m'), findsOneWidget);
    expect(find.text('Low care'), findsOneWidget);
  });

  testWidgets('Plant now ribbon shows only for an in-season plant', (
    tester,
  ) async {
    final inSeason = _overrides();
    final kale = await _view(tester, 'kale', inSeason);
    expect(kale.compat.inSeason, isTrue);
    await _pump(tester, plantId: 'kale', overrides: inSeason);
    expect(find.text('PLANT NOW'), findsOneWidget);
    expect(find.text('Indoor / greenhouse'), findsNothing);

    final january = _overrides(now: DateTime(2026, 1, 7, 9));
    final basil = await _view(tester, 'sweet-basil', january);
    expect(basil.compat.inSeason, isFalse);
    expect(basil.compat.outdoorViable, isTrue);
    await _pump(tester, plantId: 'sweet-basil', overrides: january);
    expect(find.text('PLANT NOW'), findsNothing);
    expect(find.text('Indoor / greenhouse'), findsNothing);
  });

  testWidgets('indoor-only plant shows no Plant now ribbon', (tester) async {
    await _pump(
      tester,
      plantId: 'sweet-basil',
      overrides: _overrides(climate: _coldClimate),
    );
    expect(find.text('Indoor / greenhouse'), findsOneWidget);
    expect(find.text('PLANT NOW'), findsNothing);
  });

  testWidgets('sweet-basil shows harvest window, credit, and tips in order', (
    tester,
  ) async {
    final plant = await _plant(tester, 'sweet-basil');
    await _pump(tester, plantId: 'sweet-basil', overrides: _overrides());

    expect(find.text('100 · Great fit'), findsOneWidget);
    expect(find.text('100%'), findsNWidgets(6));
    expect(plant.timeToGrowLabel, isNotNull);
    expect(find.text(plant.timeToGrowLabel!), findsOneWidget);
    expect(find.text('Warm-season'), findsOneWidget);
    expect(
      find.text('Image credit: ${plant.image.credit} · ${plant.image.license}'),
      findsOneWidget,
    );
    expect(find.text('Indoor / greenhouse'), findsNothing);

    final tops = [
      for (final tip in plant.tips) tester.getTopLeft(find.text(tip)).dy,
    ];
    expect(tops, hasLength(plant.tips.length));
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]), reason: plant.tips[i]);
    }
  });

  testWidgets('month strip labels in-season months and the current month', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final overrides = _overrides();
    final view = await _view(tester, 'sweet-basil', overrides);
    await _pump(tester, plantId: 'sweet-basil', overrides: overrides);

    final currentIndex = DateTime(2026, 10, 7).month - 1;
    expect(view.compat.monthStrip.any((inSeason) => inSeason), isTrue);
    for (var i = 0; i < 12; i++) {
      final inSeason = view.compat.monthStrip[i];
      final label = [
        _monthNames[i],
        if (inSeason) 'good time to plant',
        if (i == currentIndex) 'this month',
      ].join(', ');
      expect(
        find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}\$')),
        findsOneWidget,
        reason: label,
      );
    }
    expect(find.text('Good time to plant'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Grow this calls onGrow once with the plant as scored here', (
    tester,
  ) async {
    final grown = <ScoredPlant>[];
    await _pump(
      tester,
      plantId: 'sweet-basil',
      overrides: _overrides(),
      onGrow: grown.add,
    );
    await tester.tap(find.text('GROW THIS'));
    await tester.pump();
    expect(grown, hasLength(1));
    expect(grown.single.plant.id, 'sweet-basil');
    final badge = tester.widget<CompatBadge>(find.byType(CompatBadge).first);
    expect(grown.single.compatibility.score, badge.score);
  });

  testWidgets('Grow this stays pinned while the body scrolls', (tester) async {
    await _pump(tester, plantId: 'english-lavender', overrides: _overrides());

    final button = find.text('GROW THIS');
    final buttonBefore = tester.getRect(button);
    final whyBefore = tester.getTopLeft(find.text('Why it fits')).dy;
    expect(buttonBefore.bottom, lessThanOrEqualTo(800));
    expect(
      find.ancestor(of: button, matching: find.byType(SingleChildScrollView)),
      findsNothing,
    );

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Why it fits')).dy, lessThan(whyBefore));
    expect(tester.getRect(button), buttonBefore);
  });

  testWidgets('indoor chip shows when outdoor growing is not viable', (
    tester,
  ) async {
    await _pump(
      tester,
      plantId: 'sweet-basil',
      overrides: _overrides(climate: _coldClimate),
    );
    expect(find.text('Indoor / greenhouse'), findsOneWidget);
  });

  testWidgets('unknown plant id shows a not-in-catalog message', (
    tester,
  ) async {
    await _pump(tester, plantId: 'no-such-plant', overrides: _overrides());
    expect(find.text('This plant is not in the catalog.'), findsOneWidget);
  });

  testWidgets('the image credit line opens the record sourceUrl', (
    tester,
  ) async {
    final plant = await _plant(tester, 'kale');
    final opened = <Uri>[];
    await _pump(
      tester,
      plantId: 'kale',
      overrides: [
        ..._overrides(),
        linkOpenerProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
    );
    final credit = find.text(
      'Image credit: ${plant.image.credit} · ${plant.image.license}',
    );
    await tester.ensureVisible(credit);
    await tester.tap(credit);
    await tester.pump();
    expect(opened, [Uri.parse(plant.image.sourceUrl!)]);
  });

  testWidgets('the image credit line is plain text without a sourceUrl', (
    tester,
  ) async {
    final base = kaleWith({});
    final noLink = kaleWith({
      'image': {
        'asset': base.image.asset,
        'credit': base.image.credit,
        'license': base.image.license,
      },
    });
    final opened = <Uri>[];
    await _pump(
      tester,
      plantId: noLink.id,
      overrides: [
        ..._overrides(),
        catalogProvider.overrideWith((ref) async => [noLink]),
        linkOpenerProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
    );
    final credit = find.text(
      'Image credit: ${noLink.image.credit} · ${noLink.image.license}',
    );
    await tester.ensureVisible(credit);
    await tester.tap(credit);
    await tester.pump();
    expect(opened, isEmpty);
  });

  for (final count in [2, 3, 4]) {
    testWidgets('a record with $count tips shows all of them in order', (
      tester,
    ) async {
      final tips = [for (var i = 1; i <= count; i++) 'Tip number $i here.'];
      final plant = kaleWith({'tips': tips});
      await _pump(
        tester,
        plantId: plant.id,
        overrides: [
          ..._overrides(),
          catalogProvider.overrideWith((ref) async => [plant]),
        ],
      );
      final tops = <double>[];
      for (final tip in tips) {
        final finder = find.text(tip);
        await tester.ensureVisible(finder);
        await tester.pump();
        tops.add(tester.getTopLeft(finder).dy);
      }
      expect(find.textContaining('Tip number'), findsNWidgets(count));
      expect(tops, [...tops]..sort());
    });
  }

  testWidgets('a plant with no daily care shows a dash, not 0m', (
    tester,
  ) async {
    final plant = kaleWith({
      'care': {
        ...fx.rawKale()['care'] as Map<String, dynamic>,
        'dailyMinutes': 0,
      },
    });
    await _pump(
      tester,
      plantId: plant.id,
      overrides: [
        ..._overrides(),
        catalogProvider.overrideWith((ref) async => [plant]),
      ],
    );
    expect(find.text('Daily care'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('~0m'), findsNothing);
  });

  testWidgets('sweet-basil: April is a gold month cell and December is not', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, plantId: 'sweet-basil', overrides: _overrides());
    Color? fillOf(String month) {
      final cell = find.byWidgetPredicate(
        (w) =>
            w is Semantics && (w.properties.label?.startsWith(month) ?? false),
      );
      final box = tester
          .widget<DecoratedBox>(
            find.descendant(of: cell, matching: find.byType(DecoratedBox)),
          )
          .decoration;
      return (box as BoxDecoration).color;
    }

    expect(fillOf('April'), AppColors.geauxGold);
    expect(fillOf('December'), isNot(AppColors.geauxGold));
    handle.dispose();
  });
}
