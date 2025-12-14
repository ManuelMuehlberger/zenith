 // ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

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
  // Background: consistent dark surface for all cards (matching home screen)
  static const Color CARD_BG_COLOR = Color(0xFF212121); // Colors.grey[900] equivalent
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

  // Extra large bold title (for workout names and prominent headers)
  static const double HEADER_EXTRA_LARGE_TITLE_FONT_SIZE = 32.0;
  static const FontWeight HEADER_EXTRA_LARGE_TITLE_FONT_WEIGHT = FontWeight.w800;
  static const TextStyle HEADER_EXTRA_LARGE_TITLE_TEXT_STYLE = TextStyle(
    fontSize: HEADER_EXTRA_LARGE_TITLE_FONT_SIZE,
    fontWeight: HEADER_EXTRA_LARGE_TITLE_FONT_WEIGHT,
    color: HEADER_TITLE_COLOR,
  );

  // Super large ultra bold title (for very prominent headers)
  static const double HEADER_SUPER_LARGE_TITLE_FONT_SIZE = 36.0;
  static const FontWeight HEADER_SUPER_LARGE_TITLE_FONT_WEIGHT = FontWeight.w900;
  static const TextStyle HEADER_SUPER_LARGE_TITLE_TEXT_STYLE = TextStyle(
    fontSize: HEADER_SUPER_LARGE_TITLE_FONT_SIZE,
    fontWeight: HEADER_SUPER_LARGE_TITLE_FONT_WEIGHT,
    color: HEADER_TITLE_COLOR,
  );

  // iOS-centric text styles for content
  static const Color TEXT_PRIMARY_COLOR = Color(0xFFFFFFFF);
  static const Color TEXT_SECONDARY_COLOR = Color(0xFFB0B0B0);
  static const Color TEXT_TERTIARY_COLOR = Color(0xFF8A8A8A);

  // Accent color used throughout the app
  static const Color ACCENT_COLOR = Color.fromARGB(255, 16, 223, 226); // Standard iOS blue
  static const Color ACCENT_COLOR_GREEN = Colors.green;
  static const Color ACCENT_COLOR_ORANGE = Colors.orange;

  // UI element colors
  static const Color DIVIDER_COLOR = Color(0xFF424242); // Colors.grey[800]
  static const Color WORKOUT_BUTTON_BG_COLOR = Color(0xFF222222);
  static const Color FINISH_BUTTON_BG_COLOR = Color.fromARGB(255, 10, 18, 9);

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

  // Hint text style for text fields
  static const TextStyle IOS_HINT_TEXT_STYLE = TextStyle(
    fontSize: IOS_BODY_FONT_SIZE,
    fontWeight: IOS_BODY_FONT_WEIGHT,
    color: TEXT_SECONDARY_COLOR,
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

  // Subtitle text style with accent color
  static const TextStyle IOS_SUBTITLE_ACCENT_TEXT_STYLE = TextStyle(
    fontSize: IOS_SUBTITLE_FONT_SIZE,
    fontWeight: IOS_SUBTITLE_FONT_WEIGHT,
    color: ACCENT_COLOR,
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

  // Active Workout Screen specific text styles
  static const TextStyle WORKOUT_HEADER_PROGRESS_TEXT_STYLE = TextStyle(
    color: ACCENT_COLOR,
    fontSize: 11,
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

/// Workout icon/emoji selection item
class WorkoutIconItem {
  final String id;
  final IconData? icon;
  final String? emoji;
  final String name;

  const WorkoutIconItem({
    required this.id,
    this.icon,
    this.emoji,
    required this.name,
  }) : assert(icon != null || emoji != null, 'Either icon or emoji must be provided');

  bool get isEmoji => emoji != null;
  bool get isIcon => icon != null;
}

/// Available workout icons and emojis for customization
class WorkoutIcons {
  static const List<WorkoutIconItem> items = [
    // Core workout icons (reduced to most relevant)
    WorkoutIconItem(id: 'fitness_center', icon: Icons.fitness_center, name: 'Fitness'),
    WorkoutIconItem(id: 'bolt', icon: Icons.bolt, name: 'Power'),
    WorkoutIconItem(id: 'local_fire_department', icon: Icons.local_fire_department, name: 'Burn'),
    WorkoutIconItem(id: 'favorite', icon: Icons.favorite, name: 'Heart'),
    WorkoutIconItem(id: 'star', icon: Icons.star, name: 'Star'),
    
    // Body part icons
    WorkoutIconItem(id: 'accessibility_new', icon: Icons.accessibility_new, name: 'Full Body'),
    WorkoutIconItem(id: 'directions_walk', icon: Icons.directions_walk, name: 'Legs'),
    
    // Workout-relevant emojis
    WorkoutIconItem(id: 'muscle', emoji: '💪', name: 'Muscle'),
    WorkoutIconItem(id: 'fire', emoji: '🔥', name: 'Fire'),
    WorkoutIconItem(id: 'lightning', emoji: '⚡', name: 'Lightning'),
    WorkoutIconItem(id: 'target', emoji: '🎯', name: 'Target'),
    WorkoutIconItem(id: 'trophy', emoji: '🏆', name: 'Trophy'),
    WorkoutIconItem(id: 'medal', emoji: '🥇', name: 'Medal'),
    WorkoutIconItem(id: 'rocket', emoji: '🚀', name: 'Rocket'),
    WorkoutIconItem(id: 'diamond', emoji: '💎', name: 'Diamond'),
    WorkoutIconItem(id: 'crown', emoji: '👑', name: 'Crown'),
    WorkoutIconItem(id: 'sword', emoji: '⚔️', name: 'Sword'),
    WorkoutIconItem(id: 'shield', emoji: '🛡️', name: 'Shield'),
    WorkoutIconItem(id: 'mountain', emoji: '⛰️', name: 'Mountain'),
    WorkoutIconItem(id: 'volcano', emoji: '🌋', name: 'Volcano'),
    WorkoutIconItem(id: 'tornado', emoji: '🌪️', name: 'Tornado'),
    WorkoutIconItem(id: 'explosion', emoji: '💥', name: 'Explosion'),
    WorkoutIconItem(id: 'gem', emoji: '💍', name: 'Gem'),
    WorkoutIconItem(id: 'skull', emoji: '💀', name: 'Skull'),
    WorkoutIconItem(id: 'robot', emoji: '🤖', name: 'Robot'),
    WorkoutIconItem(id: 'alien', emoji: '👽', name: 'Alien'),
    WorkoutIconItem(id: 'ghost', emoji: '👻', name: 'Ghost'),
  ];

  /// Get the default icon item
  static WorkoutIconItem get defaultItem => items.first;

  /// Find an icon item by its ID
  static WorkoutIconItem? findById(String id) {
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Convert from legacy IconData to WorkoutIconItem
  static WorkoutIconItem fromIconData(IconData iconData) {
    // Try to find matching icon in our list
    for (final item in items) {
      if (item.icon?.codePoint == iconData.codePoint) {
        return item;
      }
    }
    // If not found, return default
    return defaultItem;
  }

  /// Convert from legacy icon code point to WorkoutIconItem
  static WorkoutIconItem fromCodePoint(int? codePoint) {
    if (codePoint == null) return defaultItem;
    
    for (final item in items) {
      if (item.icon?.codePoint == codePoint) {
        return item;
      }
    }
    return defaultItem;
  }

  /// Get IconData from code point, ensuring const invocation for tree shaking
  static IconData getIconDataFromCodePoint(int? codePoint) {
    if (codePoint == null) return Icons.fitness_center;
    
    // Check WorkoutIcons.items first
    for (final item in items) {
      if (item.icon?.codePoint == codePoint) {
        return item.icon!;
      }
    }

    // Check legacy icons
    switch (codePoint) {
      case 0xe1a3: // fitness_center
        return Icons.fitness_center;
      case 0xe02f: // directions_run
        return Icons.directions_run;
      case 0xe047: // pool
        return Icons.pool;
      case 0xe52f: // sports
        return Icons.sports;
      case 0xe531: // sports_gymnastics
        return Icons.sports_gymnastics;
      case 0xe532: // sports_handball
        return Icons.sports_handball;
      case 0xe533: // sports_martial_arts
        return Icons.sports_martial_arts;
      case 0xe534: // sports_mma
        return Icons.sports_mma;
      case 0xe535: // sports_motorsports
        return Icons.sports_motorsports;
      case 0xe536: // sports_score
        return Icons.sports_score;
    }

    // Default fallback
    return Icons.fitness_center;
  }
}
