import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../recommendations/application/clock_provider.dart';
import '../application/care_schedule_provider.dart';
import '../data/drift_care_schedule_repository.dart';
import '../domain/care_event.dart';
import '../domain/care_schedule.dart';
import '../domain/schedule_math.dart';
import '../domain/slot.dart';
import 'widgets/day_selector.dart';
import 'widgets/task_row.dart';

/// Placeholder until the team confirms the copy (issue #34).
const careEmptyCopy = 'Nothing due today.';

/// Days the selector shows: today and the next six.
const careSelectorDays = 7;

/// CR-01: the daily care list. [date] is the `date` query of `/care`; a
/// missing value or one outside today…today+6 selects today.
class CareScreen extends ConsumerStatefulWidget {
  const CareScreen({super.key, this.date});

  final DateTime? date;

  @override
  ConsumerState<CareScreen> createState() => _CareScreenState();
}

/// A task marked done on this screen, kept so its row stays in place after
/// the recomputed schedule drops it.
class _Done {
  const _Done(this.task, this.at);

  final ScheduledCareTask task;
  final DateTime at;
}

class _CareScreenState extends ConsumerState<CareScreen> {
  /// The day tapped in the selector; null follows [CareScreen.date].
  DateTime? _picked;
  final _done = <String, _Done>{};
  final _saving = <String>{};

  @override
  void didUpdateWidget(CareScreen old) {
    super.didUpdateWidget(old);
    // A new `date` (e.g. from a reminder tap) wins over an earlier pick.
    if (old.date != widget.date) _picked = null;
  }

  DateTime _selected(DateTime today) {
    final wanted = _picked ?? widget.date;
    if (wanted == null) return today;
    final day = dayOf(wanted);
    final offset = daysBetween(today, day);
    return offset < 0 || offset >= careSelectorDays ? today : day;
  }

  Future<void> _markDone(ScheduledCareTask task) async {
    final key = _keyOf(task);
    if (!_saving.add(key)) return;
    final at = ref.read(clockProvider)();
    try {
      await ref
          .read(careScheduleRepositoryProvider)
          .logCareEvent(
            plantingId: task.plantingId,
            type: _eventTypeOf(task.kind),
            at: at,
            note: task.kind == CareTaskKind.other ? task.note : null,
          );
    } finally {
      _saving.remove(key);
    }
    if (mounted) setState(() => _done[key] = _Done(task, at));
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final selected = _selected(today);
    final days = [for (var i = 0; i < careSelectorDays; i++) addDays(today, i)];
    final schedule = ref.watch(careScheduleProvider);
    // Keep the last list while a recompute is in flight so rows don't flash.
    final tasks = schedule.value;
    final entries = tasks == null ? null : _entries(tasks);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child: Text(
                'Care',
                style: AppText.h1.copyWith(color: AppColors.soil900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: CareDaySelector(
                days: days,
                selected: selected,
                hasTasks: (d) =>
                    entries != null &&
                    _tasksOn(entries, d, d == today).isNotEmpty,
                onSelect: (d) => setState(() => _picked = d),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: switch (schedule) {
                _ when entries != null => _List(
                  entries: entries,
                  selected: selected,
                  today: today,
                  onDone: _markDone,
                ),
                AsyncError() => const GeauxEmptyState(
                  message: "Couldn't load your care schedule.",
                  icon: Symbols.error_rounded,
                ),
                _ => const Center(
                  child: CircularProgressIndicator(color: AppColors.leaf500),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  /// The schedule plus tasks finished here that the schedule no longer has.
  List<_Entry> _entries(List<ScheduledCareTask> tasks) {
    final keys = {for (final t in tasks) _keyOf(t)};
    return [
      for (final t in tasks) _Entry(t, _done[_keyOf(t)]?.at),
      for (final d in _done.values)
        if (!keys.contains(_keyOf(d.task))) _Entry(d.task, d.at),
    ];
  }
}

class _Entry {
  const _Entry(this.task, this.doneAt);

  final ScheduledCareTask task;
  final DateTime? doneAt;
}

String _keyOf(ScheduledCareTask t) =>
    '${t.plantingId}|${t.kind.name}|${t.note}|${t.due.toIso8601String()}';

CareEventType _eventTypeOf(CareTaskKind kind) => switch (kind) {
  CareTaskKind.water => CareEventType.water,
  CareTaskKind.fertilize => CareEventType.fertilize,
  CareTaskKind.prune => CareEventType.prune,
  CareTaskKind.harvest => CareEventType.harvest,
  CareTaskKind.other => CareEventType.note,
};

TaskRowType _rowTypeOf(CareTaskKind kind) => switch (kind) {
  CareTaskKind.water => TaskRowType.water,
  CareTaskKind.fertilize => TaskRowType.fertilize,
  CareTaskKind.prune => TaskRowType.prune,
  CareTaskKind.harvest => TaskRowType.harvest,
  CareTaskKind.other => TaskRowType.other,
};

/// Entries on [day]'s list: on today, the overdue ones plus those whose
/// slot is today; otherwise those whose slot is on [day].
List<_Entry> _tasksOn(List<_Entry> entries, DateTime day, bool isToday) => [
  for (final e in entries)
    if (e.task.overdue ? isToday : dayOf(e.task.slot.start) == day) e,
];

class _List extends ConsumerWidget {
  const _List({
    required this.entries,
    required this.selected,
    required this.today,
    required this.onDone,
  });

  final List<_Entry> entries;
  final DateTime selected;
  final DateTime today;
  final void Function(ScheduledCareTask task) onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onDay = _tasksOn(entries, selected, selected == today);
    if (onDay.isEmpty) return const GeauxEmptyState(message: careEmptyCopy);

    final overdue = [
      for (final e in onDay)
        if (e.task.overdue) e,
    ];
    final timed = <DateTime, List<_Entry>>{};
    final outside = <_Entry>[];
    for (final e in onDay) {
      if (e.task.overdue) continue;
      if (e.task.slot.outsideFreeTimes) {
        outside.add(e);
      } else {
        (timed[e.task.slot.start] ??= []).add(e);
      }
    }
    final starts = timed.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      children: [
        if (overdue.isNotEmpty)
          _Group(
            header: const _GroupHeader(
              icon: Symbols.error_rounded,
              label: 'Overdue',
              color: AppColors.soil900,
              fill: 1,
            ),
            entries: overdue,
            today: today,
            onDone: onDone,
          ),
        for (final start in starts)
          _Group(
            header: _GroupHeader(
              icon: Symbols.schedule_rounded,
              label: formatClock(context, start),
            ),
            entries: timed[start]!,
            today: today,
            onDone: onDone,
          ),
        if (outside.isNotEmpty)
          _Group(
            header: const _GroupHeader(
              icon: Symbols.schedule_rounded,
              label: outsideFreeTimesCopy,
            ),
            entries: outside,
            today: today,
            onDone: onDone,
          ),
      ],
    );
  }
}

/// [t] in the device's short time format, e.g. `10:00 AM`.
String formatClock(BuildContext context, DateTime t) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(t),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.icon,
    required this.label,
    this.color = AppColors.soil600,
    this.fill = 0,
  });

  final IconData icon;
  final String label;
  final Color color;

  /// Material Symbols fill axis: 1 for the solid Overdue mark.
  final double fill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.md, color: color, fill: fill),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: AppText.overline.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.header,
    required this.entries,
    required this.today,
    required this.onDone,
  });

  final Widget header;
  final List<_Entry> entries;
  final DateTime today;
  final void Function(ScheduledCareTask task) onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TaskRow(
                key: ValueKey(_keyOf(e.task)),
                type: _rowTypeOf(e.task.kind),
                state: _stateOf(e),
                plantName: e.task.nickname,
                note: e.task.note,
                overdueDays: daysBetween(e.task.due, today),
                doneAt: e.doneAt == null
                    ? null
                    : formatClock(context, e.doneAt!),
                onDone: () => onDone(e.task),
              ),
            ),
        ],
      ),
    );
  }

  TaskRowState _stateOf(_Entry e) {
    if (e.doneAt != null) return TaskRowState.done;
    if (e.task.overdue) return TaskRowState.overdue;
    if (e.task.rainSkip) return TaskRowState.rainSkip;
    return TaskRowState.due;
  }
}
