import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('WEIGHT_UNITS map contains correct values', () {
      expect(AppConstants.WEIGHT_UNITS[Units.metric], 'kg');
      expect(AppConstants.WEIGHT_UNITS[Units.imperial], 'lbs');
      expect(AppConstants.WEIGHT_UNITS.length, 2);
    });

    test('DEFAULT_THEME is correct', () {
      expect(AppConstants.DEFAULT_THEME, 'dark');
    });

    test('DEFAULT_UNITS is correct', () {
      expect(AppConstants.DEFAULT_UNITS, Units.metric);
    });

    test('spacing and iOS metrics are defined correctly', () {
      expect(AppConstants.CARD_VERTICAL_GAP, 12.0);
      expect(AppConstants.SECTION_VERTICAL_GAP, 16.0);
      expect(AppConstants.ITEM_HORIZONTAL_GAP, 16.0);
      expect(AppConstants.SCROLL_HYSTERESIS_THRESHOLD, 150.0);
      expect(AppConstants.CARD_RADIUS, 12.0);
      expect(AppConstants.SHEET_RADIUS, 20.0);
      expect(AppConstants.HEADER_EXTRA_HEIGHT, 60.0);
      expect(AppConstants.PAGE_HORIZONTAL_PADDING, 16.0);
      expect(AppConstants.CARD_PADDING, 16.0);
      expect(AppConstants.GLASS_BLUR_SIGMA, 10.0);
      expect(AppConstants.CARD_STROKE_WIDTH, isNonZero);
      expect(AppConstants.HEADER_STROKE_WIDTH, isNonZero);
    });

    test('Button and action text constants are defined', () {
      expect(AppConstants.BACK_BUTTON_TOOLTIP, 'Back');
      expect(AppConstants.SELECT_EXERCISE_TITLE, 'Select Exercise');
      expect(AppConstants.DONE_BUTTON_TEXT, 'Done');
    });

    test('Animation and layout constants are defined correctly', () {
      expect(
        AppConstants.DRAG_ANIMATION_DURATION,
        const Duration(milliseconds: 200),
      );
      expect(AppConstants.DRAG_ANIMATION_CURVE, Curves.easeInOut);
      expect(AppConstants.PAGE_HORIZONTAL_PADDING, 16.0);
    });
  });

  group('Units', () {
    test('weightUnit returns correct values', () {
      expect(Units.metric.weightUnit, 'kg');
      expect(Units.imperial.weightUnit, 'lbs');
    });

    test('fromString returns correct values', () {
      expect(Units.fromString('metric'), Units.metric);
      expect(Units.fromString('imperial'), Units.imperial);
    });

    test('fromString returns default for invalid input', () {
      expect(Units.fromString('invalid'), Units.metric);
      expect(Units.fromString(''), Units.metric);
      expect(Units.fromString('Metric'), Units.metric);
    });

    test('all expected units are present', () {
      expect(Units.values, contains(Units.metric));
      expect(Units.values, contains(Units.imperial));
      expect(Units.values.length, 2);
    });
  });

  group('EquipmentType', () {
    test('fromString returns matching enum for valid display names', () {
      expect(EquipmentType.fromString('Barbell'), EquipmentType.barbell);
      expect(EquipmentType.fromString('Dumbbell'), EquipmentType.dumbbell);
      expect(EquipmentType.fromString('Cable'), EquipmentType.cable);
      expect(EquipmentType.fromString('Machine'), EquipmentType.machine);
      expect(EquipmentType.fromString('None'), EquipmentType.none);
    });

    test('fromString normalizes legacy dumbbell spelling and falls back', () {
      expect(EquipmentType.fromString('Dumbell'), EquipmentType.dumbbell);
      expect(EquipmentType.fromString('Unknown'), EquipmentType.none);
      expect(EquipmentType.fromString(''), EquipmentType.none);
    });

    test('all returns every equipment type in enum order', () {
      expect(EquipmentType.all, orderedEquals(EquipmentType.values));
      expect(
        EquipmentType.all.map((type) => type.displayName),
        orderedEquals(['Barbell', 'Dumbbell', 'Cable', 'Machine', 'None']),
      );
    });
  });

  group('AppMuscleGroup', () {
    test('fromString returns matching enum for known display names', () {
      expect(AppMuscleGroup.fromString('Chest'), AppMuscleGroup.chest);
      expect(
        AppMuscleGroup.fromString('Front Deltoids'),
        AppMuscleGroup.frontDeltoids,
      );
      expect(
        AppMuscleGroup.fromString('Rotator Cuffs'),
        AppMuscleGroup.rotatorCuff,
      );
      expect(AppMuscleGroup.fromString('NA'), AppMuscleGroup.na);
    });

    test('fromString falls back to na for unknown values', () {
      expect(AppMuscleGroup.fromString('Unknown'), AppMuscleGroup.na);
      expect(AppMuscleGroup.fromString(''), AppMuscleGroup.na);
      expect(AppMuscleGroup.fromString('chest'), AppMuscleGroup.na);
    });

    test('all returns every muscle group and unique display names', () {
      final groups = AppMuscleGroup.all;

      expect(groups, orderedEquals(AppMuscleGroup.values));
      expect(groups.length, AppMuscleGroup.values.length);
      expect(
        groups.map((group) => group.displayName).toSet().length,
        AppMuscleGroup.values.length,
      );
    });
  });

  group('WorkoutIconItem', () {
    test('icon item reports icon flags', () {
      const item = WorkoutIconItem(
        id: 'fitness_center',
        icon: Icons.fitness_center,
        name: 'Fitness',
      );

      expect(item.isIcon, isTrue);
      expect(item.isEmoji, isFalse);
      expect(item.icon, Icons.fitness_center);
      expect(item.emoji, isNull);
    });

    test('emoji item reports emoji flags', () {
      const item = WorkoutIconItem(id: 'muscle', emoji: '💪', name: 'Muscle');

      expect(item.isEmoji, isTrue);
      expect(item.isIcon, isFalse);
      expect(item.emoji, '💪');
      expect(item.icon, isNull);
    });

    test('constructor asserts when icon and emoji are both missing', () {
      expect(
        () => WorkoutIconItem(id: 'invalid', name: 'Invalid'),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('WorkoutIcons', () {
    test('items contain icon and emoji entries with unique ids', () {
      expect(WorkoutIcons.items, isNotEmpty);
      expect(WorkoutIcons.items.any((item) => item.isIcon), isTrue);
      expect(WorkoutIcons.items.any((item) => item.isEmoji), isTrue);
      expect(
        WorkoutIcons.items.map((item) => item.id).toSet().length,
        WorkoutIcons.items.length,
      );
    });

    test('defaultItem is the first configured icon', () {
      expect(WorkoutIcons.defaultItem, same(WorkoutIcons.items.first));
      expect(WorkoutIcons.defaultItem.id, 'fitness_center');
      expect(WorkoutIcons.defaultItem.icon, Icons.fitness_center);
    });

    test('findById returns a matching item or null when missing', () {
      expect(WorkoutIcons.findById('bolt')?.name, 'Power');
      expect(WorkoutIcons.findById('muscle')?.emoji, '💪');
      expect(WorkoutIcons.findById('missing-id'), isNull);
    });

    test('fromIconData returns matching item or default fallback', () {
      expect(WorkoutIcons.fromIconData(Icons.bolt).id, 'bolt');
      expect(
        WorkoutIcons.fromIconData(Icons.pool),
        same(WorkoutIcons.defaultItem),
      );
    });

    test(
      'fromCodePoint returns matching item and defaults for null or unknown',
      () {
        expect(
          WorkoutIcons.fromCodePoint(Icons.local_fire_department.codePoint).id,
          'local_fire_department',
        );
        expect(
          WorkoutIcons.fromCodePoint(null),
          same(WorkoutIcons.defaultItem),
        );
        expect(
          WorkoutIcons.fromCodePoint(Icons.pool.codePoint),
          same(WorkoutIcons.defaultItem),
        );
      },
    );

    test(
      'getIconDataFromCodePoint resolves configured, legacy, and fallback icons',
      () {
        expect(
          WorkoutIcons.getIconDataFromCodePoint(Icons.bolt.codePoint),
          Icons.bolt,
        );
        expect(
          WorkoutIcons.getIconDataFromCodePoint(0xe02f),
          Icons.directions_run,
        );
        expect(WorkoutIcons.getIconDataFromCodePoint(0xe047), Icons.pool);
        expect(
          WorkoutIcons.getIconDataFromCodePoint(null),
          Icons.fitness_center,
        );
        expect(WorkoutIcons.getIconDataFromCodePoint(-1), Icons.fitness_center);
      },
    );
  });
}
