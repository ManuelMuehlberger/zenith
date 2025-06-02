import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/workout_builder_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/app_wrapper.dart';
import 'services/exercise_service.dart';
import 'services/workout_service.dart';
import 'services/workout_session_service.dart';
import 'services/user_service.dart';
import 'services/live_workout_notification_service.dart';
import 'utils/navigation_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load exercises, workouts, and active session on app startup
  await ExerciseService.instance.loadExercises();
  await WorkoutService.instance.loadData();
  await WorkoutSessionService.instance.loadActiveSession();
  await UserService.instance.loadUserProfile();
  debugPrint("[Main] Initializing LiveWorkoutNotificationService...");
  await LiveWorkoutNotificationService().initialize(); 
  debugPrint("[Main] LiveWorkoutNotificationService initialized.");
  
  WorkoutSessionService.instance.initializeNotificationCallback();
  
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
          backgroundColor: Colors.black.withOpacity(0.8), // "glass" background
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardTheme(
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
  int _currentIndex = 0;
  
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();
  List<Widget> get _screens => [
    HomeScreen(key: _homeScreenKey),
    const WorkoutBuilderScreen(),
    const InsightsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    
    NavigationHelper.registerHomeTabSwitcher(() {
      if (!mounted) return;

      if (_currentIndex != 0) {
        setState(() {
          _currentIndex = 0;
        });
      }
      // Refresh home screen history when switching to home tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _homeScreenKey.currentState != null) {
          _homeScreenKey.currentState!.loadWorkoutHistory();
        }
      });
    });

    NavigationHelper.registerTabSwitcher((index) {
      if (!mounted) return;

      if (_currentIndex != index) {
        setState(() {
          _currentIndex = index;
        });
      }
      // If switching to home tab (index 0), also refresh its history
      if (index == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _homeScreenKey.currentState != null) {
            _homeScreenKey.currentState!.loadWorkoutHistory();
          }
        });
      }
    });
    
    _checkForActiveWorkout();
  }

  @override
  void dispose() {
    NavigationHelper.unregisterSwitchers();
    super.dispose();
  }


  void _checkForActiveWorkout() {
    // If there's an active workout session, navigate to the workouts tab
    if (WorkoutSessionService.instance.hasActiveSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentIndex = 1; // Workouts tab
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
          if (index == 0 && _homeScreenKey.currentState != null) {
            _homeScreenKey.currentState!.loadWorkoutHistory();
          }
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
    );
  }
}
