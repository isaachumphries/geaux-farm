import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';
import 'package:geaux_farm/features/local/data/markets_provider.dart';
import 'package:geaux_farm/features/local/domain/map_links.dart';
import 'package:geaux_farm/features/local/domain/market.dart';
import 'package:geaux_farm/features/local/presentation/markets_list.dart';

// plan/08 § Markets: rows show name, distance, and whatever of hours and
// website the OSM element carries; zero results show the exact empty copy.

const _market = Market(
  id: 'node/3001',
  name: 'Red Stick Farmers Market',
  lat: 30.45,
  lon: -91.19,
  distanceMi: 2.43,
  openingHours: 'Sa 08:00-12:00',
  website: 'https://example.test/red-stick',
);

Future<List<Uri>> _pump(
  WidgetTester tester,
  AsyncValue<List<Market>> markets,
) async {
  final launched = <Uri>[];
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        marketsProvider.overrideWith(() => _FixedMarkets(markets)),
        mapPlatformProvider.overrideWithValue(MapPlatform.android),
        mapLauncherProvider.overrideWithValue((uri) async {
          launched.add(uri);
          return true;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: MarketsList()),
      ),
    ),
  );
  await tester.pump();
  return launched;
}

void main() {
  testWidgets('a row shows the name, distance, hours and website', (
    tester,
  ) async {
    await _pump(tester, const AsyncData([_market]));

    expect(find.text('Red Stick Farmers Market'), findsOneWidget);
    expect(find.text('2.4 mi'), findsOneWidget);
    expect(find.text('Sa 08:00-12:00'), findsOneWidget);
    expect(find.text('https://example.test/red-stick'), findsOneWidget);
  });

  testWidgets('a market with no hours or website shows neither line', (
    tester,
  ) async {
    await _pump(
      tester,
      const AsyncData([
        Market(
          id: 'node/1',
          name: 'Bare Market',
          lat: 30.0,
          lon: -91.0,
          distanceMi: 1,
        ),
      ]),
    );

    expect(find.text('Bare Market'), findsOneWidget);
    expect(find.textContaining('http'), findsNothing);
  });

  testWidgets('rows keep the provider order', (tester) async {
    await _pump(
      tester,
      const AsyncData([
        Market(id: 'a', name: 'Nearest', lat: 30, lon: -91, distanceMi: 0.5),
        Market(id: 'b', name: 'Farther', lat: 30, lon: -91, distanceMi: 9.5),
      ]),
    );

    final names = tester
        .widgetList<MarketRow>(find.byType(MarketRow))
        .map((r) => r.market.name);
    expect(names, ['Nearest', 'Farther']);
  });

  testWidgets('zero results show the plan copy exactly', (tester) async {
    await _pump(tester, const AsyncData([]));

    expect(
      find.text('No markets found nearby. Know one? Add it to OpenStreetMap.'),
      findsOneWidget,
    );
    expect(find.byType(MarketRow), findsNothing);
  });

  testWidgets('an error shows Retry, not the empty copy', (tester) async {
    await _pump(tester, AsyncError(Exception('offline'), StackTrace.empty));

    expect(find.text(marketsErrorCopy), findsOneWidget);
    expect(find.text(marketsEmptyCopy), findsNothing);
    expect(find.text('RETRY'), findsOneWidget);
  });

  testWidgets('loading shows a spinner and no rows', (tester) async {
    await _pump(tester, const AsyncLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(MarketRow), findsNothing);
  });

  testWidgets('tapping a row launches the maps URL once', (tester) async {
    final launched = await _pump(tester, const AsyncData([_market]));

    await tester.tap(find.byType(MarketRow));
    await tester.pump();

    expect(launched, [
      Uri.parse('geo:30.45,-91.19?q=Red+Stick+Farmers+Market'),
    ]);
  });
}

/// A [marketsProvider] stuck in one state, so the widget can be pumped
/// without a network or a profile.
class _FixedMarkets extends MarketsNotifier {
  _FixedMarkets(this.value);

  final AsyncValue<List<Market>> value;

  @override
  Future<List<Market>> build() async {
    if (value case AsyncError(:final error, :final stackTrace)) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (value.isLoading) return Completer<List<Market>>().future;
    return value.requireValue;
  }
}
