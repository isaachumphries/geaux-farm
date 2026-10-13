import 'package:flutter/material.dart';

import '../theme.dart';

/// One tab of [GeauxBottomNav]. The icon comes from the caller (Material
/// Symbols Rounded); it is drawn filled when its tab is active.
class GeauxNavItem {
  const GeauxNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The app's tab bar: 4 tabs, or 5 once the Local stretch tab ships.
class GeauxBottomNav extends StatelessWidget {
  const GeauxBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  }) : assert(
         items.length == 4 || items.length == 5,
         'GeauxBottomNav takes 4 or 5 items',
       );

  final List<GeauxNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.stone200, width: AppBorders.width),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavTab(
                    item: items[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final GeauxNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.leaf700 : AppColors.soil600;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTouchTarget + AppSpacing.xs,
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: active ? AppColors.leaf100 : null,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: active
                      ? AppColors.navActiveBorder
                      : Colors.transparent,
                  width: AppBorders.width,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 24, color: fg, fill: active ? 1 : 0),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label.copyWith(
                      color: fg,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
