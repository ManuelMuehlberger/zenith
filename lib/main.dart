import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'screens/home_screen.dart';
import 'screens/workout_builder_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/app_wrapper.dart';
import 'services/app_navigation_service.dart';
import 'services/exercise_service.dart';
import 'services/workout_service.dart';
import 'services/workout_session_service.dart';
import 'services/user_service.dart';
import 'services/live_workout_notification_service.dart';
import 'dart:ui';
import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up logging
  Logger.root.level = Level.INFO; // Set log level to INFO
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  final logger = Logger('ZenithApp');
  logger.info('Application startup initiated');
  
  // Load exercises, workouts, and active session on app startup
  await ExerciseService.instance.loadExercises();
  await WorkoutService.instance.loadData();
  await WorkoutSessionService.instance.loadActiveSession();
  await UserService.instance.loadUserProfile();
  logger.info('Core services initialized');
  
  logger.info('Initializing LiveWorkoutNotificationService...');
  await LiveWorkoutNotificationService().initialize(); 
  logger.info('LiveWorkoutNotificationService initialized.');
  
  WorkoutSessionService.instance.initializeNotificationCallback();
  
  logger.info('Starting application');
  runApp(const WorkoutTrackerApp());
}

class WorkoutTrackerApp extends StatelessWidget {
  const WorkoutTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Tracker',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          surface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardThemeData(
          color: Colors.grey[900],
          elevation: 2,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
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
    const WorkoutBuilderScreen(),
    const InsightsScreen(),
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
          body: IndexedStack(
            index: currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.BOTTOM_BAR_BG_COLOR,
                  border: Border(
                    top: BorderSide(color: AppConstants.HEADER_STROKE_COLOR, width: AppConstants.HEADER_STROKE_WIDTH),
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
