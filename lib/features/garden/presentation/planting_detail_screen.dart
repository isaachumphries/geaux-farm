import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../care/domain/care_event.dart';
import '../../care/domain/care_schedule.dart';
import '../../care/domain/schedule_math.dart';
import '../../care/domain/slot.dart';
import '../../care/presentation/care_screen.dart';
import '../../care/presentation/widgets/task_row.dart';
import '../../catalog/domain/plant.dart';
import '../../catalog/presentation/plant_art.dart';
import '../../home/domain/home_copy.dart';
import '../../recommendations/application/clock_provider.dart';
import '../application/garden_provider.dart';
import '../application/planting_actions.dart';
import '../domain/growth.dart';
import '../domain/planting.dart';
import '../domain/planting_copy.dart';
import 'grow_this_sheet.dart';
import 'widgets/planting_card.dart';

/// GD-02 Planting detail (#30), top to bottom: header with stage and ring,
/// next-water chip, action row, upcoming tasks, care log, Mark harvested,
/// Remove. Stage, due dates, and slots come from the shared care rules
/// (CARE-01, CARE-02), so they match CR-01.
class PlantingDetailScreen extends ConsumerWidget {
  const PlantingDetailScreen({super.key, required this.plantingId});

  final String plantingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(plantingViewProvider(plantingId));
    final view = async.value;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        // Keeps showing the last value while a write reloads the garden.
        child: view != null
            ? _Detail(view: view)
            : async.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.leaf500),
              )
            : _Missing(onBack: () => _back(context)),
      ),
    );
  }
}

void _back(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/garden');
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GeauxTopBar(
            title: 'Planting',
            leading: GeauxCircleButton(
              icon: Symbols.arrow_back_rounded,
              tooltip: 'Back',
              onPressed: onBack,
            ),
          ),
          const Spacer(),
          Text(
            "This plant isn't in your garden anymore.",
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: AppColors.soil600),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// The GD-02 action row: water and skip when the plant has a water need,
/// one button per catalog task kind, harvest only once [progress] reaches 1
/// (#30), and a note. Order follows the GD-02 frame.
List<CareEventType> quickActionsFor(Plant p, {required double progress}) {
  final kinds = {for (final t in p.care.tasks) t.type};
  final harvests =
      p.maturityKind == MaturityKind.harvest ||
      kinds.contains(TaskType.harvest);
  return [
    if (p.water != null) ...[CareEventType.water, CareEventType.skipWater],
    if (kinds.contains(TaskType.fertilize)) CareEventType.fertilize,
    if (kinds.contains(TaskType.prune)) CareEventType.prune,
    if (harvests && progress >= 1) CareEventType.harvest,
    CareEventType.note,
  ];
}

({String label, IconData icon, Color tint, Color ink}) _actionStyle(
  CareEventType t,
) => switch (t) {
  CareEventType.water => (
    label: 'Water',
    icon: Symbols.water_drop_rounded,
    tint: AppColors.tileSky,
    ink: AppColors.frost,
  ),
  CareEventType.skipWater => (
    label: 'Skip',
    icon: Symbols.block_rounded,
    tint: AppColors.stone200,
    ink: AppColors.soil600,
  ),
  CareEventType.fertilize => (
    label: 'Fertilize',
    icon: Symbols.compost_rounded,
    tint: AppColors.gold100,
    ink: AppColors.goldLedge,
  ),
  CareEventType.prune => (
    label: 'Prune',
    icon: Symbols.content_cut_rounded,
    tint: AppColors.leaf100,
    ink: AppColors.leaf700,
  ),
  CareEventType.harvest => (
    label: 'Harvest',
    icon: Symbols.shopping_basket_rounded,
    tint: AppColors.tilePeach,
    ink: AppColors.heat,
  ),
  CareEventType.note => (
    label: 'Add note',
    icon: Symbols.edit_note_rounded,
    tint: AppColors.tileSoil,
    ink: AppColors.tileSoilLedge,
  ),
};

class _Detail extends ConsumerWidget {
  const _Detail({required this.view});

  final PlantingView view;

  /// Runs [write], then confirms it with [done] or reports a failure. The
  /// screen stays put; the chip, ring, stage, and log follow the write.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() write,
    String done,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await write();
      messenger.showSnackBar(SnackBar(content: Text('Logged: $done')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't save that. Try again.")),
      );
    }
  }

  Future<void> _log(
    BuildContext context,
    WidgetRef ref,
    CareEventType type, {
    String? note,
  }) {
    final actions = ref.read(plantingActionsProvider);
    return _run(
      context,
      () => switch (type) {
        CareEventType.water => actions.water(view.id),
        CareEventType.skipWater => actions.skip(view.id),
        _ => actions.logTask(view.id, type, note: note),
      },
      _doneLabel(type),
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => const _NoteDialog(),
    );
    if (note == null || note.trim().isEmpty || !context.mounted) return;
    await _run(
      context,
      () => ref.read(plantingActionsProvider).addNote(view.id, note),
      _doneLabel(CareEventType.note),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${view.planting.nickname}?'),
        content: const Text('It leaves your garden and its reminders stop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(plantingActionsProvider).remove(view.id);
    if (context.mounted) context.go('/garden');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = view.plant;
    final pl = view.planting;
    final active = pl.status == PlantingStatus.active;
    final tasks = ref.watch(plantingTasksProvider(view.id));
    final events = ref.watch(plantingEventsProvider(view.id));
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding);

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
      children: [
        Padding(
          padding: inset,
          child: GeauxTopBar(
            title: pl.nickname,
            leading: GeauxCircleButton(
              icon: Symbols.arrow_back_rounded,
              tooltip: 'Back',
              onPressed: () => _back(context),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: inset,
          child: _Header(view: view),
        ),
        if (active) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: inset,
            child: _QuickActions(
              actions: quickActionsFor(p, progress: view.growth?.progress ?? 0),
              onAction: (t) => t == CareEventType.note
                  ? _addNote(context, ref)
                  : _log(context, ref, t),
            ),
          ),
        ],
        if (active && tasks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const Padding(padding: inset, child: _Heading('Upcoming')),
          const SizedBox(height: AppSpacing.sm),
          for (final t in tasks)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child: _UpcomingTask(
                task: t,
                onDone: () => _log(
                  context,
                  ref,
                  _eventTypeOf(t.kind),
                  note: t.kind == CareTaskKind.other ? t.note : null,
                ),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: inset,
          child: Row(
            children: [
              const Expanded(child: _Heading('Care log')),
              if (active)
                GeauxButton(
                  label: 'Add note',
                  variant: GeauxButtonVariant.text,
                  onPressed: () => _addNote(context, ref),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: inset,
          child: _CareLog(view: view, events: events),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (active && p.maturityKind == MaturityKind.harvest) ...[
          Padding(
            padding: inset,
            child: GeauxButton(
              label: 'Mark harvested',
              variant: GeauxButtonVariant.secondary,
              onPressed: () => _run(
                context,
                () => ref.read(plantingActionsProvider).markHarvested(view.id),
                _doneLabel(CareEventType.harvest),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Center(
          child: GeauxButton(
            label: 'Remove',
            variant: GeauxButtonVariant.text,
            onPressed: () => _confirmRemove(context, ref),
          ),
        ),
      ],
    );
  }
}

CareEventType _eventTypeOf(CareTaskKind kind) => switch (kind) {
  CareTaskKind.water => CareEventType.water,
  CareTaskKind.fertilize => CareEventType.fertilize,
  CareTaskKind.prune => CareEventType.prune,
  CareTaskKind.harvest => CareEventType.harvest,
  CareTaskKind.other => CareEventType.note,
};

String _doneLabel(CareEventType t) => switch (t) {
  CareEventType.water => 'watered',
  CareEventType.skipWater => 'skipped watering',
  CareEventType.fertilize => 'fertilized',
  CareEventType.prune => 'pruned',
  CareEventType.harvest => 'harvested',
  CareEventType.note => 'note added',
};

class _Header extends ConsumerWidget {
  const _Header({required this.view});

  final PlantingView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final water = ref.watch(nextWaterProvider(view.id)).value;
    final p = view.plant;
    final pl = view.planting;
    final stage = view.growth;
    final planted = pl.plantedOn;
    final start = startFor(p, pl);
    final maturity = maturityLine(p, pl);
    final style = plantArtStyle(p.category);
    final where = [
      whereLabel(view.space?.type, pl.setup),
      if (start != null) startMethodLabel(start.method),
    ].join(' · ');
    final active = pl.status == PlantingStatus.active;

    return GeauxCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A band in the plant's own color sets each screen apart.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.card - AppBorders.width),
            ),
            child: ColoredBox(
              color: style.tint,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    PlantTile(category: p.category),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pl.nickname,
                            style: AppText.h2.copyWith(
                              color: AppColors.soil900,
                            ),
                          ),
                          if (pl.nickname != p.commonName)
                            Text(
                              p.commonName,
                              style: AppText.bodySm.copyWith(
                                color: AppColors.soil900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          Text(
                            where,
                            style: AppText.bodySm.copyWith(
                              color: AppColors.soil600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (stage != null && stage.showsProgressRing && active)
                      GrowthRing(progress: stage.progress),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (pl.status == PlantingStatus.harvested)
                      Text(
                        'Harvested',
                        style: AppText.label.copyWith(color: AppColors.soil600),
                      )
                    else if (stage != null && planted != null)
                      StageText(
                        stage: stage.stage,
                        text: stageLine(stage.stage, planted, today),
                      ),
                    if (water != null && active)
                      WaterChip(
                        label: nextWaterLabel(
                          water.slot.start,
                          water.slot.outsideFreeTimes
                              ? outsideFreeTimesCopy
                              : formatClock(context, water.slot.start),
                        ),
                      ),
                  ],
                ),
                if (maturity != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    maturity,
                    style: AppText.bodySm.copyWith(color: AppColors.soil900),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.actions, required this.onAction});

  final List<CareEventType> actions;
  final ValueChanged<CareEventType> onAction;

  @override
  Widget build(BuildContext context) {
    // Four to a row, as in the GD-02 frame; more wrap underneath.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 3 * AppSpacing.md) / 4;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final a in actions)
              _ActionTile(type: a, width: width, onTap: () => onAction(a)),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.type,
    required this.width,
    required this.onTap,
  });

  final CareEventType type;
  final double width;
  final VoidCallback onTap;

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    final s = _actionStyle(type);
    return Semantics(
      button: true,
      label: s.label,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            SizedBox.square(
              dimension: _size,
              child: GeauxCard(
                onTap: onTap,
                padding: EdgeInsets.zero,
                color: s.tint,
                borderColor: null,
                ledgeColor: s.ink,
                child: Center(
                  child: Icon(
                    s.icon,
                    size: AppIconSize.xl + 4,
                    color: s.ink,
                    fill: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              s.label,
              textAlign: TextAlign.center,
              style: AppText.label.copyWith(color: AppColors.soil900),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: AppText.h2.copyWith(color: AppColors.soil900)),
    );
  }
}

/// One upcoming task from the care list: its slot as a CR-01 header
/// ("Thu, Oct 8 · 8:00 AM", "Overdue", or outside free times) over the
/// shared [TaskRow].
class _UpcomingTask extends ConsumerWidget {
  const _UpcomingTask({required this.task, required this.onDone});

  final ScheduledCareTask task;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final slot = task.slot;
    final day = DateFormat('EEE, MMM d', 'en_US').format(slot.start);
    final when = slot.outsideFreeTimes
        ? '$day · $outsideFreeTimesCopy'
        : '$day · ${formatClock(context, slot.start)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CareGroupHeader(
          icon: task.overdue ? Symbols.error_rounded : Symbols.schedule_rounded,
          label: task.overdue ? 'Overdue · $when' : when,
          color: task.overdue ? AppColors.heat : AppColors.soil600,
          fill: task.overdue ? 1 : 0,
        ),
        TaskRow(
          type: taskRowTypeOf(task.kind),
          state: task.overdue
              ? TaskRowState.overdue
              : task.rainSkip
              ? TaskRowState.rainSkip
              : TaskRowState.due,
          plantName: task.nickname,
          note: task.note,
          overdueDays: daysBetween(task.due, today),
          onDone: onDone,
        ),
      ],
    );
  }
}

class _CareLog extends ConsumerWidget {
  const _CareLog({required this.view, required this.events});

  final PlantingView view;
  final List<CareEvent> events;

  static IconData _icon(CareEventType t) => _actionStyle(t).icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final planted = view.planting.plantedOn;
    final space = view.space;
    final rows = <({IconData icon, String text, String when})>[
      for (final e in events)
        (
          icon: _icon(e.type),
          text: careEventLabel(e),
          when: careLogDate(e.at, today),
        ),
      if (planted != null)
        (
          icon: Symbols.potted_plant_rounded,
          text: space == null
              ? 'Planted'
              : 'Planted on the ${spaceNoun(space.type)}',
          when: plantedLogDate(planted, today),
        ),
    ];
    return GeauxCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.stone200),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    r.icon,
                    size: AppIconSize.md,
                    color: AppColors.leaf700,
                    fill: 1,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.text,
                          style: AppText.bodySm.copyWith(
                            color: AppColors.soil900,
                          ),
                        ),
                        Text(
                          r.when,
                          style: AppText.caption.copyWith(
                            color: AppColors.soil600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Nothing logged yet.',
                style: AppText.bodySm.copyWith(color: AppColors.soil600),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog();

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a note'),
      content: GeauxTextField(
        controller: _text,
        hintText: 'e.g. New leaves coming in!',
        autofocus: true,
        maxLength: 140,
        textInputAction: TextInputAction.done,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_text.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
