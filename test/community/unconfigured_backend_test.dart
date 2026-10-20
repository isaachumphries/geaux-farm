import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/http.dart';
import 'package:geaux_farm/features/community/application/community_feed_provider.dart';
import 'package:geaux_farm/features/community/application/starred_guides_provider.dart';
import 'package:geaux_farm/features/community/data/auth_providers.dart';
import 'package:geaux_farm/features/community/data/guide_repository_provider.dart';
import 'package:geaux_farm/features/community/domain/auth_user.dart';
import 'package:geaux_farm/features/community/domain/guide_feed_query.dart';

// Tests run without --dart-define-from-file=env.json, so Env.hasSupabase is
// false and the real (un-overridden) providers are the no-backend ones. The
// app must still run: community reads show Error + Retry and sign-in shows
// its offline error (09 § Offline behavior, § Errors).

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('without Supabase configured', () {
    test('the providers pick the unconfigured repositories', () {
      final c = _container();

      expect(c.read(authRepositoryProvider), isA<UnconfiguredAuthRepository>());
      expect(
        c.read(guideRepositoryProvider),
        isA<UnconfiguredGuideRepository>(),
      );
    });

    test(
      'authStateProvider settles on signed out, so sign-in can open',
      () async {
        final c = _container();
        c.listen(authStateProvider, (_, _) {});

        expect(await c.read(authStateProvider.future), isNull);
        expect(c.read(authStateProvider), const AsyncData<AuthUser?>(null));
      },
    );

    test('every auth network call fails as NetworkException; sign-out '
        'succeeds', () async {
      final repo = _container().read(authRepositoryProvider);
      final offline = throwsA(isA<NetworkException>());

      await expectLater(repo.sendEmailCode('isaac@example.com'), offline);
      await expectLater(
        repo.verifyEmailCode('isaac@example.com', '481926'),
        offline,
      );
      await expectLater(repo.usernameAvailable('isaac'), offline);
      await expectLater(repo.createProfile('isaac'), offline);
      await expectLater(repo.signOut(), completes);
      expect(repo.currentUser, isNull);
    });

    test('the feed is an error state from a NetworkException', () async {
      final c = _container();
      const query = GuideFeedQuery();
      c.listen(communityFeedProvider(query), (_, _) {});

      await expectLater(
        c.read(communityFeedProvider(query).future),
        throwsA(isA<NetworkException>()),
      );
      expect(
        c.read(communityFeedProvider(query)).error,
        isA<NetworkException>(),
      );
    });

    test('"Starred by me" is empty, as when signed out', () async {
      final c = _container();

      expect(await c.read(starredGuideIdsProvider.future), isEmpty);
    });
  });
}
