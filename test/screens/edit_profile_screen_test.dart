import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/screens/edit_profile_screen.dart';
import 'package:zenith/services/user_service.dart';
import 'package:zenith/theme/app_theme.dart';

void main() {
  group('EditProfileScreen', () {
    setUp(() {
      UserService.instance.currentProfileForTesting = UserData(
        id: 'user-1',
        name: 'Taylor',
        birthdate: DateTime(1994, 5, 1),
        gender: Gender.female,
        units: Units.metric,
        weightHistory: [
          WeightEntry(timestamp: DateTime(2026, 5, 1), value: 61.4),
        ],
        createdAt: DateTime(2026, 1, 1),
        theme: 'system',
      );
    });

    tearDown(() {
      UserService.instance.resetForTesting();
    });

    testWidgets('shows stored gender in the personal information section', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const EditProfileScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
    });
  });
}
