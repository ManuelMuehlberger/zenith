import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:logging/logging.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

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
        final dockWidth = math.min(
          MediaQuery.sizeOf(context).width - (AppTheme.mainDockOffset * 2),
          AppTheme.mainDockMaxWidth,
        );

        return Scaffold(
          extendBody: true,
          body: BottomBar(
            showIcon: false,
            layout: BottomBarLayout(width: dockWidth),
            body: _MainDockBody(currentIndex: currentIndex, screens: _screens),
            child: _MainFloatingDock(
              currentIndex: currentIndex,
              destinations: _destinations,
              maxWidth: dockWidth,
            ),
          ),
        );
      },
    );
  }
}

class _MainDockBody extends StatelessWidget {
  const _MainDockBody({required this.currentIndex, required this.screens});

  final int currentIndex;
  final List<Widget> screens;

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(index: currentIndex, children: screens);
    final blurHeight =
        AppTheme.mainDockEdgeBlurBaseHeight +
        MediaQuery.paddingOf(context).bottom;
    final fadeHeight =
        AppTheme.mainDockEdgeFadeBaseHeight +
        MediaQuery.paddingOf(context).bottom;
    final fadeColor = context.appColors.dockEdgeFade;

    return Stack(
      fit: StackFit.expand,
      children: [
        SoftEdgeBlur(
          edges: [
            EdgeBlur(
              type: EdgeType.bottomEdge,
              size: blurHeight,
              sigma: AppTheme.mainDockBlurSigma,
              tintColor: context.appColors.overlaySoft,
              controlPoints: [
                ControlPoint(
                  position: AppTheme.mainDockEdgeBlurVisibleStop,
                  type: ControlPointType.visible,
                ),
                ControlPoint(position: 1, type: ControlPointType.transparent),
              ],
            ),
          ],
          child: body,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: fadeHeight,
          child: IgnorePointer(
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
        ),
      ],
    );
  }
}

class _MainFloatingDock extends StatelessWidget {
  const _MainFloatingDock({
    required this.currentIndex,
    required this.destinations,
    required this.maxWidth,
  });

  final int currentIndex;
  final List<_MainDockDestination> destinations;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final showWorkoutAction = currentIndex == 1;
    final expandedWidth = math.min(AppTheme.mainDockPrimaryWidth, maxWidth);
    final compactWidth = math.min(
      AppTheme.mainDockCompactWidth,
      maxWidth - AppTheme.mainDockActionSize - AppTheme.mainDockActionGap,
    );

    return SizedBox(
      width: maxWidth,
      height: AppTheme.mainDockHeight,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: showWorkoutAction ? 1 : 0),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          final actionSlotWidth =
              (AppTheme.mainDockActionSize + AppTheme.mainDockActionGap) *
              progress;
          final dockWidth = lerpDouble(expandedWidth, compactWidth, progress)!;

          return Center(
            child: SizedBox(
              width: dockWidth + actionSlotWidth,
              height: AppTheme.mainDockHeight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: dockWidth,
                    height: AppTheme.mainDockHeight,
                    child: _MainDockSurface(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.mainDockItemPadding,
                          vertical: 10,
                        ),
                        child: BottomBarItems(
                          spacing: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (
                              var index = 0;
                              index < destinations.length;
                              index++
                            )
                              BottomBarItem(
                                selected: index == currentIndex,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  AppNavigationService.instance.goToTab(index);
                                },
                                tooltip: destinations[index].label,
                                icon: Icon(
                                  destinations[index].icon,
                                  size: AppTheme.mainDockIconSize,
                                ),
                                selectedIcon: Icon(
                                  destinations[index].selectedIcon,
                                  size: AppTheme.mainDockSelectedIconSize,
                                ),
                                color: context.appColors.textSecondary,
                                selectedColor: context.appScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: actionSlotWidth,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: progress <= 0
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(
                                  left: AppTheme.mainDockActionGap,
                                ),
                                child: IgnorePointer(
                                  ignoring: progress < 0.95,
                                  child: Opacity(
                                    opacity: progress,
                                    child: Transform.translate(
                                      offset: Offset((1 - progress) * 12, 0),
                                      child: _WorkoutDockAction(
                                        onPressed: () {
                                          HapticFeedback.mediumImpact();
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const CreateWorkoutScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MainDockSurface extends StatelessWidget {
  const _MainDockSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppTheme.mainDockBorderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.appColors.surfaceAlt,
          borderRadius: AppTheme.mainDockBorderRadius,
          border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow,
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _WorkoutDockAction extends StatelessWidget {
  const _WorkoutDockAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppTheme.mainDockActionSize,
      height: AppTheme.mainDockActionSize,
      child: _MainDockSurface(
        child: Material(
          color: Colors.transparent,
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
