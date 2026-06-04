import 'package:flutter/material.dart';
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

  testWidgets('MainScreen lightweight dock uses glass surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const MainScreen()),
    );
    await tester.pump();

    final scaffoldFinder = find.byType(Scaffold).first;
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.extendBody, isTrue);

    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.byTooltip('Workouts'), findsOneWidget);
    expect(find.byTooltip('Insights'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsNothing);

    final decoratedWidgets = tester
        .widgetList(find.byType(DecoratedBox))
        .whereType<DecoratedBox>()
        .toList();
    final hasDockFrame = decoratedWidgets.any((widget) {
      final decoration = widget.decoration;
      if (decoration is BoxDecoration) {
        return decoration.borderRadius == AppTheme.mainDockBorderRadius &&
            decoration.border != null &&
            decoration.boxShadow?.isNotEmpty == true;
      }
      return false;
    });
    final hasDockTintGradient = decoratedWidgets.any((widget) {
      final decoration = widget.decoration;
      if (decoration is BoxDecoration) {
        return decoration.gradient is LinearGradient;
      }
      return false;
    });
    expect(hasDockFrame, isTrue);
    expect(hasDockTintGradient, isTrue);
  });

  testWidgets('NavigationHelper switches tabs through AppNavigationService', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const MainScreen()),
    );
    await tester.pump();

    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center_outlined), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center_rounded), findsNothing);
    expect(find.byIcon(Icons.add_rounded), findsNothing);

    NavigationHelper.goToTab(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsNothing);
    expect(find.byIcon(Icons.fitness_center_rounded), findsOneWidget);
    expect(AppNavigationService.instance.currentTabIndex, 1);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNWidgets(2));

    NavigationHelper.goToHomeTab();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center_outlined), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center_rounded), findsNothing);
    expect(AppNavigationService.instance.currentTabIndex, 0);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });

  testWidgets('workout dock action fades between tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const MainScreen()),
    );
    await tester.pump();

    NavigationHelper.goToTab(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    final fadeInOpacity = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .map((widget) => widget.opacity)
        .where((opacity) => opacity > 0 && opacity < 1);
    expect(fadeInOpacity, isNotEmpty);

    await tester.pump(const Duration(milliseconds: 220));
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    NavigationHelper.goToHomeTab();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    final fadeOutOpacity = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .map((widget) => widget.opacity)
        .where((opacity) => opacity > 0 && opacity < 1);
    expect(fadeOutOpacity, isNotEmpty);

    await tester.pump(const Duration(milliseconds: 180));
    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });
}
