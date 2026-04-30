import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'constants/app_constants.dart';
import 'screens/app_wrapper.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/workout_builder_screen.dart';
import 'services/app_navigation_service.dart';
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
    return MaterialApp(
      title: 'Workout Tracker',
      theme: AppTheme.dark.copyWith(
        appBarTheme: AppTheme.dark.appBarTheme.copyWith(
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: const AppWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                sigmaY: AppConstants.GLASS_BLUR_SIGMA,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppConstants.BOTTOM_BAR_BG_COLOR,
                  border: Border(
                    top: BorderSide(
                      color: AppConstants.HEADER_STROKE_COLOR,
                      width: AppConstants.HEADER_STROKE_WIDTH,
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  currentIndex: currentIndex,
                  onTap: (index) {
                    HapticFeedback.selectionClick();
                    AppNavigationService.instance.goToTab(index);
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.fitness_center),
                      label: 'Workouts',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.analytics),
                      label: 'Insights',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
