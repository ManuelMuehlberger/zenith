import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/debug_settings_screen.dart';
import 'package:zenith/screens/settings_screen.dart';

void main() {
  testWidgets('renders empty state when no profile is loaded', (tester) async {
    expect(DebugSettingsScreen.isEnabled, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('No profile found'), findsOneWidget);
  });
}
