import 'package:geaux_farm/features/climate/data/climate_provider.dart';
import 'package:geaux_farm/features/climate/domain/climate_profile.dart';

import '../recommendations/fixtures/baton_rouge.dart' as fx;

/// A climate provider that skips the archive build and the cache and
/// returns [profile] (the plan/04 Baton Rouge profile by default).
class FixedClimate extends ClimateNotifier {
  FixedClimate([this.profile]);

  final ClimateProfile? profile;

  @override
  Future<ClimateProfile> build() async => profile ?? fx.batonRougeClimate;
}
