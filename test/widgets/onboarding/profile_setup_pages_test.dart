import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/onboarding/profile_setup_pages.dart';
import 'package:zenith/widgets/weight_picker_wheel.dart';

void main() {
  group('NamePage', () {
    testWidgets('uses the shared card radius without an outer border', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Manu');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: NamePage(
              nameController: controller,
              nameFocusNode: focusNode,
              onNext: () {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      final decoration = field.decoration!;
      final borderRadius = decoration.borderRadius! as BorderRadius;

      expect(borderRadius, AppTheme.workoutCardBorderRadius);
      expect(decoration.border, isNull);
    });
  });

  group('GenderPage', () {
    testWidgets(
      'starts unselected and enables continue after choosing gender',
      (tester) async {
        Gender? selectedGender;

        tester.view.physicalSize = const Size(1200, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => GenderPage(
                  gender: selectedGender,
                  onGenderChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                  onNext: () {},
                  onBack: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Optional. Pick what fits your profile, or skip the detail.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Starts at'), findsNothing);
        expect(find.textContaining('weight'), findsNothing);
        final FilledButton initialContinue = tester.widget(
          find.widgetWithText(FilledButton, 'Continue'),
        );
        expect(initialContinue.onPressed, isNull);

        await tester.tap(find.text('Male'));
        await tester.pumpAndSettle();

        expect(selectedGender, Gender.male);
        final FilledButton enabledContinue = tester.widget(
          find.widgetWithText(FilledButton, 'Continue'),
        );
        expect(enabledContinue.onPressed, isNotNull);

        final option = tester.widget<AnimatedContainer>(
          find
              .byWidgetPredicate(
                (widget) =>
                    widget is AnimatedContainer &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration! as BoxDecoration).borderRadius ==
                        AppTheme.workoutCardBorderRadius,
              )
              .first,
        );
        final decoration = option.decoration! as BoxDecoration;
        expect(decoration.border, isNull);
      },
    );
  });

  group('UnitsPage', () {
    testWidgets('starts unselected and enables continue after choosing units', (
      tester,
    ) async {
      Units? selectedUnits;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => UnitsPage(
                units: selectedUnits,
                onUnitsChanged: (value) {
                  setState(() {
                    selectedUnits = value;
                  });
                },
                onNext: () {},
                onBack: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final FilledButton initialContinue = tester.widget(
        find.widgetWithText(FilledButton, 'Continue'),
      );
      expect(initialContinue.onPressed, isNull);

      await tester.tap(find.text('Metric'));
      await tester.pumpAndSettle();

      expect(selectedUnits, Units.metric);
      final FilledButton enabledContinue = tester.widget(
        find.widgetWithText(FilledButton, 'Continue'),
      );
      expect(enabledContinue.onPressed, isNotNull);

      final option = tester.widget<AnimatedContainer>(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is AnimatedContainer &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration! as BoxDecoration).borderRadius ==
                      AppTheme.workoutCardBorderRadius,
            )
            .first,
      );
      final decoration = option.decoration! as BoxDecoration;
      expect(decoration.border, isNull);
    });

    testWidgets('uses a lighter selected accent in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: UnitsPage(
              units: Units.metric,
              onUnitsChanged: (_) {},
              onNext: () {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final metricText = tester.widget<Text>(find.text('Metric'));
      expect(metricText.style?.color, AppThemeColors.dark.info);

      final selectedIcon = tester.widget<Icon>(
        find.byIcon(CupertinoIcons.check_mark_circled_solid),
      );
      expect(selectedIcon.color, AppThemeColors.dark.info);

      final option = tester.widget<AnimatedContainer>(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is AnimatedContainer &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration! as BoxDecoration).color ==
                      AppThemeColors.dark.info.withValues(alpha: 0.14),
            )
            .first,
      );
      expect(option, isNotNull);
    });
  });

  group('AgePage', () {
    testWidgets('uses the shared card radius without an outer border', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AgePage(
              age: 25,
              onAgeChanged: (_) {},
              onNext: () {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overlays = tester.widgetList<PickerSelectionOverlay>(
        find.byType(PickerSelectionOverlay),
      );
      final shell = tester.widget<Container>(
        find.descendant(
          of: find.byType(AgePage),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.constraints?.minHeight == 200 &&
                widget.decoration is BoxDecoration,
          ),
        ),
      );
      final decoration = shell.decoration! as BoxDecoration;
      final borderRadius = decoration.borderRadius! as BorderRadius;

      expect(overlays.length, 1);
      expect(overlays.first.radius, PickerSelectionStyle.emphasizedRadius);
      expect(borderRadius, AppTheme.workoutCardBorderRadius);
      expect(decoration.border, isNull);
    });
  });

  group('WeightPage', () {
    testWidgets('matches the shared card and selector radii without a border', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: WeightPage(
              weight: 74.0,
              units: Units.metric,
              onWeightChanged: (_) {},
              onNext: () {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.byKey(WeightPage.wrapperKey),
      );
      final decoration = container.decoration! as BoxDecoration;
      final borderRadius = decoration.borderRadius! as BorderRadius;

      expect(borderRadius, AppTheme.workoutCardBorderRadius);
      expect(decoration.border, isNull);

      final picker = tester.widget<WeightPickerWheel>(
        find.byType(WeightPickerWheel),
      );
      expect(
        picker.selectionOverlayRadius,
        PickerSelectionStyle.emphasizedRadius,
      );
    });
  });
}
