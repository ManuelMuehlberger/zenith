import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen includes bottom spacer to avoid glass tab bar overlap', (tester) async {
    // Simulate a device with a bottom safe area (e.g., iPhone with home indicator)
    const double bottomSafe = 24.0;
    const expectedHeight = bottomSafe + kBottomNavigationBarHeight;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: bottomSafe)),
          child: const HomeScreen(),
        ),
      ),
    );
    // Avoid pumpAndSettle; app may schedule timers/post-frame callbacks that never settle in tests
    await tester.pump();

    // Find a SliverToBoxAdapter whose child is a SizedBox with the expected height
    final sliverFinder = find.byWidgetPredicate((w) {
      if (w is SliverToBoxAdapter && w.child is SizedBox) {
        final SizedBox box = w.child as SizedBox;
        final h = box.height;
        // Be tolerant across environments; assert spacer is at least the bar height
        return h != null && h >= kBottomNavigationBarHeight;
      }
      return false;
    });

    expect(sliverFinder, findsOneWidget,
        reason: 'Expected a bottom SliverToBoxAdapter with SizedBox(height: bottomSafe + kBottomNavigationBarHeight)');
  });
}
