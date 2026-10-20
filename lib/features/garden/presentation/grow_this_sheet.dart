import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../catalog/domain/plant.dart';
import '../../catalog/presentation/plant_art.dart';
import '../../onboarding/data/profile_providers.dart';
import '../../onboarding/domain/space.dart';
import '../../recommendations/application/clock_provider.dart';
import '../../recommendations/application/recommendations_provider.dart';
import '../../recommendations/domain/scored_plant.dart';
import '../../recommendations/presentation/widgets/compat_badge.dart';
import '../data/garden_repository.dart';
import '../domain/planting.dart';
import '../domain/planting_copy.dart';

/// Opens PD-02 for [plant]. When the user adds it, shows a confirmation
/// and opens the new planting in My Garden (GD-02).
Future<void> pickPlant(BuildContext context, ScoredPlant plant) async {
  final added = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cream50,
    builder: (_) => GrowThisSheet(plant: plant),
  );
  if (added == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${plant.plant.commonName} is in your garden!')),
  );
  context.go('/garden/planting/$added');
}

/// "Harvest in 50–65 days" for one way of starting [p]; the day range
/// comes from [start], the verb from the plant's maturity kind.
String startTimeLabel(Plant p, PlantStart start) {
  final days = '${start.daysMin}–${start.daysMax} days';
  return switch (p.maturityKind) {
    MaturityKind.harvest => 'Harvest in $days',
    MaturityKind.bloom => 'Blooms in $days',
    MaturityKind.establish => 'Settles in over $days',
    MaturityKind.foliage => 'Grows year-round',
  };
}

String startMethodLabel(StartMethod m) => switch (m) {
  StartMethod.seed => 'Seed',
  StartMethod.transplant => 'Transplant',
  StartMethod.cutting => 'Cutting',
};

/// "Today, Oct 7" for [today], otherwise "Oct 5".
String plantedDateLabel(DateTime date, DateTime today) {
  final md = DateFormat('MMM d', 'en_US').format(date);
  return DateUtils.isSameDay(date, today) ? 'Today, $md' : md;
}

/// PD-02 "Grow this" sheet: where the plant grows, container or not, how
/// it starts, when it was planted, and an optional nickname. Pops with the
/// new planting's id.
class GrowThisSheet extends ConsumerStatefulWidget {
  const GrowThisSheet({super.key, required this.plant});

  final ScoredPlant plant;

  @override
  ConsumerState<GrowThisSheet> createState() => _GrowThisSheetState();
}

class _GrowThisSheetState extends ConsumerState<GrowThisSheet> {
  final _nickname = TextEditingController();
  GrowSetup? _setup;
  bool? _inContainer;
  StartMethod? _start;
  DateTime? _plantedOn;
  bool _saving = false;

  Plant get _plant => widget.plant.plant;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime current, DateTime today) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      // Stage and care count from this date, so it can't be in the future.
      lastDate: today,
    );
    if (picked != null && mounted) setState(() => _plantedOn = picked);
  }

  Future<void> _add({
    required String spaceId,
    required GrowSetup setup,
    required bool inContainer,
    required StartMethod start,
    required DateTime plantedOn,
  }) async {
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(gardenRepositoryProvider)
          .addPlanting(
            plant: _plant,
            spaceId: spaceId,
            nickname: _nickname.text,
            setup: setup,
            inContainer: inContainer,
            startMethod: start,
            plantedOn: plantedOn,
          );
      if (mounted) Navigator.of(context).pop(id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't add it. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final space = ref.watch(primarySpaceProvider).value;
    final today = ref.watch(todayProvider);
    final p = _plant;
    final starts = p.starts ?? const <PlantStart>[];
    final containerOk = p.space?.containerOk ?? true;

    final setup = _setup ?? defaultGrowSetup(space?.type ?? SpaceType.balcony);
    final inContainer =
        containerOk && (_inContainer ?? space?.inContainerDefault ?? false);
    final start = _start ?? (starts.isEmpty ? null : starts.first.method);
    final plantedOn = _plantedOn ?? today;

    final VoidCallback? onAdd = _saving || space == null || start == null
        ? null
        : () => _add(
            spaceId: space.id,
            setup: setup,
            inContainer: inContainer,
            start: start,
            plantedOn: plantedOn,
          );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(child: _Grabber()),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                PlantTile(category: p.category, size: 48),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grow ${p.commonName}',
                        style: AppText.h2.copyWith(color: AppColors.soil900),
                      ),
                      Text(
                        'Set it up so we can plan its care.',
                        style: AppText.bodySm.copyWith(
                          color: AppColors.soil600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Where will it grow?',
                    style: AppText.body.copyWith(
                      color: AppColors.soil900,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                CompatBadge(score: widget.plant.compatibility.score),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GeauxSegmentedChoice<GrowSetup>(
              options: [
                for (final s in GrowSetup.values) (s, growSetupLabel(s)),
              ],
              selected: setup,
              onSelected: (s) => setState(() => _setup = s),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ContainerCard(
              containerOk: containerOk,
              minGallons: p.space?.minContainerGal,
              value: inContainer,
              onChanged: (v) => setState(() => _inContainer = v),
            ),
            if (starts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'How are you starting it?',
                style: AppText.body.copyWith(
                  color: AppColors.soil900,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, s) in starts.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StartChoice(
                        title: startMethodLabel(s.method),
                        subtitle: startTimeLabel(p, s),
                        selected: s.method == start,
                        onTap: () => setState(() => _start = s.method),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Labeled(
                    label: 'Planted',
                    child: _DateField(
                      text: plantedDateLabel(plantedOn, today),
                      onTap: () => _pickDate(plantedOn, today),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Labeled(
                    label: 'Nickname',
                    child: GeauxTextField(
                      controller: _nickname,
                      hintText: 'e.g. Big ${p.commonName}',
                      prefixIcon: Symbols.edit_rounded,
                      maxLength: 30,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            GeauxButton(label: 'Add to my garden', onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.stone200,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    );
  }
}

class _ContainerCard extends StatelessWidget {
  const _ContainerCard({
    required this.containerOk,
    required this.minGallons,
    required this.value,
    required this.onChanged,
  });

  final bool containerOk;
  final double? minGallons;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final gal = minGallons;
    final subtitle = !containerOk
        ? 'Best grown in the ground'
        : gal == null
        ? 'Grows fine in a pot'
        : '${gal.round()}+ gallon pot recommended';
    return GeauxCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tileSoil,
              borderRadius: BorderRadius.circular(AppRadii.chip + 4),
            ),
            child: const Icon(
              Symbols.potted_plant_rounded,
              size: AppIconSize.lg,
              color: AppColors.tileSoilLedge,
              fill: 1,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In a container',
                  style: AppText.body.copyWith(
                    color: AppColors.soil900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppText.bodySm.copyWith(color: AppColors.soil600),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.leaf500,
            onChanged: containerOk ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _StartChoice extends StatelessWidget {
  const _StartChoice({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GeauxCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        color: selected ? AppColors.leaf100 : AppColors.white,
        borderColor: selected ? AppColors.leaf500 : AppColors.stone200,
        ledgeColor: selected ? AppColors.leaf500 : AppColors.stone200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppText.body.copyWith(
                color: selected ? AppColors.leaf700 : AppColors.soil900,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              style: AppText.caption.copyWith(color: AppColors.soil600),
            ),
          ],
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.overline.copyWith(color: AppColors.soil600),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        child,
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Planted date',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: AppColors.stone200,
              width: AppBorders.width,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Symbols.calendar_month_rounded,
                color: AppColors.soil600,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(color: AppColors.soil900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
