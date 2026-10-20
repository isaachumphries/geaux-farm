import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../domain/rain_hint.dart';

/// What a care row asks the user to do. `other` is a catalog task with only
/// a note (plan/05 § Other care tasks).
enum TaskRowType { water, fertilize, prune, harvest, other }

enum TaskRowState { due, overdue, rainSkip, done }

/// One care task: type tile, title, a state line, and a check control.
///
/// A row that is not [TaskRowState.done] marks itself done on a swipe to the
/// right or a tap on the check, by calling [onDone]. The caller owns what
/// that means (logging the event) and rebuilds the row as `done`.
class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.type,
    required this.state,
    required this.plantName,
    this.note,
    this.overdueDays = 0,
    this.doneAt,
    this.onDone,
  });

  final TaskRowType type;
  final TaskRowState state;
  final String plantName;

  /// Catalog task note. Titles an `other` task; sits under the others.
  final String? note;

  /// Whole days past due, shown on an `overdue` row.
  final int overdueDays;

  /// Time label of a `done` row, already in the device's time format.
  final String? doneAt;
  final VoidCallback? onDone;

  bool get _done => state == TaskRowState.done;

  String get _title => switch (type) {
    TaskRowType.water => 'Water $plantName',
    TaskRowType.fertilize => 'Fertilize $plantName',
    TaskRowType.prune => 'Prune $plantName',
    TaskRowType.harvest => 'Harvest $plantName',
    TaskRowType.other => note ?? plantName,
  };

  @override
  Widget build(BuildContext context) {
    final overdue = state == TaskRowState.overdue;
    final card = GeauxCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: overdue ? AppColors.error : AppColors.stone200,
      ledgeColor: overdue ? AppColors.error : AppColors.stone200,
      child: Row(
        children: [
          _TypeTile(type: type),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _done ? AppColors.soil600 : AppColors.soil900,
                    decoration: _done ? TextDecoration.lineThrough : null,
                  ),
                ),
                _Detail(row: this),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _CheckButton(done: _done, onTap: _done ? null : onDone),
        ],
      ),
    );
    final swipe = onDone;
    // A done row is faded, as in the Figma, and cannot be swiped.
    if (_done) return Opacity(opacity: 0.7, child: card);
    if (swipe == null) return card;
    return Dismissible(
      // Fixed: the row is the only child of this Dismissible's parent slot.
      key: const ValueKey('swipe-to-done'),
      direction: DismissDirection.startToEnd,
      // The row never leaves the tree; the caller flips it to `done`.
      confirmDismiss: (_) async {
        swipe();
        return false;
      },
      background: const _SwipeBackground(),
      child: card,
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.row});

  final TaskRow row;

  @override
  Widget build(BuildContext context) {
    final style = AppText.bodySm.copyWith(color: AppColors.soil600);
    switch (row.state) {
      case TaskRowState.overdue:
        final days = row.overdueDays;
        return _iconLine(
          Symbols.error_rounded,
          'Overdue · $days ${days == 1 ? 'day' : 'days'}',
          AppColors.error,
        );
      case TaskRowState.rainSkip:
        return _iconLine(
          Symbols.umbrella_rounded,
          rainSkipCopy,
          AppColors.frost,
        );
      case TaskRowState.done:
        final at = row.doneAt;
        return Text(at == null ? 'Done' : 'Done at $at', style: style);
      case TaskRowState.due:
        final sub = row.type == TaskRowType.other ? row.plantName : row.note;
        return sub == null ? const SizedBox.shrink() : Text(sub, style: style);
    }
  }

  Widget _iconLine(IconData icon, String text, Color color) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2, right: AppSpacing.xs),
        child: Icon(icon, size: AppIconSize.sm, color: color, fill: 1),
      ),
      Expanded(
        child: Text(text, style: AppText.bodySm.copyWith(color: color)),
      ),
    ],
  );
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.type});

  final TaskRowType type;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color bg, Color fg) = switch (type) {
      TaskRowType.water => (
        Symbols.water_drop_rounded,
        AppColors.tileSky,
        AppColors.tileSkyLedge,
      ),
      TaskRowType.fertilize => (
        Symbols.science_rounded,
        AppColors.gold100,
        AppColors.goldLedge,
      ),
      TaskRowType.prune => (
        Symbols.content_cut_rounded,
        AppColors.leaf100,
        AppColors.leaf700,
      ),
      TaskRowType.harvest => (
        Symbols.shopping_basket_rounded,
        AppColors.tilePeach,
        AppColors.heat,
      ),
      TaskRowType.other => (
        Symbols.sticky_note_2_rounded,
        AppColors.tileSoil,
        AppColors.tileSoilLedge,
      ),
    };
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.card - 2),
      ),
      child: Icon(icon, size: 28, color: fg, fill: 1),
    );
  }
}

/// Round check on the right of a row: an empty ledge circle, or a filled
/// green one once done.
class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.done, required this.onTap});

  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    final circle = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.leaf700 : AppColors.stone200,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppBorders.ledge - 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.leaf500 : AppColors.white,
            border: done
                ? null
                : Border.all(
                    color: AppColors.stone200,
                    width: AppBorders.width,
                  ),
          ),
          child: SizedBox(
            width: size,
            height: size - (AppBorders.ledge - 2),
            child: Icon(
              Symbols.check_rounded,
              size: 28,
              color: done ? AppColors.white : AppColors.chevronMuted,
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: !done,
      label: done ? 'Done' : 'Mark done',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: circle,
      ),
    );
  }
}

/// Revealed behind a row as it is dragged to the right.
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.leaf100,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: const Icon(
        Symbols.check_rounded,
        size: AppIconSize.xl,
        color: AppColors.leaf700,
      ),
    );
  }
}
