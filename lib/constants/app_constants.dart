 // ignore_for_file: constant_identifier_names

import 'dart:ui' show Color;
import 'package:flutter/painting.dart' show TextStyle, FontWeight;

/// Application-wide constants and enums
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// Weight units supported in the application
  static const Map<Units, String> WEIGHT_UNITS = {
    Units.metric: 'kg',
    Units.imperial: 'lbs',
  };

  /// Default values
  static const String DEFAULT_THEME = 'light';
  static const Units DEFAULT_UNITS = Units.metric;

  /// Spacing constants (unify card/list spacing across the app)
  static const double CARD_VERTICAL_GAP = 12.0;       // Gap between cards/items in lists
  static const double SECTION_VERTICAL_GAP = 16.0;    // Gap between sections/headers and lists
  static const double ITEM_HORIZONTAL_GAP = 16.0;     // Standard horizontal gap between icon/text

  /// iOS-style UI metrics
  static const double CARD_RADIUS = 12.0;             // Standard corner radius for cards/containers
  static const double SHEET_RADIUS = 20.0;            // Corner radius for bottom sheets/action sheets
  static const double HEADER_EXTRA_HEIGHT = 60.0;     // Extra header height below toolbar for controls
  static const double HEADER_BLUR_SIGMA = 10.0;       // Blur intensity for translucent headers
  static const double PAGE_HORIZONTAL_PADDING = 16.0; // Standard page horizontal padding
  static const double CARD_PADDING = 16.0;            // Standard internal padding for cards/containers

  // Glass header constants
  static const double GLASS_BLUR_SIGMA = HEADER_BLUR_SIGMA; // Alias for consistency with "glass" components
  static const Color HEADER_BG_COLOR_STRONG = Color(0xCC000000); // 80% black for strong glass headers
  static const Color HEADER_BG_COLOR_MEDIUM = Color(0x8A000000); // ~54% black (like Colors.black54) for lighter headers
  static const Color BOTTOM_BAR_BG_COLOR = Color(0x33000000); // ~20% black to keep blur clearly visible through content
  static const double HEADER_STROKE_WIDTH = 0.5; // Thin separator stroke width for headers (if used)
  static const Color HEADER_STROKE_COLOR = Color(0x59FFFFFF); // ~35% white stroke for subtle borders

  // Card visual constants
  // Background: semi-opaque dark surface for iOS-style cards
  static const Color CARD_BG_COLOR = Color(0xCC101010);
  // Subtle hairline stroke for glass/dark iOS aesthetics
  static const double CARD_STROKE_WIDTH = 0.5;
  static const Color CARD_STROKE_COLOR = HEADER_STROKE_COLOR;

  // Header text styles (shared across screens)
  static const double HEADER_TITLE_FONT_SIZE = 24.0;
  static const FontWeight HEADER_TITLE_FONT_WEIGHT = FontWeight.bold;
  static const Color HEADER_TITLE_COLOR = Color(0xFFFFFFFF);
  static const TextStyle HEADER_TITLE_TEXT_STYLE = TextStyle(
    fontSize: HEADER_TITLE_FONT_SIZE,
    fontWeight: HEADER_TITLE_FONT_WEIGHT,
    color: HEADER_TITLE_COLOR,
  );

  // Small header title (collapsed app bar)
  static const double HEADER_SMALL_TITLE_FONT_SIZE = 18.0;
  static const FontWeight HEADER_SMALL_TITLE_FONT_WEIGHT = FontWeight.w600;
  static const TextStyle HEADER_SMALL_TITLE_TEXT_STYLE = TextStyle(
    fontSize: HEADER_SMALL_TITLE_FONT_SIZE,
    fontWeight: HEADER_SMALL_TITLE_FONT_WEIGHT,
    color: HEADER_TITLE_COLOR,
  );

  // Large header title (expanded app bar)
  static const double HEADER_LARGE_TITLE_FONT_SIZE = 34.0;
  static const FontWeight HEADER_LARGE_TITLE_FONT_WEIGHT = FontWeight.w700;
  static const TextStyle HEADER_LARGE_TITLE_TEXT_STYLE = TextStyle(
    fontSize: HEADER_LARGE_TITLE_FONT_SIZE,
    fontWeight: HEADER_LARGE_TITLE_FONT_WEIGHT,
    color: HEADER_TITLE_COLOR,
  );

  // iOS-centric text styles for content
  static const Color TEXT_PRIMARY_COLOR = Color(0xFFFFFFFF);
  static const Color TEXT_SECONDARY_COLOR = Color(0xFFB0B0B0);
  static const Color TEXT_TERTIARY_COLOR = Color(0xFF8A8A8A);

  // Titles used in list items and section headers (e.g., exercise names)
  static const double IOS_TITLE_FONT_SIZE = 18.0;
  static const FontWeight IOS_TITLE_FONT_WEIGHT = FontWeight.w600;
  static const TextStyle IOS_TITLE_TEXT_STYLE = TextStyle(
    fontSize: IOS_TITLE_FONT_SIZE,
    fontWeight: IOS_TITLE_FONT_WEIGHT,
    color: TEXT_PRIMARY_COLOR,
  );

  // Default body text for iOS
  static const double IOS_BODY_FONT_SIZE = 17.0;
  static const FontWeight IOS_BODY_FONT_WEIGHT = FontWeight.w400;
  static const TextStyle IOS_BODY_TEXT_STYLE = TextStyle(
    fontSize: IOS_BODY_FONT_SIZE,
    fontWeight: IOS_BODY_FONT_WEIGHT,
    color: TEXT_PRIMARY_COLOR,
  );

  // Secondary/label text (e.g., chips, meta)
  static const double IOS_LABEL_FONT_SIZE = 13.0;
  static const FontWeight IOS_LABEL_FONT_WEIGHT = FontWeight.w500;
  static const TextStyle IOS_LABEL_TEXT_STYLE = TextStyle(
    fontSize: IOS_LABEL_FONT_SIZE,
    fontWeight: IOS_LABEL_FONT_WEIGHT,
    color: TEXT_SECONDARY_COLOR,
  );

}

/// Supported measurement units
enum Units {
  metric,
  imperial;

  /// Get the string representation of the unit for weight display
  String get weightUnit {
    switch (this) {
      case Units.metric:
        return 'kg';
      case Units.imperial:
        return 'lbs';
    }
  }

  /// Parse a string to a Units enum
  static Units fromString(String value) {
    return Units.values.firstWhere(
      (unit) => unit.name == value,
      orElse: () => Units.metric, // Default to metric
    );
  }
}
