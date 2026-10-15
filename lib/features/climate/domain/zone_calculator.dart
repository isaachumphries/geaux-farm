/// USDA-style hardiness zone from the annual extreme minimum (plan/04
/// § Climate profile step 4): `z = min + 60`; below 0 is `1a`; otherwise
/// the number is `floor(z / 10) + 1` clamped to 1–13 and the half is `a`
/// when `z mod 10 < 5`, else `b`.
String computeZone(double annualExtremeMinF) {
  final z = annualExtremeMinF + 60;
  if (z < 0) return '1a';
  final number = ((z / 10).floor() + 1).clamp(1, 13);
  final letter = z % 10 < 5 ? 'a' : 'b';
  return '$number$letter';
}
