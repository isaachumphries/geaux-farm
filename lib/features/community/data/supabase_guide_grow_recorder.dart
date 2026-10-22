import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env.dart';
import '../../../core/http.dart';
import '../domain/guide_grow_recorder.dart';

/// Postgres `unique_violation`: the `guide_grows` primary key.
const _uniqueViolation = '23505';

/// [GuideGrowRecorder] over the `guide_grows` table.
class SupabaseGuideGrowRecorder implements GuideGrowRecorder {
  /// [currentUserId] defaults to the signed-in Supabase user.
  SupabaseGuideGrowRecorder(this._client, {String? Function()? currentUserId})
    : _currentUserId = currentUserId ?? (() => _client.auth.currentUser?.id);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  @override
  Future<void> recordGrow(String guideId) async {
    final userId = _currentUserId() ?? (throw const AuthRequiredException());
    try {
      await _client
          .from('guide_grows')
          .insert({'user_id': userId, 'guide_id': guideId})
          .retry(enabled: false, requestTimeout: AppHttpClient.defaultTimeout);
    } on PostgrestException catch (e) {
      // Grown before, e.g. on another device: the count already has it.
      if (e.code != _uniqueViolation) rethrow;
    } on TimeoutException {
      throw const NetworkException('Request timed out');
    } on SocketException catch (e) {
      throw NetworkException('Socket error: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Client error: ${e.message}');
    }
  }
}

/// No backend: there is no account to count the grow against.
class UnconfiguredGuideGrowRecorder implements GuideGrowRecorder {
  const UnconfiguredGuideGrowRecorder();

  @override
  Future<void> recordGrow(String guideId) =>
      Future.error(const NetworkException('Supabase is not configured'));
}

/// The Supabase recorder, or [UnconfiguredGuideGrowRecorder] when the app
/// was started without `env.json` (see [Env.hasSupabase]).
final guideGrowRecorderProvider = Provider<GuideGrowRecorder>(
  (ref) => Env.hasSupabase
      ? SupabaseGuideGrowRecorder(Supabase.instance.client)
      : const UnconfiguredGuideGrowRecorder(),
);
