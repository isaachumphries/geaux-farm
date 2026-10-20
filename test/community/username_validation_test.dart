import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/domain/username.dart';

void main() {
  group('isValidUsername (plan/07 § Auth: ^[a-z0-9_]{3,20}\$)', () {
    const cases = <String, bool>{
      'ab': false, // too short
      'abc': true,
      'abcdefghijklmnopqrst': true, // 20 chars
      'abcdefghijklmnopqrstu': false, // 21 chars
      'ABC': false, // uppercase
      'has space': false,
      'good_name1': true,
      '': false,
      'a-b': false,
      'abc\n': false, // `\$` must not let a trailing newline through
    };
    cases.forEach((input, valid) {
      test('${input.isEmpty ? '(empty)' : input.replaceAll('\n', r'\n')} '
          '-> ${valid ? 'valid' : 'invalid'}', () {
        expect(isValidUsername(input), valid);
      });
    });

    test('length constants match the regex', () {
      expect(usernameMinLength, 3);
      expect(usernameMaxLength, 20);
      expect(isValidUsername('a' * usernameMinLength), isTrue);
      expect(isValidUsername('a' * (usernameMinLength - 1)), isFalse);
      expect(isValidUsername('a' * usernameMaxLength), isTrue);
      expect(isValidUsername('a' * (usernameMaxLength + 1)), isFalse);
    });
  });
}
