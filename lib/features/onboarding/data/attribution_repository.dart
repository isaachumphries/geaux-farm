import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_profile.dart';

/// Sends the anonymous OB-06 answer to `attribution_responses`
/// (plan/02 § Persistence): `source` and `other_text` only, no user id, no
/// retry. Errors are swallowed by the caller.
abstract interface class AttributionRepository {
  Future<void> submit(HeardFrom source, String? otherText);
}

/// Stand-in until the Supabase client lands (#47): sends nothing. The
/// Supabase implementation replaces it in `lib/features/onboarding/data/`
/// only through this provider.
class NoopAttributionRepository implements AttributionRepository {
  const NoopAttributionRepository();

  @override
  Future<void> submit(HeardFrom source, String? otherText) async {}
}

final attributionRepositoryProvider = Provider<AttributionRepository>(
  (ref) => const NoopAttributionRepository(),
);
