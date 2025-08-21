import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout.dart';
import '../services/workout_session_service.dart';
import '../services/user_service.dart';
import '../utils/navigation_helper.dart';
import '../main.dart';
import 'package:confetti/confetti.dart';
import '../constants/app_constants.dart';

class WorkoutCompletionScreen extends StatefulWidget {
  final Workout session;

  const WorkoutCompletionScreen({
    super.key,
    required this.session,
  });

  @override
  State<WorkoutCompletionScreen> createState() => _WorkoutCompletionScreenState();
}

class _WorkoutCompletionScreenState extends State<WorkoutCompletionScreen> {
  final _notesController = TextEditingController();
  int? _selectedMood; // Using int for mood (1-5 scale)
  late ConfettiController _confettiController;
  final GlobalKey _finishButtonKey = GlobalKey();
  Offset? _confettiPosition;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                title: const Text(
                  'Complete Workout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.black,
                elevation: 0,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workout summary
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[800]!, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha((255 * 0.2).round()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.session.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Workout completed!',
                                      style: TextStyle(
                                        color: Colors.green[300],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSummaryItem(
                                WorkoutSessionService.instance.formatDuration(
                                  widget.session.completedAt != null 
                                      ? widget.session.completedAt!.difference(widget.session.startedAt ?? DateTime.now()) 
                                      : Duration.zero
                                ),
                                'Duration',
                                Icons.timer_outlined,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[800],
                              ),
                              _buildSummaryItem(
                                '${widget.session.completedSets}/${widget.session.totalSets}',
                                'Sets',
                                Icons.fitness_center_outlined,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[800],
                              ),
                              _buildSummaryItem(
                                '${WorkoutSessionService.instance.formatWeight(widget.session.totalWeight)} ${(UserService.instance.currentProfile?.units == Units.imperial) ? 'lbs' : 'kg'}',
                                'Weight',
                                Icons.monitor_weight_outlined,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How did the workout feel? Any observations?',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!, width: 1),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Optional notes...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'How are you feeling?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final moodValue = index + 1;
                        final isSelected = _selectedMood == moodValue;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedMood = moodValue;
                            });
                          },
                          child: Container(
                            width: 60,
                            height: 70,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.withAlpha((255 * 0.2).round()) : Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey[800]!,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getMoodEmoji(moodValue),
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getMoodDisplayName(moodValue),
                                  style: TextStyle(
                                    color: isSelected ? Colors.blue : Colors.grey[400],
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox( 
                            height: 50,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Back to Workout',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox( 
                            height: 50,
                            child: ElevatedButton(
                              key: _finishButtonKey, 
                              onPressed: _completeWorkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Finish',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ), 
            // Confetti overlay
            if (_confettiPosition != null)
              Positioned(
                left: _confettiPosition!.dx,
                top: _confettiPosition!.dy,
                child: SizedBox(
                  width: 1, 
                  height: 1,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive, 
                    emissionFrequency: 0.05, 
                    numberOfParticles: 30,  
                    gravity: 0.1,          
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple
                    ],
                  ),
                ),
              ),
          ], 
        );
      },
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Helper method to get emoji for mood (1-5 scale)
  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😔';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '😊';
    }
  }

  // Helper method to get display name for mood (1-5 scale)
  String _getMoodDisplayName(int mood) {
    switch (mood) {
      case 1:
        return 'Very Sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Very Happy';
      default:
        return 'Happy';
    }
  }

  Future<void> _completeWorkout() async { 
    try {
      await WorkoutSessionService.instance.completeWorkout(
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        mood: _selectedMood,
      );
      
      HapticFeedback.mediumImpact();
      
      Offset? buttonCenter;
      if (_finishButtonKey.currentContext != null) {
        final RenderBox renderBox = _finishButtonKey.currentContext!.findRenderObject() as RenderBox;
        buttonCenter = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
        if (mounted) {
          //_triggerConfetti();
        }
      }
      
      //custom circle reveal transition
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CircleRevealPageRoute(
            page: const MainScreen(),
            centerOffset: buttonCenter, // Pass the button center for the reveal
            transitionDuration: const Duration(milliseconds: 700),
          ),
          (Route<dynamic> route) => false, 
        );

        // Ensure home tab is selected after transition
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { 
             NavigationHelper.goToHomeTab(); 
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete workout: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}

// Custom PageRoute for Circle Reveal Transition
class CircleRevealPageRoute<T> extends PageRoute<T> {
  CircleRevealPageRoute({
    required this.page,
    this.centerOffset,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.reverseTransitionDuration = const Duration(milliseconds: 500),
  });

  final Widget page;
  final Offset? centerOffset;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ClipPath(
      clipper: CircleRevealClipper(
        fraction: animation.value,
        centerOffset: centerOffset,
      ),
      child: child,
    );
  }

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;
}

class CircleRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset? centerOffset;

  CircleRevealClipper({required this.fraction, this.centerOffset});

  @override
  Path getClip(Size size) {
    final center = centerOffset ?? Offset(size.width / 2, size.height / 2);
    final radius = sqrt(pow(size.width, 2) + pow(size.height, 2)) * fraction;

    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(CircleRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.centerOffset != centerOffset;
  }
}
