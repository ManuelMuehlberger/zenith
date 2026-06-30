import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/exercise_browser_screen.dart';
import 'package:zenith/theme/app_theme.dart';

void main() {
  testWidgets('renders opaque header without backdrop blur', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ExerciseBrowserScreen()),
    );
    await tester.pump();

    expect(find.text('Exercise Statistics'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
