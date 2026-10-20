import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/domain/auth_user.dart';

import 'fake_auth_repository.dart';

void main() {
  test('authStateProvider emits null, the user after verify, null after '
      'sign-out', () async {
    final repo = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final seen = <AuthUser?>[];
    container.listen(
      authStateProvider,
      (_, next) => seen.add(next.value),
      fireImmediately: false,
    );

    await container.read(authStateProvider.future);
    await repo.verifyEmailCode('isaac@example.com', '123456');
    await Future<void>.delayed(Duration.zero);
    await repo.signOut();
    await Future<void>.delayed(Duration.zero);

    expect(seen, [
      null,
      const AuthUser(id: 'u1', email: 'isaac@example.com'),
      null,
    ]);
  });

  test(
    'UnconfiguredAuthRepository is signed out and fails as offline',
    () async {
      const repo = UnconfiguredAuthRepository();
      expect(await repo.authChanges().first, isNull);
      expect(repo.currentUser, isNull);
      await expectLater(repo.sendEmailCode('a@b.co'), throwsA(anything));
    },
  );
}
