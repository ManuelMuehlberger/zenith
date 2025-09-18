import 'package:flutter/material.dart';
import 'dart:ui';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        loadWorkouts();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      final completed = WorkoutService.instance.workouts
          .where((w) => w.status == WorkoutStatus.completed)
          .toList();

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
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 60), // Combined height
              ),
              // Content
              _isLoading
                  ? SliverFillRemaining(
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue,
                        ),
                      ),
                    )
                  : _workoutHistory.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No workouts yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start by creating a workout in the Builder tab',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
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
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppConstants.HEADER_BG_COLOR_STRONG,
                  ),
                  child: Column(
                    children: [
                      // AppBar content
                      Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top,
                          left: 16,
                          right: 16,
                          bottom: 0,
                        ),
                        height: MediaQuery.of(context).padding.top + kToolbarHeight,
                        child: Row(
                          children: [
                            Expanded(
                              child: AnimatedBuilder(
                                animation: UserService.instance,
                                builder: (context, _) {
                                  final name = UserService.instance.currentProfile?.name.trim();
                                  final greeting = (name != null && name.isNotEmpty) ? 'Hey, $name!' : 'Hey!';
                                  return Text(
                                    greeting,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white, size: 28,),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // "Recent Workouts" section
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        width: double.infinity,
                        child: const Text(
                          'Recent Workouts',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
