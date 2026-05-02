import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/main.dart';
import 'package:zenith/services/app_navigation_service.dart';
import 'package:zenith/services/workout_session_service.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/utils/navigation_helper.dart';

void main() {
  setUp(() {
    AppNavigationService.instance.resetForTesting();
    WorkoutSessionService.instance.currentSession = null;
  });

  testWidgets('MainScreen floating dock uses the solid dock surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const MainScreen()),
    );
    await tester.pump();

    final scaffoldFinder = find.byType(Scaffold).first;
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.extendBody, isTrue);

    expect(find.byType(BottomBar), findsOneWidget);
    expect(find.byType(BottomBarItem), findsNWidgets(3));
    expect(find.byIcon(Icons.add_rounded), findsNothing);

    final decoratedWidgets = tester
        .widgetList(find.byType(DecoratedBox))
        .whereType<DecoratedBox>()
        .toList();
    final hasBottomBarTintContainer = decoratedWidgets.any((widget) {
      final decoration = widget.decoration;
      if (decoration is BoxDecoration) {
        return decoration.color == AppTheme.darkTokens.surfaceAlt;
      }
      return false;
    });
    expect(
      hasBottomBarTintContainer,
      isTrue,
      reason: 'Expected the floating dock to use the solid theme surface',
    );

    final dockTheme = Theme.of(
      tester.element(find.byType(BottomBar)),
    ).extension<BottomBarThemeData>();

    expect(dockTheme, isNotNull);
    expect(dockTheme!.layout?.respectSafeArea, isFalse);
    // The theme-level barDecoration is transparent; dock decoration lives in _MainDockSurface.
    expect(dockTheme.barDecoration?.color, AppThemeColors.clear);
    expect(dockTheme.barDecoration?.border, isNull);

    final items = tester.widgetList<BottomBarItem>(find.byType(BottomBarItem));
    for (final item in items) {
      expect(item.label, isNull);
    }
  });

  testWidgets('NavigationHelper switches tabs through AppNavigationService', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const MainScreen()),
    );
    await tester.pump();

    List<BottomBarItem> items = tester
        .widgetList<BottomBarItem>(find.byType(BottomBarItem))
        .toList();
    expect(items[0].selected, isTrue);
    expect(items[1].selected, isFalse);
    expect(find.byIcon(Icons.add_rounded), findsNothing);

    NavigationHelper.goToTab(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    items = tester
        .widgetList<BottomBarItem>(find.byType(BottomBarItem))
        .toList();
    expect(items[0].selected, isFalse);
    expect(items[1].selected, isTrue);
    expect(AppNavigationService.instance.currentTabIndex, 1);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    NavigationHelper.goToHomeTab();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    items = tester
        .widgetList<BottomBarItem>(find.byType(BottomBarItem))
        .toList();
    expect(items[0].selected, isTrue);
    expect(items[1].selected, isFalse);
    expect(AppNavigationService.instance.currentTabIndex, 0);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });
}
