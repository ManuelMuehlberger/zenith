import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

enum AppThemePreference {
  system('system', 'System', ThemeMode.system),
  light('light', 'Light', ThemeMode.light),
  dark('dark', 'Dark', ThemeMode.dark);

  const AppThemePreference(this.storageValue, this.label, this.themeMode);

  final String storageValue;
  final String label;
  final ThemeMode themeMode;

  static AppThemePreference fromStorage(String? value) {
    for (final preference in values) {
      if (preference.storageValue == value) {
        return preference;
      }
    }
    return AppThemePreference.system;
  }
}

@immutable
// policy: allow-public-api theme palette contract consumed by app theme tokens.
class AppThemePalette {
  const AppThemePalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.field,
    required this.dockEdgeFade,
    required this.overlayStrong,
    required this.overlayMedium,
    required this.overlaySoft,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color field;
  final Color dockEdgeFade;
  final Color overlayStrong;
  final Color overlayMedium;
  final Color overlaySoft;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color shadow;
}

class AppThemeColors {
  AppThemeColors._();

  static const Color clear = Color(0x00000000);

  static const AppThemePalette light = AppThemePalette(
    background: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFFFFFF),
    field: Color(0xFFECEEF2),
    dockEdgeFade: Color(0xFFFFFFFF),
    overlayStrong: Color(0xF2FFFFFF),
    overlayMedium: Color(0xD9FFFFFF),
    overlaySoft: Color(0x99FFFFFF),
    outline: Color(0x1F101828),
    textPrimary: Color(0xFF101828),
    textSecondary: Color(0xFF667085),
    textTertiary: Color(0xFF98A2B3),
    accent: Color(0xFF0A6CDB),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9F0A),
    danger: Color(0xFFFF453A),
    shadow: Color(0x14000000),
  );

  static const AppThemePalette dark = AppThemePalette(
    background: Color(0xFF000000),
    surface: Color(0xFF212121),
    surfaceAlt: Color(0xFF1A1A1A),
    field: Color(0xFF2C2C2E),
    dockEdgeFade: Color(0xFF000000),
    overlayStrong: Color(0xCC000000),
    overlayMedium: Color(0x8A000000),
    overlaySoft: Color(0x33000000),
    outline: Color(0x59FFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B0B0),
    textTertiary: Color(0xFF8A8A8A),
    accent: Color(0xFF76B9FF),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9F0A),
    danger: Color(0xFFFF453A),
    shadow: Color(0x2E000000),
  );
}

class AppTextStyles {
  AppTextStyles._();

  static TextTheme theme(AppThemePalette palette) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: palette.textPrimary,
        height: 1.15,
      ),
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
        height: 1.2,
      ),
      headlineSmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: palette.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: palette.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: palette.textTertiary,
      ),
      labelLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: palette.accent,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: palette.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: palette.textTertiary,
      ),
    );
  }
}

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.surfaceAlt,
    required this.field,
    required this.dockEdgeFade,
    required this.overlayStrong,
    required this.overlayMedium,
    required this.overlaySoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.warning,
    required this.shadow,
  });

  final Color surfaceAlt;
  final Color field;
  final Color dockEdgeFade;
  final Color overlayStrong;
  final Color overlayMedium;
  final Color overlaySoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color success;
  final Color warning;
  final Color shadow;

  @override
  AppThemeTokens copyWith({
    Color? surfaceAlt,
    Color? field,
    Color? dockEdgeFade,
    Color? overlayStrong,
    Color? overlayMedium,
    Color? overlaySoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? warning,
    Color? shadow,
  }) {
    return AppThemeTokens(
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      field: field ?? this.field,
      dockEdgeFade: dockEdgeFade ?? this.dockEdgeFade,
      overlayStrong: overlayStrong ?? this.overlayStrong,
      overlayMedium: overlayMedium ?? this.overlayMedium,
      overlaySoft: overlaySoft ?? this.overlaySoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) {
      return this;
    }

    return AppThemeTokens(
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t) ?? surfaceAlt,
      field: Color.lerp(field, other.field, t) ?? field,
      dockEdgeFade:
          Color.lerp(dockEdgeFade, other.dockEdgeFade, t) ?? dockEdgeFade,
      overlayStrong:
          Color.lerp(overlayStrong, other.overlayStrong, t) ?? overlayStrong,
      overlayMedium:
          Color.lerp(overlayMedium, other.overlayMedium, t) ?? overlayMedium,
      overlaySoft: Color.lerp(overlaySoft, other.overlaySoft, t) ?? overlaySoft,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textTertiary:
          Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const double mainDockHeight = 64;
  static const double mainDockOffset = 18;
  static const double mainDockMaxWidth = 420;
  static const double mainDockBlurSigma = 14;
  static const double mainDockEdgeBlurBaseHeight = mainDockClearance * 1.6;
  static const double mainDockEdgeBlurVisibleStop = 0.24;
  static const double mainDockEdgeFadeBaseHeight = mainDockClearance * 2.1;
  static const double mainDockEdgeFadeMidStop = 0.6;
  static const double mainDockEdgeFadeShoulderOpacity = 0.12;
  static const double mainDockEdgeFadeBottomOpacity = 0.78;
  static const double mainDockIconSize = 28;
  static const double mainDockSelectedIconSize = 30;
  static const double mainDockPrimaryWidth = 236;
  static const double mainDockCompactWidth = 188;
  static const double mainDockActionSize = 64;
  static const double mainDockActionGap = 14;
  static const double mainDockItemPadding = 14;
  static const BorderRadius mainDockBorderRadius = BorderRadius.all(
    Radius.circular(28),
  );
  static const BorderRadius workoutCardBorderRadius = mainDockBorderRadius;
  static const double mainDockClearance = mainDockHeight + mainDockOffset;

  static final AppThemeTokens lightTokens = AppThemeTokens(
    surfaceAlt: AppThemeColors.light.surfaceAlt,
    field: AppThemeColors.light.field,
    dockEdgeFade: AppThemeColors.light.dockEdgeFade,
    overlayStrong: AppThemeColors.light.overlayStrong,
    overlayMedium: AppThemeColors.light.overlayMedium,
    overlaySoft: AppThemeColors.light.overlaySoft,
    textPrimary: AppThemeColors.light.textPrimary,
    textSecondary: AppThemeColors.light.textSecondary,
    textTertiary: AppThemeColors.light.textTertiary,
    success: AppThemeColors.light.success,
    warning: AppThemeColors.light.warning,
    shadow: AppThemeColors.light.shadow,
  );

  static final AppThemeTokens darkTokens = AppThemeTokens(
    surfaceAlt: AppThemeColors.dark.surfaceAlt,
    field: AppThemeColors.dark.field,
    dockEdgeFade: AppThemeColors.dark.dockEdgeFade,
    overlayStrong: AppThemeColors.dark.overlayStrong,
    overlayMedium: AppThemeColors.dark.overlayMedium,
    overlaySoft: AppThemeColors.dark.overlaySoft,
    textPrimary: AppThemeColors.dark.textPrimary,
    textSecondary: AppThemeColors.dark.textSecondary,
    textTertiary: AppThemeColors.dark.textTertiary,
    success: AppThemeColors.dark.success,
    warning: AppThemeColors.dark.warning,
    shadow: AppThemeColors.dark.shadow,
  );

  static const BottomBarThemeData _bottomBarTheme = BottomBarThemeData(
    barDecoration: BoxDecoration(color: AppThemeColors.clear),
    layout: BottomBarLayout(
      offset: mainDockOffset,
      borderRadius: mainDockBorderRadius,
      clip: Clip.none,
      respectSafeArea: false,
    ),
    scrollBehavior: BottomBarScrollBehavior(hideOnScroll: false),
  );

  static ThemeData _buildTheme(
    AppThemePalette palette,
    Brightness brightness,
    AppThemeTokens tokens,
  ) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.accent,
      onPrimary: palette.onAccent,
      secondary: palette.accent,
      onSecondary: palette.onAccent,
      error: palette.danger,
      onError: palette.onAccent,
      surface: palette.surface,
      onSurface: palette.textPrimary,
    );
    final textTheme = AppTextStyles.theme(palette);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,
      dividerColor: palette.outline,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        surfaceTintColor: AppThemeColors.clear,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: AppThemeColors.clear,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppThemeColors.clear,
        selectedItemColor: palette.accent,
        unselectedItemColor: palette.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          elevation: 0,
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.textSecondary,
          textStyle: textTheme.titleMedium?.copyWith(
            color: palette.textSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: brightness,
        primaryColor: palette.accent,
        scaffoldBackgroundColor: palette.background,
        barBackgroundColor: palette.background,
        textTheme: CupertinoTextThemeData(
          primaryColor: palette.accent,
          textStyle: textTheme.bodyLarge,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[tokens, _bottomBarTheme],
    );
  }

  static final ThemeData light = _buildTheme(
    AppThemeColors.light,
    Brightness.light,
    lightTokens,
  );

  static final ThemeData dark = _buildTheme(
    AppThemeColors.dark,
    Brightness.dark,
    darkTokens,
  );

  static AppThemeTokens tokensFor(Brightness brightness) {
    return brightness == Brightness.dark ? darkTokens : lightTokens;
  }
}

extension AppThemeContext on BuildContext {
  ColorScheme get appScheme => Theme.of(this).colorScheme;

  TextTheme get appText => Theme.of(this).textTheme;

  AppThemeTokens get appColors =>
      Theme.of(this).extension<AppThemeTokens>() ??
      AppTheme.tokensFor(Theme.of(this).brightness);
}
