import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/timeline_screen.dart';
import 'package:zenith/theme/app_theme.dart';

void main() {
  testWidgets('renders opaque header without backdrop blur', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const TimelineScreen()),
    );
    await tester.pump();

    expect(find.text('Development Timeline'), findsOneWidget);
    expect(find.text('Roadmap'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
