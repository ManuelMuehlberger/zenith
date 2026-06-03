import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'screens/app_wrapper.dart';
import 'screens/create_workout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/workout_builder_screen.dart';
import 'services/app_navigation_service.dart';
import 'services/user_service.dart';
import 'services/workout_session_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  configureAppLogging(level: kDebugMode ? Level.FINE : Level.INFO);

  final logger = Logger('ZenithApp');
  logger.info('Starting application shell');
  runApp(const WorkoutTrackerApp());
}

class WorkoutTrackerApp extends StatelessWidget {
  const WorkoutTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        final preference = AppThemePreference.fromStorage(
          UserService.instance.currentProfile?.theme,
        );

        return MaterialApp(
          title: 'Workout Tracker',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: preference.themeMode,
          builder: (context, child) {
            final brightness = Theme.of(context).brightness;
            final overlayStyle = brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlayStyle,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AppWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const List<_MainDockDestination> _destinations = [
    _MainDockDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _MainDockDestination(
      label: 'Workouts',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center_rounded,
    ),
    _MainDockDestination(
      label: 'Insights',
      icon: Icons.insert_chart_outlined_rounded,
      selectedIcon: Icons.insert_chart_rounded,
    ),
  ];

  List<Widget> get _screens => const [
    HomeScreen(),
    WorkoutBuilderScreen(),
    InsightsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkForActiveWorkout();
  }

  void _checkForActiveWorkout() {
    // If there's an active workout session, navigate to the workouts tab
    if (WorkoutSessionService.instance.hasActiveSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppNavigationService.instance.goToTab(1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppNavigationService.instance,
      builder: (context, _) {
        final currentIndex = AppNavigationService.instance.currentTabIndex;

        return Scaffold(
          extendBody: true,
          body: IndexedStack(index: currentIndex, children: _screens),
          bottomNavigationBar: _MainLightweightDock(
            currentIndex: currentIndex,
            destinations: _destinations,
          ),
        );
      },
    );
  }
}

class _MainLightweightDock extends StatelessWidget {
  const _MainLightweightDock({
    required this.currentIndex,
    required this.destinations,
  });

  final int currentIndex;
  final List<_MainDockDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final showWorkoutAction = currentIndex == 1;
    final maxWidth = math.min(
      MediaQuery.sizeOf(context).width - (AppTheme.mainDockOffset * 2),
      AppTheme.mainDockMaxWidth,
    );
    final tabWidth = math.min(
      showWorkoutAction
          ? AppTheme.mainDockCompactWidth
          : AppTheme.mainDockPrimaryWidth,
      maxWidth,
    );
    final dockWidth = showWorkoutAction
        ? math.min(
            tabWidth + AppTheme.mainDockActionGap + AppTheme.mainDockActionSize,
            maxWidth,
          )
        : tabWidth;
    final fadeColor = context.appColors.dockEdgeFade;

    return SizedBox(
      height: safeBottom + AppTheme.mainDockClearance,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, AppTheme.mainDockEdgeFadeMidStop, 1],
                  colors: [
                    fadeColor.withValues(alpha: 0),
                    fadeColor.withValues(
                      alpha: AppTheme.mainDockEdgeFadeShoulderOpacity,
                    ),
                    fadeColor.withValues(
                      alpha: AppTheme.mainDockEdgeFadeBottomOpacity,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: AppTheme.mainDockOffset,
                right: AppTheme.mainDockOffset,
                bottom: safeBottom + AppTheme.mainDockOffset,
              ),
              child: SizedBox(
                width: dockWidth,
                height: AppTheme.mainDockHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: tabWidth,
                      height: AppTheme.mainDockHeight,
                      child: _MainDockSurface(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (
                              var index = 0;
                              index < destinations.length;
                              index++
                            )
                              _MainDockButton(
                                destination: destinations[index],
                                selected: index == currentIndex,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  AppNavigationService.instance.goToTab(index);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (showWorkoutAction) ...[
                      const SizedBox(width: AppTheme.mainDockActionGap),
                      _WorkoutDockAction(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CreateWorkoutScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainDockButton extends StatelessWidget {
  const _MainDockButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _MainDockDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.appScheme.primary
        : context.appColors.textSecondary;

    return Tooltip(
      message: destination.label,
      child: Material(
        color: context.appColors.surfaceAlt.withValues(alpha: 0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox.square(
            dimension: 48,
            child: Icon(
              selected ? destination.selectedIcon : destination.icon,
              color: color,
              size: selected
                  ? AppTheme.mainDockSelectedIconSize
                  : AppTheme.mainDockIconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _MainDockSurface extends StatelessWidget {
  const _MainDockSurface({required this.child, this.borderRadius});

  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolvedBorderRadius = borderRadius ?? AppTheme.mainDockBorderRadius;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.appScheme.primary;
    final baseGlassColor = context.appColors.surfaceAlt.withValues(
      alpha: isDark ? 0.68 : 0.8,
    );
    final tintedGlassColor = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.12 : 0.07),
      baseGlassColor,
    );
    final outlineColor = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.2 : 0.14),
      Theme.of(context).dividerColor,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: resolvedBorderRadius,
        border: Border.all(color: outlineColor, width: 0.75),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: resolvedBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(
                    context.appScheme.onSurface.withValues(
                      alpha: isDark ? 0.08 : 0.2,
                    ),
                    tintedGlassColor,
                  ),
                  tintedGlassColor,
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _WorkoutDockAction extends StatelessWidget {
  const _WorkoutDockAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppTheme.mainDockActionSize,
      child: _MainDockSurface(
        borderRadius: BorderRadius.circular(AppTheme.mainDockActionSize / 2),
        child: Material(
          color: context.appColors.surfaceAlt.withValues(alpha: 0),
          child: InkWell(
            onTap: onPressed,
            child: Icon(
              Icons.add_rounded,
              color: context.appScheme.primary,
              size: AppTheme.mainDockSelectedIconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _MainDockDestination {
  const _MainDockDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
