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

    test('Card color constants are defined and correct', () {
      // Existing card color
      expect(AppConstants.CARD_BG_COLOR, const Color(0xFF212121));
      // New exercise card background color should match design (home cards)
      expect(AppConstants.EXERCISE_CARD_BG_COLOR, const Color(0xFF1A1A1A));
      // Stroke constants remain consistent
      expect(AppConstants.CARD_STROKE_WIDTH, isNonZero);
      expect(AppConstants.CARD_STROKE_COLOR, AppConstants.HEADER_STROKE_COLOR);
    });

    test('Button and action text constants are defined', () {
      expect(AppConstants.BACK_BUTTON_TOOLTIP, 'Back');
      expect(AppConstants.SELECT_EXERCISE_TITLE, 'Select Exercise');
      expect(AppConstants.DONE_BUTTON_TEXT, 'Done');
    });

    test('Header button text style is defined correctly', () {
      expect(AppConstants.HEADER_BUTTON_TEXT_STYLE.color, AppConstants.ACCENT_COLOR);
      expect(AppConstants.HEADER_BUTTON_TEXT_STYLE.fontSize, 16);
      expect(AppConstants.HEADER_BUTTON_TEXT_STYLE.fontWeight, FontWeight.w600);
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
      expect(Units.fromString('unknown'), Units.metric);
    });

    test('all expected units are present', () {
      expect(Units.values, contains(Units.metric));
      expect(Units.values, contains(Units.imperial));
      expect(Units.values.length, 2);
    });
  });
}
