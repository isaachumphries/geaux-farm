import 'space.dart';

/// Area slider stops in sq ft (plan/02 § OB-03).
const areaStops = [2, 4, 8, 16, 32, 64, 128, 256, 500];

/// The area each space type starts the slider at.
const defaultAreaSqFt = {
  SpaceType.windowsill: 4,
  SpaceType.balcony: 16,
  SpaceType.smallYard: 32,
  SpaceType.largeYard: 128,
  SpaceType.communityPlot: 64,
};

/// The comparison shown after `≈ {n} sq ft · `.
String areaComparisonLabel(int sqFt) {
  if (sqFt <= 4) return 'a windowsill';
  if (sqFt <= 16) return 'a few big pots';
  if (sqFt <= 32) return 'a 4×8 raised bed';
  if (sqFt <= 128) return 'a small vegetable garden';
  return 'a big garden';
}

/// `rainExposed` and `inContainerDefault` for a space type. Only Balcony or
/// patio reads the rain switch.
({bool rainExposed, bool inContainerDefault}) derivedSpaceDefaults(
  SpaceType type,
  bool rainSwitchOn,
) => switch (type) {
  SpaceType.windowsill => (rainExposed: false, inContainerDefault: true),
  SpaceType.balcony => (rainExposed: rainSwitchOn, inContainerDefault: true),
  SpaceType.smallYard ||
  SpaceType.largeYard ||
  SpaceType.communityPlot => (rainExposed: true, inContainerDefault: false),
};
