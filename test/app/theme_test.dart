import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';

void main() {
  test('plan color tokens have their exact hex values', () {
    final expected = <(Color, int)>[
      (AppColors.leaf700, 0xFF2F6B3A),
      (AppColors.leaf500, 0xFF4C9A5B),
      (AppColors.leaf100, 0xFFE3F1E4),
      (AppColors.geauxGold, 0xFFF2B705),
      (AppColors.gold100, 0xFFFFF4CC),
      (AppColors.tigerPurple, 0xFF4B2E83),
      (AppColors.soil900, 0xFF2B2620),
      (AppColors.soil600, 0xFF6B6258),
      (AppColors.stone200, 0xFFE7E2D9),
      (AppColors.cream50, 0xFFFAF7F0),
      (AppColors.white, 0xFFFFFFFF),
      (AppColors.great, 0xFF2E7D32),
      (AppColors.good, 0xFF7CB342),
      (AppColors.possible, 0xFFF9A825),
      (AppColors.indoor, 0xFF8D6E63),
      (AppColors.frost, 0xFF3B82C4),
      (AppColors.heat, 0xFFD9480F),
      (AppColors.error, 0xFFC62828),
    ];
    for (final (color, hex) in expected) {
      expect(color, Color(hex));
    }
  });

  test('type styles are Nunito with the binding size/line/weight', () {
    void check(TextStyle s, double size, double line, FontWeight weight) {
      expect(s.fontFamily, 'Nunito');
      expect(s.fontSize, size);
      expect(s.fontSize! * s.height!, closeTo(line, 1e-9));
      expect(s.fontWeight, weight);
    }

    check(AppText.display, 32, 40, FontWeight.w800);
    check(AppText.h1, 24, 32, FontWeight.w800);
    check(AppText.h2, 20, 28, FontWeight.w800);
    check(AppText.body, 16, 24, FontWeight.w500);
    check(AppText.bodySm, 14, 20, FontWeight.w500);
    check(AppText.label, 12, 16, FontWeight.w700);
    check(AppText.caption, 11, 14, FontWeight.w600);
    check(AppText.button, 14, 20, FontWeight.w800);
    check(AppText.overline, 12, 16, FontWeight.w800);
    expect(AppText.button.letterSpacing, 1);
    expect(AppText.overline.letterSpacing, 0.5);
  });

  test('spacing and radius scales', () {
    expect(AppSpacing.scale, [4, 8, 12, 16, 24, 32]);
    expect(AppSpacing.screenPadding, 16);
    expect(AppRadii.chip, 8);
    expect(AppRadii.card, 16);
    expect(AppRadii.sheet, 24);
    expect(AppBorders.width, 2);
    expect(AppBorders.ledge, 4);
    expect(
      [
        AppIconSize.xs,
        AppIconSize.sm,
        AppIconSize.md,
        AppIconSize.lg,
        AppIconSize.xl,
      ],
      [14, 16, 18, 22, 24],
    );
  });

  group('AppTheme.light', () {
    final theme = AppTheme.light();

    test('is Material 3, light, on cream-50 with leaf-700 primary', () {
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.cream50);
      expect(theme.colorScheme.primary, AppColors.leaf700);
    });

    test('text theme maps the type tokens and never uses gold as text', () {
      final t = theme.textTheme;
      expect(t.displaySmall!.fontSize, AppText.display.fontSize);
      expect(t.headlineSmall!.fontWeight, AppText.h1.fontWeight);
      expect(t.titleLarge!.fontSize, AppText.h2.fontSize);
      expect(t.bodyLarge!.fontWeight, AppText.body.fontWeight);
      expect(t.bodyMedium!.fontSize, AppText.bodySm.fontSize);
      expect(t.labelMedium!.fontWeight, AppText.label.fontWeight);
      for (final s in [
        t.displaySmall,
        t.headlineSmall,
        t.titleLarge,
        t.bodyLarge,
        t.bodyMedium,
        t.bodySmall,
        t.labelMedium,
        t.labelSmall,
      ]) {
        expect(s!.fontFamily, 'Nunito');
        expect(s.color, isNot(AppColors.geauxGold));
      }
    });

    test('cards are flat with a 2px stone-200 side and radius 16', () {
      final card = theme.cardTheme;
      final shape = card.shape! as RoundedRectangleBorder;
      expect(card.elevation, 0);
      expect(shape.side, const BorderSide(color: AppColors.stone200, width: 2));
      expect(shape.borderRadius, BorderRadius.circular(16));
    });

    test('bottom sheet has radius 24 and is the surface with a shadow', () {
      final sheet = theme.bottomSheetTheme;
      final shape = sheet.shape! as RoundedRectangleBorder;
      expect(
        shape.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(24)),
      );
      expect(sheet.modalElevation, greaterThan(0));
      expect(theme.cardTheme.elevation, 0);
    });
  });
}
