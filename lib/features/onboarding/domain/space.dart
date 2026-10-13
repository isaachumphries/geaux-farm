/// Kind of growing space chosen in OB-03 (plan/02 § Stored values).
enum SpaceType { windowsill, balcony, smallYard, largeYard, communityPlot }

/// Sun the space gets, from OB-03; scoring levels shade = 0, partial = 1,
/// full = 2.
enum SunLevel { shade, partial, full }

/// A growing space (Drift `spaces`).
class Space {
  const Space({
    required this.id,
    required this.type,
    required this.areaSqFt,
    required this.sun,
    this.sunUnsure = false,
    required this.rainExposed,
    required this.inContainerDefault,
    this.isPrimary = true,
  });

  final String id;
  final SpaceType type;
  final int areaSqFt;
  final SunLevel sun;
  final bool sunUnsure;
  final bool rainExposed;
  final bool inContainerDefault;
  final bool isPrimary;
}
