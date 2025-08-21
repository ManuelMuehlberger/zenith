import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/database_service.dart';
import '../models/workout.dart';
import 'settings_screen.dart';
import '../widgets/past_workout_list_item.dart';

class HomeScreen extends StatefulWidget {
  
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
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
      // Run migration to fix icon and color data for existing workouts
      await DatabaseService.instance.migrateWorkoutIcons();
      
      final history = await DatabaseService.instance.getWorkouts();
      if (mounted) {
        setState(() {
          _workoutHistory = history.take(10).toList(); 
          _isLoading = false;
        });
      }
    } catch (e) {
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
                                child: PastWorkoutListItem(workout: workout),
                              );
                            },
                            childCount: _workoutHistory.length,
                          ),
                        ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54.withOpacity(0.8),
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
                            const Expanded(
                              child: Text(
                                'Home',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
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
