import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The top-level `<key>`/`<string>` pairs of a plist. Values that are not
/// strings (`<true/>`, `<array>`) are skipped, but their keys still show up
/// in [plistKeys].
Map<String, String> plistStrings(String xml) => {
  for (final m in RegExp(
    r'<key>([^<]+)</key>\s*<string>([^<]*)</string>',
  ).allMatches(xml))
    m.group(1)!: m.group(2)!,
};

List<String> plistKeys(String xml) => [
  for (final m in RegExp(r'<key>([^<]+)</key>').allMatches(xml)) m.group(1)!,
];

void main() {
  // plan/02 § OB-02 permissions, as quoted in #45.
  const locationCopy =
      'Geaux Farm uses your location to look up your local climate.';

  final xml = File('ios/Runner/Info.plist').readAsStringSync();

  test('NSLocationWhenInUseUsageDescription has the exact plan copy', () {
    expect(
      plistStrings(xml)['NSLocationWhenInUseUsageDescription'],
      locationCopy,
    );
  });

  test('location is when-in-use only: no Always or background keys', () {
    final keys = plistKeys(xml);
    expect(keys.where((k) => k.startsWith('NSLocationAlways')), isEmpty);
    expect(keys, isNot(contains('NSLocationUsageDescription')));
    expect(xml, isNot(contains('<string>location</string>')));
  });

  test('the parser reads a pair and ignores non-string values', () {
    const sample =
        '<dict><key>A</key><string>x</string>'
        '<key>B</key><true/></dict>';
    expect(plistStrings(sample), {'A': 'x'});
    expect(plistKeys(sample), ['A', 'B']);
  });
}
