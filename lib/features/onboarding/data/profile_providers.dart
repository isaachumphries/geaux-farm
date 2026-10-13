import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/space.dart';
import '../domain/user_profile.dart';
import 'default_profile.dart';

/// The local user profile. Drift (#43) replaces the body with a stream of
/// the `user_profile` row; until then it yields [defaultUserProfile].
final userProfileProvider = StreamProvider<UserProfile>(
  (ref) => Stream.value(defaultUserProfile),
);

/// The primary growing space. Drift (#43) replaces the body with a stream of
/// the `spaces` row where `is_primary` is true; until then it yields
/// [defaultSpace].
final primarySpaceProvider = StreamProvider<Space>(
  (ref) => Stream.value(defaultSpace),
);
