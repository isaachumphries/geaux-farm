import 'package:flutter/material.dart';

/// Color tokens. Plan values come from `plan/01-layout-plan.md`
/// § Foundations; the Figma-only shades are sampled from the HM-01 and
/// OB-01 frame exports.
abstract final class AppColors {
  static const leaf700 = Color(0xFF2F6B3A);
  static const leaf500 = Color(0xFF4C9A5B);
  static const leaf100 = Color(0xFFE3F1E4);
  static const geauxGold = Color(0xFFF2B705);
  static const gold100 = Color(0xFFFFF4CC);
  static const tigerPurple = Color(0xFF4B2E83);
  static const soil900 = Color(0xFF2B2620);
  static const soil600 = Color(0xFF6B6258);
  static const stone200 = Color(0xFFE7E2D9);
  static const cream50 = Color(0xFFFAF7F0);
  static const white = Color(0xFFFFFFFF);

  // Plant-to-space compatibility.
  static const great = Color(0xFF2E7D32);
  static const good = Color(0xFF7CB342);
  static const possible = Color(0xFFF9A825);
  static const indoor = Color(0xFF8D6E63);

  // Alerts.
  static const frost = Color(0xFF3B82C4);
  static const heat = Color(0xFFD9480F);
  static const error = Color(0xFFC62828);

  // Figma-only ledges: the darker same-hue bottom edge of filled surfaces.
  /// Under leaf-700 fills (season banner, primary button).
  static const leafLedge = Color(0xFF1E4B25);

  /// Under geaux-gold fills (the "Plant now" ribbon).
  static const goldLedge = Color(0xFFCB9400);

  /// Border of the active bottom-nav pill.
  static const navActiveBorder = Color(0xFFAAD6B5);

  // Figma-only tinted icon tiles (OB-01 illustration, HM-01 cards).
  static const tilePeach = Color(0xFFFCE9DD);
  static const tileSky = Color(0xFFE2EFF9);
  static const tileSkyLedge = Color(0xFF3081CA);
  static const tileSoil = Color(0xFFF1E6D8);
  static const tileSoilLedge = Color(0xFFA27249);

  /// Translucent white disc behind a plant card's category icon (HM-01,
  /// RC-01).
  static const artHalo = Color(0x8CFFFFFF);
}

/// Type tokens: plan/01 sizes and line heights, Figma (Nunito) weights.
abstract final class AppText {
  static const fontFamily = 'Nunito';

  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w800,
  );
  static const h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w800,
  );
  static const h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w800,
  );
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
  );
  static const bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
  );
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
  );
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
  );

  /// Uppercase button labels ("GET STARTED", "I'LL PICK LATER").
  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 1,
  );

  /// Uppercase caps lines ("WEDNESDAY, OCT 7", "THIS SEASON").
  static const overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );

  /// Plant names on cards and card titles ("Kale", "Pick your first
  /// plant"): between body and h2 in the Figma.
  static const cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w800,
  );
}

/// Inline icon sizes: the steps the Figma uses next to text and in
/// buttons. Illustration art sizes stay with the widget that draws them.
abstract final class AppIconSize {
  /// Card detail lines and the maintenance pill's bolt.
  static const double xs = 14;

  /// Compat badge mark and the "Plant now" ribbon sprout.
  static const double sm = 16;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const List<double> scale = [xs, sm, md, lg, xl, xxl];

  static const double screenPadding = 16;
  static const double minTouchTarget = 48;
}

abstract final class AppRadii {
  static const double chip = 8;
  static const double card = 16;
  static const double sheet = 24;

  /// Fully rounded ends for pills and capsule buttons.
  static const double pill = 999;
}

abstract final class AppBorders {
  static const double width = 2;

  /// Total thickness of a ledge surface's bottom edge (border + ledge).
  static const double ledge = 4;

  static const cardSide = BorderSide(color: AppColors.stone200, width: width);
}

abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.leaf700,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.leaf100,
      onPrimaryContainer: AppColors.leaf700,
      secondary: AppColors.geauxGold,
      onSecondary: AppColors.soil900,
      secondaryContainer: AppColors.gold100,
      onSecondaryContainer: AppColors.soil900,
      tertiary: AppColors.tigerPurple,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.soil900,
      onSurfaceVariant: AppColors.soil600,
      outline: AppColors.stone200,
      outlineVariant: AppColors.stone200,
    );
    const ink = AppColors.soil900;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: AppText.fontFamily,
      scaffoldBackgroundColor: AppColors.cream50,
      textTheme: TextTheme(
        displaySmall: AppText.display.copyWith(color: ink),
        headlineSmall: AppText.h1.copyWith(color: ink),
        titleLarge: AppText.h2.copyWith(color: ink),
        bodyLarge: AppText.body.copyWith(color: ink),
        bodyMedium: AppText.bodySm.copyWith(color: ink),
        bodySmall: AppText.caption.copyWith(color: AppColors.soil600),
        labelMedium: AppText.label.copyWith(color: ink),
        labelSmall: AppText.caption.copyWith(color: ink),
      ),
      iconTheme: const IconThemeData(color: AppColors.soil600, size: 24),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: AppBorders.cardSide,
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        modalBackgroundColor: AppColors.white,
        elevation: 8,
        modalElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.sheet)),
        ),
      ),
    );
  }
}
