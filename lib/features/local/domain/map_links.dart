/// Deep links that open a market in the platform's maps app (plan/08
/// § Markets). Pure: the caller passes the platform.
library;

/// Which maps scheme to build. The caller reads the real platform, so
/// these stay testable off-device.
enum MapPlatform { android, ios }

/// The maps URL for [name] at ([lat], [lon]).
///
/// Android uses the `geo:` scheme and iOS Apple Maps; the name is
/// percent-encoded for the query string.
Uri marketMapUrl({
  required MapPlatform platform,
  required String name,
  required double lat,
  required double lon,
}) {
  final q = Uri.encodeQueryComponent(name);
  return switch (platform) {
    MapPlatform.android => Uri.parse('geo:$lat,$lon?q=$q'),
    MapPlatform.ios => Uri.parse('https://maps.apple.com/?q=$q&ll=$lat,$lon'),
  };
}
