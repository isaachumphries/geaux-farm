import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../domain/availability_edits.dart';

/// The OB-05 week grid: 7 day columns by 8 two-hour rows. Pointer-down on
/// a cell picks the paint mode (the opposite of that cell), and dragging
/// applies it to every cell the pointer crosses; a tap toggles one cell.
/// Each change fires a light haptic.
class AvailabilityGrid extends StatefulWidget {
  const AvailabilityGrid({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// 7 bitmasks, Mon..Sun.
  final List<int> value;
  final ValueChanged<List<int>> onChanged;

  static const double cellWidth = 40;
  static const double cellHeight = 44;
  static const double gap = 2;
  static const double labelWidth = 40;
  static const double headerHeight = 20;

  @override
  State<AvailabilityGrid> createState() => _AvailabilityGridState();
}

class _AvailabilityGridState extends State<AvailabilityGrid> {
  /// Paint (true) or erase (false) for the current pointer; null when no
  /// pointer is down.
  bool? _paint;
  late List<int> _days = widget.value;
  double _cellWidth = AvailabilityGrid.cellWidth;

  @override
  void didUpdateWidget(AvailabilityGrid old) {
    super.didUpdateWidget(old);
    if (_paint == null) _days = widget.value;
  }

  /// The (day, block) under [local], a position inside the cell area.
  (int, int)? _cellAt(Offset local) {
    const gap = AvailabilityGrid.gap;
    final day = (local.dx / (_cellWidth + gap)).floor();
    final block = (local.dy / (AvailabilityGrid.cellHeight + gap)).floor();
    if (day < 0 || day >= availabilityDays) return null;
    if (block < 0 || block >= availabilityBlocks) return null;
    return (day, block);
  }

  void _apply(Offset local) {
    final cell = _cellAt(local);
    final paint = _paint;
    if (cell == null || paint == null) return;
    final (day, block) = cell;
    if (isBlockSet(_days, day, block) == paint) return;
    _days = setBlock(_days, day, block, paint);
    HapticFeedback.lightImpact();
    widget.onChanged(_days);
  }

  void _down(PointerDownEvent e) {
    final cell = _cellAt(e.localPosition);
    if (cell == null) return;
    _days = widget.value;
    _paint = !isBlockSet(_days, cell.$1, cell.$2);
    _apply(e.localPosition);
  }

  void _end() => _paint = null;

  @override
  Widget build(BuildContext context) {
    const gap = AvailabilityGrid.gap;
    const h = AvailabilityGrid.cellHeight;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow screens shrink the cells rather than scroll.
        _cellWidth = math.min(
          AvailabilityGrid.cellWidth,
          (constraints.maxWidth - AvailabilityGrid.labelWidth - gap * 8) / 7,
        );
        final w = _cellWidth;
        final labelStyle = AppText.caption.copyWith(color: AppColors.soil600);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: AvailabilityGrid.headerHeight,
              child: Row(
                children: [
                  const SizedBox(width: AvailabilityGrid.labelWidth + gap),
                  for (final d in dayLabels)
                    SizedBox(
                      width: w + gap,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: AppText.caption.copyWith(
                          color: AppColors.soil900,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: AvailabilityGrid.labelWidth,
                  child: Column(
                    children: [
                      for (final label in blockLabels)
                        SizedBox(
                          height: h + gap,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(label, style: labelStyle),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: gap),
                // The empty drag handlers win the gesture arena, so a drag
                // on the grid paints instead of scrolling the page.
                RawGestureDetector(
                  gestures: {
                    PanGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          PanGestureRecognizer
                        >(
                          () =>
                              PanGestureRecognizer()
                                ..dragStartBehavior = DragStartBehavior.down,
                          (r) => r.onStart = (_) {},
                        ),
                    VerticalDragGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          VerticalDragGestureRecognizer
                        >(
                          VerticalDragGestureRecognizer.new,
                          (r) => r.onStart = (_) {},
                        ),
                  },
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _down,
                    onPointerMove: (e) => _apply(e.localPosition),
                    onPointerUp: (_) => _end(),
                    onPointerCancel: (_) => _end(),
                    child: Semantics(
                      label:
                          'Availability grid, ${dayLabels.length} days by '
                          '${blockLabels.length} two-hour blocks',
                      child: SizedBox(
                        width: (w + gap) * 7,
                        height: (h + gap) * 8,
                        child: Column(
                          children: [
                            for (var b = 0; b < availabilityBlocks; b++)
                              Row(
                                children: [
                                  for (var d = 0; d < availabilityDays; d++)
                                    _Cell(
                                      key: ValueKey('cell-$d-$b'),
                                      width: w,
                                      selected: isBlockSet(widget.value, d, b),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({super.key, required this.width, required this.selected});

  final double width;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        right: AvailabilityGrid.gap,
        bottom: AvailabilityGrid.gap,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: width,
        height: AvailabilityGrid.cellHeight,
        decoration: BoxDecoration(
          color: selected ? AppColors.leaf500 : AppColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.leaf700 : AppColors.stone200,
            width: AppBorders.width,
          ),
        ),
      ),
    );
  }
}
