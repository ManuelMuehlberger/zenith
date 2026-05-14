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
      expect(find.text('74 kg'), findsOneWidget);
      expect(find.text('.2'), findsOneWidget);
    });

    test('gender defaults still map to onboarding starting weights', () {
      final metricSpec = WeightPickerWheelSpec.forUnits(Units.metric);

      expect(metricSpec.defaultWeight(gender: Gender.female), 60.0);
      expect(metricSpec.defaultWeight(gender: Gender.ratherNotSay), 60.0);
      expect(metricSpec.defaultWeight(gender: Gender.male), 75.0);
    });
  });
}
