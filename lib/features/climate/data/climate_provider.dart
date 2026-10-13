import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/climate_profile.dart';
import 'default_climate.dart';

/// The user's climate profile (plan/09 § State management). #26 replaces
/// [build] with the cached-profile read and rebuild rules and adds
/// `rebuild()`; until then it returns [batonRougeClimate].
class ClimateNotifier extends AsyncNotifier<ClimateProfile> {
  @override
  Future<ClimateProfile> build() async => batonRougeClimate;
}

final climateProvider = AsyncNotifierProvider<ClimateNotifier, ClimateProfile>(
  ClimateNotifier.new,
);
