import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../care/domain/care_event.dart';
import '../../catalog/domain/plant.dart';
import '../../catalog/presentation/plant_art.dart';
import '../../home/domain/home_copy.dart';
import '../../recommendations/application/clock_provider.dart';
import '../application/garden_provider.dart';
import '../data/garden_repository.dart';
import '../domain/growth.dart';
import '../domain/planting.dart';
import '../domain/planting_copy.dart';
import 'grow_this_sheet.dart';
import 'widgets/planting_card.dart';

/// GD-02 Planting detail. The header, quick actions, care guide, and
/// stage note follow the plant's category and maturity kind, so a herb,
/// a tomato, and a lavender each get their own screen.
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

/// Quick actions offered for a plant: water and skip when it has a water
/// need, one button per catalog task kind, harvest for plants grown for a
/// harvest, and a note. Order follows the GD-02 frame.
List<CareEventType> quickActionsFor(Plant p) {
  final kinds = {for (final t in p.care.tasks) t.type};
  return [
    if (p.water != null) ...[CareEventType.water, CareEventType.skipWater],
    if (kinds.contains(TaskType.fertilize)) CareEventType.fertilize,
    if (kinds.contains(TaskType.prune)) CareEventType.prune,
    if (p.maturityKind == MaturityKind.harvest) CareEventType.harvest,
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

String _taskTitle(CareDue t, String nickname) => switch (t.type) {
  CareEventType.water || CareEventType.skipWater => 'Water $nickname',
  CareEventType.fertilize => 'Fertilize $nickname',
  CareEventType.prune => 'Prune $nickname',
  CareEventType.harvest => 'Harvest $nickname',
  CareEventType.note => t.note ?? 'Check on $nickname',
};

class _Detail extends ConsumerWidget {
  const _Detail({required this.view});

  final PlantingView view;

  Future<void> _log(
    BuildContext context,
    WidgetRef ref,
    CareEventType type, {
    String? note,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(gardenRepositoryProvider)
          .logCare(view.id, type, note: note);
      messenger.showSnackBar(
        SnackBar(content: Text('Logged: ${_doneLabel(type)}')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't save that. Try again.")),
      );
    }
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => const _NoteDialog(),
    );
    if (note == null || note.trim().isEmpty || !context.mounted) return;
    await _log(context, ref, CareEventType.note, note: note);
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    PlantingStatus status,
  ) async {
    await ref.read(gardenRepositoryProvider).setStatus(view.id, status);
    if (context.mounted) context.go('/garden');
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
    if (ok == true && context.mounted) {
      await _setStatus(context, ref, PlantingStatus.removed);
    }
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
        if (view.growth case final stage? when active) ...[
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: inset,
            child: _StageNote(
              category: p.category,
              text: stageNote(p, stage.stage),
            ),
          ),
        ],
        if (active) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: inset,
            child: _QuickActions(
              actions: quickActionsFor(p),
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
              child: _TaskRow(
                task: t,
                nickname: pl.nickname,
                onDone: () => _log(
                  context,
                  ref,
                  t.type,
                  note: t.type == CareEventType.note ? t.note : null,
                ),
              ),
            ),
        ],
        if (p.care.tasks.isNotEmpty || p.tips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: inset,
            child: _Heading('Caring for your ${categoryNoun(p.category)}'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: inset,
            child: _CareGuide(plant: p),
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
              onPressed: () =>
                  _setStatus(context, ref, PlantingStatus.harvested),
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
    final water = ref.watch(nextWaterProvider(view.id));
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
                      WaterChip(label: nextWaterLabel(water.due, today)),
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

class _StageNote extends StatelessWidget {
  const _StageNote({required this.category, required this.text});

  final PlantCategory category;
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = plantArtStyle(category);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Symbols.tips_and_updates_rounded,
              size: AppIconSize.lg,
              color: style.ink,
              fill: 1,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: AppText.bodySm.copyWith(color: AppColors.soil900),
              ),
            ),
          ],
        ),
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

class _TaskRow extends ConsumerWidget {
  const _TaskRow({
    required this.task,
    required this.nickname,
    required this.onDone,
  });

  final CareDue task;
  final String nickname;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final overdue = task.due.isBefore(today);
    final s = _actionStyle(task.type);
    return GeauxCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: s.tint,
              borderRadius: BorderRadius.circular(AppRadii.chip + 4),
            ),
            child: Icon(s.icon, size: AppIconSize.lg, color: s.ink, fill: 1),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _taskTitle(task, nickname),
                  style: AppText.body.copyWith(
                    color: AppColors.soil900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  dueLabel(task.due, today),
                  style: AppText.bodySm.copyWith(
                    color: overdue ? AppColors.heat : AppColors.soil600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mark done',
            onPressed: onDone,
            icon: const Icon(
              Symbols.check_circle_rounded,
              size: 32,
              color: AppColors.stone200,
            ),
          ),
        ],
      ),
    );
  }
}

class _CareGuide extends StatelessWidget {
  const _CareGuide({required this.plant});

  final Plant plant;

  static ({IconData icon, String title}) _taskStyle(TaskType t) => switch (t) {
    TaskType.fertilize => (icon: Symbols.compost_rounded, title: 'Feed'),
    TaskType.prune => (icon: Symbols.content_cut_rounded, title: 'Prune'),
    TaskType.harvest => (
      icon: Symbols.shopping_basket_rounded,
      title: 'Harvest',
    ),
    TaskType.other => (icon: Symbols.checklist_rounded, title: 'Check'),
  };

  @override
  Widget build(BuildContext context) {
    final water = plant.water;
    return GeauxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (water != null)
            _GuideLine(
              icon: Symbols.water_drop_rounded,
              color: AppColors.frost,
              title: 'Water',
              detail:
                  '${everyLabel(water.everyDaysOutdoor)} outdoors, '
                  '${everyLabel(water.everyDaysIndoor).toLowerCase()} '
                  'indoors',
            ),
          for (final t in plant.care.tasks)
            _GuideLine(
              icon: _taskStyle(t.type).icon,
              color: AppColors.leaf700,
              title: '${_taskStyle(t.type).title} · ${everyLabel(t.everyDays)}',
              detail: t.note,
            ),
          for (final tip in plant.tips)
            _GuideLine(
              icon: Symbols.lightbulb_rounded,
              color: AppColors.goldLedge,
              title: 'Tip',
              detail: tip,
            ),
        ],
      ),
    );
  }
}

class _GuideLine extends StatelessWidget {
  const _GuideLine({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSize.md, color: color, fill: 1),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.bodySm.copyWith(
                    color: AppColors.soil900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  detail,
                  style: AppText.bodySm.copyWith(color: AppColors.soil600),
                ),
              ],
            ),
          ),
        ],
      ),
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
          when: careLogDate(planted, today),
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
