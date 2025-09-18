import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/main.dart';
import 'package:zenith/constants/app_constants.dart';

void main() {
  testWidgets('MainScreen bottom bar is glass and transparent', (tester) async {
    // Pump MainScreen inside a MaterialApp
    await tester.pumpWidget(
      const MaterialApp(home: MainScreen()),
    );
    // Avoid pumpAndSettle; app has timers/post-frame callbacks that never settle in tests
    await tester.pump();

    // Scaffold extendBody should be true (content extends behind the bar)
    final scaffoldFinder = find.byType(Scaffold).first;
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.extendBody, isTrue);

    // BackdropFilter should exist for the glass blur effect
    expect(find.byType(BackdropFilter), findsWidgets);

    // Container with the BOTTOM_BAR_BG_COLOR (the translucent tint for bottom bar) should exist
    final containerWidgets = tester.widgetList(find.byType(Container)).whereType<Container>().toList();
    final hasBottomBarTintContainer = containerWidgets.any((c) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration) {
        return decoration.color == AppConstants.BOTTOM_BAR_BG_COLOR;
      }
      return false;
    });
    expect(hasBottomBarTintContainer, isTrue, reason: 'Expected a Container using AppConstants.BOTTOM_BAR_BG_COLOR as the bottom bar tint');

    // BottomNavigationBar background should be transparent
    final barFinder = find.byType(BottomNavigationBar);
    expect(barFinder, findsOneWidget);
    final bar = tester.widget<BottomNavigationBar>(barFinder);
    expect(bar.backgroundColor, equals(Colors.transparent));
  });
}
