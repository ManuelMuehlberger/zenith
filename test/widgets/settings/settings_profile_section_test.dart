import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/settings/settings_profile_section.dart';

void main() {
  group('SettingsProfileSection', () {
    testWidgets('shows the stored gender detail', (tester) async {
      final profile = UserData(
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SettingsProfileSection(
              userProfile: profile,
              onProfileUpdated: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
    });
  });
}
