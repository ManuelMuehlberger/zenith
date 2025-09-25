 // ignore_for_file: constant_identifier_names

import 'dart:ui' show Color;
import 'package:flutter/painting.dart' show TextStyle, FontWeight;
import 'package:flutter/widgets.dart';

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
  static const String DEFAULT_THEME = 'dark';
  static const Units DEFAULT_UNITS = Units.metric;

  /// Spacing constants (unify card/list spacing across the app)
  static const double CARD_VERTICAL_GAP = 12.0; // Gap between cards/items in lists
  static const double SECTION_VERTICAL_GAP = 16.0; // Gap between sections/headers and lists
  static const double ITEM_HORIZONTAL_GAP = 16.0; // Standard horizontal gap between icon/text
  static const double SCROLL_HYSTERESIS_THRESHOLD = 150.0; // Scroll distance to trigger animations

  /// Drag and Drop animations
  static const Duration DRAG_ANIMATION_DURATION = Duration(milliseconds: 200);
  static const Curve DRAG_ANIMATION_CURVE = Curves.easeInOut;
  static const double DRAG_ITEM_LIFT_SCALE = 1.05;

  /// iOS-style UI metrics
  static const double CARD_RADIUS = 12.0; // Standard corner radius for cards/containers
  static const double SHEET_RADIUS = 20.0; // Corner radius for bottom sheets/action sheets
  static const double HEADER_EXTRA_HEIGHT = 60.0; // Extra header height below toolbar for controls
  static const double HEADER_BLUR_SIGMA = 10.0; // Blur intensity for translucent headers
  static const double PAGE_HORIZONTAL_PADDING = 16.0; // Standard page horizontal padding
  static const double CARD_PADDING = 16.0; // Standard internal padding for cards/containers

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
  // Exercise card background color to match home screen cards
  static const Color EXERCISE_CARD_BG_COLOR = Color(0xFF1A1A1A); // Dark grey matching home screen
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

  // Accent color used throughout the app
  static const Color ACCENT_COLOR = Color(0xFF007AFF); // Standard iOS blue

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

  // Normal text style for general purpose
  static const double IOS_NORMAL_FONT_SIZE = 15.0;
  static const FontWeight IOS_NORMAL_FONT_WEIGHT = FontWeight.w500;
  static const TextStyle IOS_NORMAL_TEXT_STYLE = TextStyle(
    fontSize: IOS_NORMAL_FONT_SIZE,
    fontWeight: IOS_NORMAL_FONT_WEIGHT,
    color: TEXT_SECONDARY_COLOR,
  );

  // Subtitle text style (e.g., for workout details)
  static const double IOS_SUBTITLE_FONT_SIZE = 15.0;
  static const FontWeight IOS_SUBTITLE_FONT_WEIGHT = FontWeight.w400;
  static const TextStyle IOS_SUBTITLE_TEXT_STYLE = TextStyle(
    fontSize: IOS_SUBTITLE_FONT_SIZE,
    fontWeight: IOS_SUBTITLE_FONT_WEIGHT,
    color: TEXT_SECONDARY_COLOR,
  );

  // Subtext style (smaller, grayer)
  static const double IOS_SUBTEXT_FONT_SIZE = 13.0;
  static const FontWeight IOS_SUBTEXT_FONT_WEIGHT = FontWeight.w400;
  static const TextStyle IOS_SUBTEXT_STYLE = TextStyle(
    fontSize: IOS_SUBTEXT_FONT_SIZE,
    fontWeight: IOS_SUBTEXT_FONT_WEIGHT,
    color: TEXT_TERTIARY_COLOR,
  );

  // Card-specific text styles
  static const TextStyle CARD_TITLE_TEXT_STYLE = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    color: TEXT_PRIMARY_COLOR,
  );

  static const TextStyle CARD_SUBTITLE_TEXT_STYLE = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: TEXT_SECONDARY_COLOR,
  );

  // Button and action text constants
  static const String BACK_BUTTON_TOOLTIP = 'Back';
  static const String SELECT_EXERCISE_TITLE = 'Select Exercise';
  static const String DONE_BUTTON_TEXT = 'Done';
  static const TextStyle HEADER_BUTTON_TEXT_STYLE = TextStyle(
    color: ACCENT_COLOR,
    fontSize: 16,
    fontWeight: FontWeight.w600,
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

/// Equipment types available in the application
enum EquipmentType {
  barbell('Barbell'),
  dumbbell('Dumbbell'), // Note: Corrected spelling from "Dumbell" in data
  cable('Cable'),
  machine('Machine'),
  none('None');

  final String displayName;
  const EquipmentType(this.displayName);

  static EquipmentType fromString(String value) {
    // Handle the misspelling in the data ("Dumbell" instead of "Dumbbell")
    final normalizedValue = value == 'Dumbell' ? 'Dumbbell' : value;
    return values.firstWhere(
      (e) => e.displayName == normalizedValue,
      orElse: () => EquipmentType.none,
    );
  }

  static List<EquipmentType> get all => values.toList();
}

/// Muscle groups available in the application
/// This mirrors the MuscleGroup enum in models/muscle_group.dart
/// but provides a consistent reference for UI components
enum AppMuscleGroup {
  chest('Chest'),
  triceps('Triceps'),
  frontDeltoids('Front Deltoids'),
  core('Core'),
  lateralDeltoids('Lateral Deltoids'),
  rearDeltoids('Rear Deltoids'),
  shoulders('Shoulders'),
  biceps('Biceps'),
  lats('Lats'),
  rotatorCuff('Rotator Cuffs'),
  quads('Quads'),
  hamstrings('Hamstrings'),
  glutes('Glutes'),
  abductors('Abductors'),
  adductors('Adductors'),
  lowerBack('Lower Back'),
  trapezius('Trapezius'),
  forearmFlexors('Forearm Flexors'),
  forearms('Forearms'),
  calves('Calves'),
  abs('Abs'),
  obliques('Obliques'),
  back('Back'),
  legs('Legs'),
  cardio('Cardio'),
  na('NA');

  final String displayName;
  const AppMuscleGroup(this.displayName);

  static AppMuscleGroup fromString(String value) {
    return values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => AppMuscleGroup.na,
    );
  }

  static List<AppMuscleGroup> get all => values.toList();
}
