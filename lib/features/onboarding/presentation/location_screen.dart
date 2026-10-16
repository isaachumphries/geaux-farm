import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../data/device_locator.dart';
import '../data/open_meteo_geocoding_repository.dart';
import '../domain/geocoding_repository.dart';
import 'onboarding_draft_provider.dart';
import 'onboarding_routes.dart';
import 'onboarding_scaffold.dart';

/// Wait after the last keystroke before searching (plan/02 § OB-02).
const locationSearchDebounce = Duration(milliseconds: 300);

/// Shortest query that starts a search.
const locationMinQuery = 2;

/// OB-02 Location: city or ZIP search, or the device's location.
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  final _query = TextEditingController();
  Timer? _debounce;

  /// Bumped on every new search so a slow, older answer is dropped.
  int _searchId = 0;
  List<GeoPlace>? _results;
  bool _searching = false;
  bool _failed = false;
  bool _locating = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < locationMinQuery) {
      _searchId++;
      setState(() {
        _results = null;
        _searching = false;
        _failed = false;
      });
      return;
    }
    _debounce = Timer(locationSearchDebounce, () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    final id = ++_searchId;
    setState(() {
      _searching = true;
      _failed = false;
    });
    try {
      final results = await ref.read(geocodingRepositoryProvider).search(query);
      if (!mounted || id != _searchId) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } on Object {
      if (!mounted || id != _searchId) return;
      setState(() {
        _results = null;
        _searching = false;
        _failed = true;
      });
    }
  }

  void _select(GeoPlace place) {
    ref.read(onboardingDraftProvider.notifier).setLocation(place);
    context.push(OnboardingRoutes.climate);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final place = await ref.read(deviceLocatorProvider).locate();
      if (!mounted) return;
      setState(() => _locating = false);
      _select(place);
    } on LocationUnavailableException {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location is off — search for your city instead.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      route: OnboardingRoutes.location,
      step: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Where do you live?',
            style: AppText.h1.copyWith(color: AppColors.soil900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "We use your city's climate — rainfall, humidity, sunlight, UV "
            'and seasons — to pick plants that will thrive.',
            style: AppText.body.copyWith(color: AppColors.soil600),
          ),
          const SizedBox(height: AppSpacing.xl),
          GeauxTextField(
            controller: _query,
            hintText: 'Search city or ZIP',
            prefixIcon: Symbols.search_rounded,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          _GpsButton(
            loading: _locating,
            onPressed: _locating ? null : _useCurrentLocation,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_searching) {
      return const Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(color: AppColors.leaf500),
        ),
      );
    }
    if (_failed) {
      return Column(
        children: [
          Text(
            "Couldn't search right now.",
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: AppColors.soil600),
          ),
          GeauxButton(
            label: 'Retry',
            variant: GeauxButtonVariant.text,
            onPressed: () => _search(_query.text.trim()),
          ),
        ],
      );
    }
    final results = _results;
    if (results == null) return const SizedBox.shrink();
    if (results.isEmpty) {
      return Text(
        'No matches. Try a nearby city or ZIP.',
        textAlign: TextAlign.center,
        style: AppText.body.copyWith(color: AppColors.soil600),
      );
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => GeauxCard(
        onTap: () => _select(results[i]),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            const Icon(
              Symbols.location_on_rounded,
              color: AppColors.leaf700,
              fill: 1,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                results[i].label,
                style: AppText.body.copyWith(
                  color: AppColors.soil900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `Use my current location`: a secondary ledge button with a pin, or a
/// spinner while the fix is pending.
class _GpsButton extends StatelessWidget {
  const _GpsButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: GeauxCard(
        onTap: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox.square(
                  dimension: AppIconSize.md,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.leaf500,
                  ),
                )
              else
                const Icon(
                  Symbols.my_location_rounded,
                  size: AppIconSize.md,
                  color: AppColors.leaf700,
                ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'Use my current location'.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.button.copyWith(
                    color: loading ? AppColors.soil600 : AppColors.leaf700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
