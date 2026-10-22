import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/app/theme.dart';

/// WCAG 2.x relative luminance of an opaque color.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG contrast ratio, 1 to 21.
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  // plan/01 § Design review checklist: text contrast ≥ 4.5:1.
  const minimum = 4.5;

  group('contrast()', () {
    test('black on white is 21:1 and a color on itself is 1:1', () {
      expect(contrast(const Color(0xFF000000), AppColors.white), 21);
      expect(contrast(AppColors.leaf700, AppColors.leaf700), 1);
    });

    test('matches the published ratio for #767676 on white (4.54)', () {
      expect(
        contrast(const Color(0xFF767676), AppColors.white),
        closeTo(4.54, 0.01),
      );
    });

    test('gold text on white fails, as plan/01 warns', () {
      expect(contrast(AppColors.geauxGold, AppColors.white), lessThan(minimum));
    });
  });

  group('text tokens on the surfaces they sit on', () {
    // (text, background, where) for each pair the shared widgets and the
    // theme use. plan/01 § Foundations names the surfaces: cream-50 app
    // background, white cards, leaf-100 selected fills, gold-100 alerts.
    const pairs = <(Color, Color, String)>[
      (AppColors.soil900, AppColors.cream50, 'primary text on the app'),
      (AppColors.soil900, AppColors.white, 'primary text on cards'),
      (AppColors.soil900, AppColors.leaf100, 'text on selected fills'),
      (AppColors.soil900, AppColors.gold100, 'text on alert banners'),
      (AppColors.soil900, AppColors.geauxGold, 'soil-900 on gold fills'),
      (AppColors.soil600, AppColors.cream50, 'secondary text on the app'),
      (AppColors.soil600, AppColors.white, 'secondary text on cards'),
      (AppColors.soil600, AppColors.leaf100, 'secondary on selected fills'),
      (AppColors.leaf700, AppColors.white, 'text buttons on cards'),
      (AppColors.leaf700, AppColors.cream50, 'text buttons on the app'),
      (AppColors.leaf700, AppColors.leaf100, 'selected chip labels'),
      (AppColors.white, AppColors.leaf700, 'primary button labels'),
      (AppColors.white, AppColors.tigerPurple, 'community brand fills'),
      (AppColors.white, AppColors.error, 'labels on error fills'),
      (AppColors.error, AppColors.white, 'error text on cards'),
    ];
    for (final (text, background, where) in pairs) {
      test('$where ≥ 4.5:1', () {
        expect(contrast(text, background), greaterThanOrEqualTo(minimum));
      });
    }
  });

  group('AppTheme.light text styles', () {
    final theme = AppTheme.light();
    final styles = {
      'displaySmall': theme.textTheme.displaySmall,
      'headlineSmall': theme.textTheme.headlineSmall,
      'titleLarge': theme.textTheme.titleLarge,
      'bodyLarge': theme.textTheme.bodyLarge,
      'bodyMedium': theme.textTheme.bodyMedium,
      'bodySmall': theme.textTheme.bodySmall,
      'labelMedium': theme.textTheme.labelMedium,
      'labelSmall': theme.textTheme.labelSmall,
    };

    for (final MapEntry(key: name, value: style) in styles.entries) {
      test('$name passes on cream-50 and white, and is never gold', () {
        final color = style!.color!;
        expect(color, isNot(AppColors.geauxGold));
        expect(
          contrast(color, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(minimum),
        );
        expect(
          contrast(color, theme.colorScheme.surface),
          greaterThanOrEqualTo(minimum),
        );
      });
    }

    test('every on-color in the scheme passes on its fill', () {
      final s = theme.colorScheme;
      for (final (on, fill) in [
        (s.onPrimary, s.primary),
        (s.onSecondary, s.secondary),
        (s.onTertiary, s.tertiary),
        (s.onError, s.error),
        (s.onSurface, s.surface),
        (s.onSurfaceVariant, s.surface),
        (s.onPrimaryContainer, s.primaryContainer),
        (s.onSecondaryContainer, s.secondaryContainer),
      ]) {
        expect(contrast(on, fill), greaterThanOrEqualTo(minimum));
      }
    });
  });

  test('no text style in lib/ is colored geaux-gold', () {
    // A TextStyle or AppText copyWith whose color is gold. Gold stays a
    // fill (with soil-900 text) or an icon tint (plan/01 § Foundations).
    final goldText = RegExp(
      r'(TextStyle|AppText\.\w+\.copyWith)\([^()]*color:\s*AppColors\.geauxGold',
    );
    expect(
      goldText.hasMatch(
        'AppText.body.copyWith(\n  fontSize: 2,\n  color: AppColors.geauxGold,\n)',
      ),
      isTrue,
      reason: 'the scan must catch a multi-line copyWith',
    );
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            goldText.hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(offenders, isEmpty);
  });
}
