import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/converters.dart';
import 'package:geaux_farm/features/onboarding/domain/availability.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';

// plan/09 § Drift schema: `user_profile.goals` is a JSON list and
// `availability` a JSON list of 7 ints. care_events.type is covered in
// app_database_test.dart.
void main() {
  group('GoalsConverter', () {
    const c = GoalsConverter();

    test('stores a JSON list of goal names, order kept', () {
      expect(c.toSql([Goal.other, Goal.food]), '["other","food"]');
      expect(c.fromSql('["other","food"]'), [Goal.other, Goal.food]);
    });

    test('round-trips every goal and the empty list', () {
      expect(c.fromSql(c.toSql(Goal.values)), Goal.values);
      expect(c.toSql(const []), '[]');
      expect(c.fromSql('[]'), isEmpty);
    });

    test('rejects a name that is not a Goal', () {
      expect(() => c.fromSql('["Food"]'), throwsArgumentError);
    });
  });

  group('AvailabilityConverter', () {
    const c = AvailabilityConverter();

    test('stores the 7 Mon..Sun bitmasks as a JSON list', () {
      const a = Availability([0, 1, 2, 4, 8, 128, 255]);
      expect(c.toSql(a), '[0,1,2,4,8,128,255]');
      expect(c.fromSql('[0,1,2,4,8,128,255]').days, a.days);
    });

    test('round-trips an empty week and an all-free week', () {
      for (final days in [List.filled(7, 0), List.filled(7, 255)]) {
        final back = c.fromSql(c.toSql(Availability(days)));
        expect(back.days, days);
      }
    });
  });
}
