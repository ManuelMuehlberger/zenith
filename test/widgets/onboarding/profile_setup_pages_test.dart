import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/onboarding/profile_setup_pages.dart';

void main() {
  group('GenderPage', () {
    testWidgets('reports the selected gender option', (tester) async {
      Gender? selectedGender;

      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: GenderPage(
              gender: Gender.ratherNotSay,
              onGenderChanged: (value) {
                selectedGender = value;
              },
              onNext: () {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();

      expect(selectedGender, Gender.male);
    });
  });
}
