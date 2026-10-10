import 'package:flutter/material.dart';

const _pressDuration = Duration(milliseconds: 60);
const _depth = 4.0;

/// A large primary button with a solid ledge underneath that it sinks into
/// while pressed. Disabled when [onPressed] is null.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final sunk = _pressed || !enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: _pressDuration,
          margin: .only(top: sunk ? _depth : 0, bottom: sunk ? 0 : _depth),
          padding: const .symmetric(vertical: 14),
          alignment: .center,
          decoration: BoxDecoration(
            color: enabled ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: .circular(16),
            boxShadow: [
              if (!sunk)
                BoxShadow(
                  color: Color.lerp(scheme.primary, Colors.black, 0.3)!,
                  offset: const Offset(0, _depth),
                ),
            ],
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              color: enabled
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: 0.38),
              fontSize: 16,
              fontWeight: .w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// A selectable answer card that sinks while pressed and is highlighted when
/// [selected]. With [compact] it shrinks to fit its label, for use in a wrap.
class OptionCard extends StatefulWidget {
  const OptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.icon,
    this.compact = false,
  });

  final String label;
  final String? description;
  final IconData? icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<OptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = widget.selected;
    final borderColor = selected ? scheme.primary : scheme.outlineVariant;
    final foreground = selected ? scheme.primary : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _pressDuration,
          margin: .only(top: _pressed ? _depth - 2 : 0),
          padding: widget.compact
              ? const .symmetric(horizontal: 16, vertical: 10)
              : const .all(16),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : scheme.surface,
            borderRadius: .circular(16),
            border: Border(
              top: BorderSide(color: borderColor, width: 2),
              left: BorderSide(color: borderColor, width: 2),
              right: BorderSide(color: borderColor, width: 2),
              bottom: BorderSide(
                color: borderColor,
                width: _pressed ? 2 : _depth,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: widget.compact ? .min : .max,
            spacing: 16,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: 36, color: scheme.primary),
              Flexible(
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisSize: .min,
                  children: [
                    Text(
                      widget.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: .w700,
                      ),
                    ),
                    if (widget.description != null)
                      Text(
                        widget.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
