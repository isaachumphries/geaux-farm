import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../recommendations/application/clock_provider.dart';
import '../domain/draft_to_profile.dart';
import '../domain/onboarding_draft.dart';
import 'attribution_repository.dart';
import 'profile_writer.dart';

/// OB-07 Finish (plan/02 § Persistence): one Drift transaction writes the
/// profile with `onboarding_completed_at` and the primary space, then the
/// OB-06 answer is sent fire-and-forget.
class OnboardingRepository {
  OnboardingRepository({
    required this.writer,
    required this.attribution,
    required this.now,
    Random? random,
  }) : _random = random ?? Random.secure();

  final ProfileWriter writer;
  final AttributionRepository attribution;
  final DateTime Function() now;
  final Random _random;

  /// Throws [StateError] when the draft is missing an answer. A failed
  /// transaction writes nothing and rethrows.
  Future<void> completeOnboarding(OnboardingDraft draft) async {
    final rows = profileFromDraft(draft, now: now(), spaceId: _uuidV4());
    if (rows == null) throw StateError('Onboarding draft is incomplete');
    await writer.save(rows.profile, rows.space);

    final source = rows.profile.heardFrom;
    if (source != null) {
      // Never awaited, never retried; a failure is ignored.
      unawaited(
        Future(() => attribution.submit(source, rows.profile.heardOtherText))
            .catchError((Object _) {}),
      );
    }
  }

  String _uuidV4() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final hex = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(
    writer: ref.watch(profileWriterProvider),
    attribution: ref.watch(attributionRepositoryProvider),
    now: ref.watch(clockProvider),
  ),
);
