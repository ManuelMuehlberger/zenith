import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:logging/logging.dart';
import '../constants/app_constants.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../services/user_service.dart';
import 'settings_screen.dart';
import '../widgets/past_workout_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Logger _logger = Logger('HomeScreen');
  List<Workout> _workoutHistory = [];
  bool _isLoading = true;
  bool _showGreetingTitle = true;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        loadWorkouts();
      }
    });
    // Show greeting in the header for 2 seconds on startup, then switch to "Recent Workouts"
    _greetingTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _showGreetingTitle = false;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _greetingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadWorkouts();
    }
  }

  Future<void> loadWorkouts() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      _logger.info('Loading recent completed workouts for Home screen');

      // Load all data from DB into WorkoutService cache
      await WorkoutService.instance.loadData();
      _logger.fine('Loaded ${WorkoutService.instance.workouts.length} workouts from DB');

      // Filter for completed workouts only
      final completed = WorkoutService.instance.workouts.where((w) => w.status == WorkoutStatus.completed).toList();

      // Sort by completedAt desc (fallback to startedAt if needed)
      completed.sort((a, b) {
        final DateTime aTime = a.completedAt ?? a.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime = b.completedAt ?? b.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      final recent = completed.take(10).toList();
      _logger.fine('Found ${recent.length} recent completed workouts to display');

      if (mounted) {
        setState(() {
          _workoutHistory = recent;
          _isLoading = false;
        });
      }
      _logger.info('Recent workouts loaded successfully for Home screen');
    } catch (e) {
      _logger.severe('Failed to load recent workouts for Home screen: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle smallTitleStyle = AppConstants.HEADER_SMALL_TITLE_TEXT_STYLE;
    final TextStyle largeTitleStyle = AppConstants.HEADER_LARGE_TITLE_TEXT_STYLE;

    // The small title widget, used in the collapsed app bar
    final Widget smallTitle = AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, axisAlignment: -1.0, child: child),
      ),
      child: _showGreetingTitle
          ? AnimatedBuilder(
              key: const ValueKey('greeting_title'),
              animation: UserService.instance,
              builder: (context, _) {
                final name = UserService.instance.currentProfile?.name.trim();
                final greeting = (name != null && name.isNotEmpty) ? 'Hey, $name!' : 'Hey!';
                return Text(greeting, textAlign: TextAlign.center, style: smallTitleStyle);
              },
            )
          : Text(
              'Recent Workouts',
              key: const ValueKey('recent_title'),
              textAlign: TextAlign.center,
              style: smallTitleStyle,
            ),
    );

    // The large title widget, used in the expanded app bar background
    final Widget largeTitle = AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation),
      child: _showGreetingTitle
          ? AnimatedBuilder(
              key: const ValueKey('large_greeting_title'),
              animation: UserService.instance,
              builder: (context, _) {
                final name = UserService.instance.currentProfile?.name.trim();
                final greeting = (name != null && name.isNotEmpty) ? 'Hey, $name!' : 'Hey!';
                return Text(greeting, textAlign: TextAlign.center, style: largeTitleStyle);
              },
            )
          : Text(
              'Recent Workouts',
              key: const ValueKey('large_recent_title'),
              textAlign: TextAlign.center,
              style: largeTitleStyle,
            ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading: const SizedBox(width: kToolbarHeight),
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: AppConstants.HEADER_EXTRA_HEIGHT + kToolbarHeight,
            actions: [
              SizedBox(
                width: kToolbarHeight,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Persistent glass effect layer (covers expanded and collapsed states)
                    ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                          sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                        ),
                        child: Container(color: AppConstants.HEADER_BG_COLOR_STRONG),
                      ),
                    ),
                    // FlexibleSpaceBar handles title positioning and parallax of the large title
                    FlexibleSpaceBar(
                      centerTitle: true,
                      title: smallTitle,
                      background: Align(
                        alignment: Alignment.center,
                        child: largeTitle,
                      ),
                      collapseMode: CollapseMode.parallax,
                    ),
                  ],
                );
              },
            ),
          ),
          // Content
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                ),
              ),
            )
          else if (_workoutHistory.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No workouts yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start by creating a workout in the Builder tab',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final workout = _workoutHistory[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: PastWorkoutListItem(
                      workout: workout,
                      onDeleted: () {
                        // Refresh recent workouts after a deletion from detail screen
                        loadWorkouts();
                      },
                    ),
                  );
                },
                childCount: _workoutHistory.length,
              ),
            ),

          // Bottom spacer to avoid overlapping bottom navigation bar area
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
          ),
        ],
      ),
    );
  }
}
