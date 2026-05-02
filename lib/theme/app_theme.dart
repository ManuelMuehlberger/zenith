import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class AppThemeColors {
  AppThemeColors._();

  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF212121);
  static const Color surfaceAlt = Color(0xFF1A1A1A);
  static const Color field = Color(0xFF2C2C2E);
  static const Color overlayStrong = Color(0xCC000000);
  static const Color overlayMedium = Color(0x8A000000);
  static const Color overlaySoft = Color(0x33000000);
  static const Color clear = Color(0x00000000);
  static const Color outline = Color(0x59FFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF8A8A8A);
  static const Color accent = Color(0xFF10DFE2);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color danger = Color(0xFFFF453A);
  static const Color shadow = Color(0x2E000000);
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle hero = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppThemeColors.textPrimary,
    height: 1.15,
  );

  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppThemeColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppThemeColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppThemeColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppThemeColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppThemeColors.textPrimary,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppThemeColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppThemeColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppThemeColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppThemeColors.textTertiary,
  );

  static const TextStyle action = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppThemeColors.accent,
  );

  static const TextTheme theme = TextTheme(
    displayLarge: hero,
    displaySmall: display,
    headlineSmall: headline,
    titleLarge: appBarTitle,
    titleMedium: sectionTitle,
    titleSmall: bodyStrong,
    bodyLarge: body,
    bodyMedium: bodySecondary,
    bodySmall: caption,
    labelLarge: action,
    labelMedium: label,
    labelSmall: caption,
  );
}

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.surfaceAlt,
    required this.field,
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
  static const double mainDockBlurSigma = 18;
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
  static const double mainDockClearance = mainDockHeight + mainDockOffset;

  static const AppThemeTokens darkTokens = AppThemeTokens(
    surfaceAlt: AppThemeColors.surfaceAlt,
    field: AppThemeColors.field,
    overlayStrong: AppThemeColors.overlayStrong,
    overlayMedium: AppThemeColors.overlayMedium,
    overlaySoft: AppThemeColors.overlaySoft,
    textPrimary: AppThemeColors.textPrimary,
    textSecondary: AppThemeColors.textSecondary,
    textTertiary: AppThemeColors.textTertiary,
    success: AppThemeColors.success,
    warning: AppThemeColors.warning,
    shadow: AppThemeColors.shadow,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppThemeColors.accent,
    onPrimary: AppThemeColors.textPrimary,
    secondary: AppThemeColors.accent,
    onSecondary: AppThemeColors.textPrimary,
    error: AppThemeColors.danger,
    onError: AppThemeColors.textPrimary,
    surface: AppThemeColors.surface,
    onSurface: AppThemeColors.textPrimary,
  );

  static const BottomBarThemeData _darkBottomBarTheme = BottomBarThemeData(
    barDecoration: BoxDecoration(color: AppThemeColors.clear),
    layout: BottomBarLayout(
      offset: mainDockOffset,
      borderRadius: mainDockBorderRadius,
      clip: Clip.none,
      respectSafeArea: false,
    ),
    scrollBehavior: BottomBarScrollBehavior(hideOnScroll: false),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: AppThemeColors.background,
    textTheme: AppTextStyles.theme,
    dividerColor: AppThemeColors.outline,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppThemeColors.background,
      foregroundColor: AppThemeColors.textPrimary,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: AppThemeColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppThemeColors.clear,
      selectedItemColor: AppThemeColors.accent,
      unselectedItemColor: AppThemeColors.textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppThemeColors.accent,
        foregroundColor: AppThemeColors.textPrimary,
        elevation: 0,
        textStyle: AppTextStyles.sectionTitle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppThemeColors.accent,
        foregroundColor: AppThemeColors.textPrimary,
        textStyle: AppTextStyles.sectionTitle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppThemeColors.textSecondary,
        textStyle: AppTextStyles.sectionTitle.copyWith(
          color: AppThemeColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppThemeColors.accent,
      scaffoldBackgroundColor: AppThemeColors.background,
      barBackgroundColor: AppThemeColors.overlayMedium,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppThemeColors.accent,
        textStyle: AppTextStyles.body,
      ),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      darkTokens,
      _darkBottomBarTheme,
    ],
  );
}

extension AppThemeContext on BuildContext {
  ColorScheme get appScheme => Theme.of(this).colorScheme;

  TextTheme get appText => Theme.of(this).textTheme;

  AppThemeTokens get appColors =>
      Theme.of(this).extension<AppThemeTokens>() ?? AppTheme.darkTokens;
}
