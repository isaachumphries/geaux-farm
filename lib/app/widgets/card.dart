import 'package:flutter/material.dart';

import '../theme.dart';

/// How long a tappable ledge surface stays sunk while pressed.
const geauxPressDuration = Duration(milliseconds: 60);

/// The Figma "ledge" surface: a rounded box sitting on a darker bottom
/// ledge so its bottom edge is [AppBorders.ledge] thick.
///
/// Outlined surfaces (the default white card) draw a [borderColor] border
/// of [AppBorders.width] and the ledge adds the rest. Filled surfaces pass
/// `borderColor: null`, so the whole bottom edge is [ledgeColor].
///
/// With [onTap] the surface is a button that sinks into its ledge while
/// pressed. Without it the card is inert.
class GeauxCard extends StatefulWidget {
  const GeauxCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color = AppColors.white,
    this.borderColor = AppColors.stone200,
    this.ledgeColor = AppColors.stone200,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color color;
  final Color? borderColor;
  final Color ledgeColor;

  @override
  State<GeauxCard> createState() => _GeauxCardState();
}

class _GeauxCardState extends State<GeauxCard> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    final border = widget.borderColor;
    final depth = AppBorders.ledge - (border == null ? 0 : AppBorders.width);
    const radius = BorderRadius.all(Radius.circular(AppRadii.card));
    final sunk = _pressed ? depth : 0.0;

    Widget surface = AnimatedPadding(
      duration: geauxPressDuration,
      padding: EdgeInsets.only(top: sunk),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.ledgeColor,
          borderRadius: radius,
        ),
        child: AnimatedPadding(
          duration: geauxPressDuration,
          padding: EdgeInsets.only(bottom: depth - sunk),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: radius,
              border: border == null
                  ? null
                  : Border.all(color: border, width: AppBorders.width),
            ),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );

    final onTap = widget.onTap;
    if (onTap == null) return surface;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: onTap,
        child: surface,
      ),
    );
  }
}
