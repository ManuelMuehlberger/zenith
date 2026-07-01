import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/weight_picker_wheel.dart';

void main() {
  group('WeightPickerWheel', () {
    testWidgets('renders whole and decimal wheels for finer precision', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: WeightPickerWheel(
              pickerKey: const Key('weight_picker'),
              weight: 74.2,
              units: Units.metric,
              onWeightChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weight_picker')), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(find.text('.2'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
      expect(find.text('.2 kg'), findsNothing);

      final columns = tester.widgetList<Expanded>(
        find.descendant(
          of: find.byKey(const Key('weight_picker')),
          matching: find.byType(Expanded),
        ),
      );
      expect(columns.map((column) => column.flex), [5, 5]);
    });

    test('gender defaults still map to onboarding starting weights', () {
      final metricSpec = WeightPickerWheelSpec.forUnits(Units.metric);

      expect(metricSpec.defaultWeight(gender: Gender.female), 60.0);
      expect(metricSpec.defaultWeight(gender: Gender.ratherNotSay), 60.0);
      expect(metricSpec.defaultWeight(gender: Gender.male), 75.0);
    });

    testWidgets('picker overlay does not tint selected text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: PickerSelectionOverlay(radius: 12)),
        ),
      );

      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = box.decoration as ShapeDecoration;

      expect(decoration.color, AppThemeColors.light.transparent);
    });

    testWidgets('picker selection background uses the previous fill color', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: PickerSelectionBackground(itemExtent: 50, radius: 12),
          ),
        ),
      );

      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = box.decoration as ShapeDecoration;

      expect(
        decoration.color,
        AppThemeColors.light.field.withValues(alpha: 0.68),
      );
    });

    testWidgets('picker text uses normal primary text color in light theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: WeightPickerWheel(
              weight: 74.2,
              units: Units.metric,
              onWeightChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('74').first);
      expect(text.style?.color, AppThemeColors.light.textPrimary);

      final pickerContext = tester.element(find.byType(CupertinoPicker).first);
      expect(
        CupertinoTheme.of(pickerContext).textTheme.pickerTextStyle.color,
        AppThemeColors.light.textPrimary,
      );
    });

    testWidgets('picker overlay stays transparent in dark theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: PickerSelectionOverlay(radius: 12)),
        ),
      );

      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = box.decoration as ShapeDecoration;

      expect(decoration.color, AppThemeColors.dark.transparent);
    });

    testWidgets('picker selection background uses the dark field fill color', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: PickerSelectionBackground(itemExtent: 50, radius: 12),
          ),
        ),
      );

      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = box.decoration as ShapeDecoration;

      expect(
        decoration.color,
        AppThemeColors.dark.field.withValues(alpha: 0.68),
      );
    });

    testWidgets('picker text uses normal primary text color in dark theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: WeightPickerWheel(
              weight: 74.2,
              units: Units.metric,
              onWeightChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('74').first);
      expect(text.style?.color, AppThemeColors.dark.textPrimary);

      final pickerContext = tester.element(find.byType(CupertinoPicker).first);
      expect(
        CupertinoTheme.of(pickerContext).textTheme.pickerTextStyle.color,
        AppThemeColors.dark.textPrimary,
      );
    });
  });

  group('DurationPickerWheel', () {
    testWidgets('renders hour and minute wheels for the selected duration', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DurationPickerWheel(
              pickerKey: const Key('duration_picker'),
              duration: const Duration(hours: 1, minutes: 12),
              onDurationChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('duration_picker')), findsOneWidget);
      expect(find.text('1 h'), findsNothing);
      expect(find.text('12 min'), findsNothing);
      expect(find.text('h'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
      expect(find.text('12'), findsWidgets);
    });

    testWidgets('clamps durations above the supported maximum', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DurationPickerWheel(
              duration: const Duration(hours: 18, minutes: 30),
              onDurationChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('12 h'), findsNothing);
      expect(find.text('59 min'), findsNothing);
      expect(find.text('h'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
      expect(find.text('59'), findsOneWidget);
    });

    testWidgets('emits changed duration values from both wheels', (
      tester,
    ) async {
      Duration? selectedDuration;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DurationPickerWheel(
              duration: const Duration(hours: 1, minutes: 12),
              onDurationChanged: (value) {
                selectedDuration = value;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pickers = find.byType(CupertinoPicker);

      await tester.drag(pickers.first, const Offset(0, -50));
      await tester.pumpAndSettle();
      expect(selectedDuration, const Duration(hours: 2, minutes: 12));

      await tester.drag(pickers.last, const Offset(0, -50));
      await tester.pumpAndSettle();
      expect(selectedDuration, const Duration(hours: 2, minutes: 13));
    });
  });
}
