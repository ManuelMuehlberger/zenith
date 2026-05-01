import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/main.dart';
import 'package:zenith/services/app_navigation_service.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/utils/navigation_helper.dart';

void main() {
  setUp(() {
    AppNavigationService.instance.resetForTesting();
  });

  testWidgets('MainScreen bottom bar is glass and transparent', (tester) async {
    // Pump MainScreen inside a MaterialApp
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const MainScreen()),
    );
    // Avoid pumpAndSettle; app has timers/post-frame callbacks that never settle in tests
    await tester.pump();

    // Scaffold extendBody should be true (content extends behind the bar)
    final scaffoldFinder = find.byType(Scaffold).first;
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.extendBody, isTrue);

    // BackdropFilter should exist for the glass blur effect
    expect(find.byType(BackdropFilter), findsWidgets);

    // Container with the themed translucent overlay should exist.
    final containerWidgets = tester
        .widgetList(find.byType(Container))
        .whereType<Container>()
        .toList();
    final hasBottomBarTintContainer = containerWidgets.any((c) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration) {
        return decoration.color == AppTheme.darkTokens.overlaySoft;
      }
      return false;
    });
    expect(
      hasBottomBarTintContainer,
      isTrue,
      reason:
          'Expected a Container using the theme overlay tint for the bottom bar',
    );

    // BottomNavigationBar background should come from the transparent theme token.
    final barFinder = find.byType(BottomNavigationBar);
    expect(barFinder, findsOneWidget);
    final bar = tester.widget<BottomNavigationBar>(barFinder);
    expect(
      Theme.of(
        tester.element(barFinder),
      ).bottomNavigationBarTheme.backgroundColor,
      AppThemeColors.clear,
    );
    expect(bar.backgroundColor, isNull);
  });

  testWidgets('NavigationHelper switches tabs through AppNavigationService', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const MainScreen()),
    );
    await tester.pump();

    BottomNavigationBar bar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(bar.currentIndex, 0);

    NavigationHelper.goToTab(1);
    await tester.pump();

    bar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(bar.currentIndex, 1);
    expect(AppNavigationService.instance.currentTabIndex, 1);

    NavigationHelper.goToHomeTab();
    await tester.pump();

    bar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(bar.currentIndex, 0);
    expect(AppNavigationService.instance.currentTabIndex, 0);
  });
}
