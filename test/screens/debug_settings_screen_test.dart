import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/debug_settings_screen.dart';

void main() {
  testWidgets('renders developer tools and danger zone sections', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DebugSettingsScreen()));
    await tester.pump();

    expect(find.text('Debug'), findsOneWidget);
    expect(find.text('Debug Menu'), findsOneWidget);
    expect(find.text('Generate History Data'), findsOneWidget);
    expect(find.text('Rebuild Workout Achievements'), findsOneWidget);
    expect(find.text('Danger Zone'), findsOneWidget);
    expect(find.text('Clear All Data'), findsOneWidget);
  });
}
