import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/recommendations/domain/compat_level.dart';
import 'package:geaux_farm/features/recommendations/domain/compatibility.dart';

void main() {
  final cases = {
    100: CompatLevel.great,
    80: CompatLevel.great,
    79: CompatLevel.good,
    60: CompatLevel.good,
    59: CompatLevel.possible,
    40: CompatLevel.possible,
    39: CompatLevel.indoor,
    0: CompatLevel.indoor,
  };
  cases.forEach((score, level) {
    test('$score → ${level.name}', () {
      expect(compatLevelFor(score), level);
    });
  });
}
