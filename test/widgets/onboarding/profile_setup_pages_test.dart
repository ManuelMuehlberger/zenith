import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/onboarding/profile_setup_pages.dart';
import 'package:zenith/widgets/weight_picker_wheel.dart';

void main() {
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
    });
  });

  group('AgePage', () {
    testWidgets('uses the larger selector radius', (tester) async {
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

      expect(overlays.length, 1);
      expect(overlays.first.radius, PickerSelectionStyle.emphasizedRadius);
    });
  });

  group('WeightPage', () {
    testWidgets('matches the larger onboarding card and selector radii', (
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

      expect(borderRadius.topLeft.x, AppConstants.SHEET_RADIUS);
      expect(borderRadius.topRight.x, AppConstants.SHEET_RADIUS);
      expect(borderRadius.bottomLeft.x, AppConstants.SHEET_RADIUS);
      expect(borderRadius.bottomRight.x, AppConstants.SHEET_RADIUS);

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
