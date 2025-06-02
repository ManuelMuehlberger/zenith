import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout.dart';
import '../services/workout_session_service.dart';
import '../utils/navigation_helper.dart';

class ExpandableWorkoutCard extends StatefulWidget {
  final Workout workout;
  final VoidCallback onEditPressed;
  final VoidCallback onMorePressed;
  final int index;
  final VoidCallback? onDragStartedCallback;
  final VoidCallback? onDragEndCallback;

  const ExpandableWorkoutCard({
    super.key,
    required this.workout,
    required this.onEditPressed,
    required this.onMorePressed,
    required this.index,
    this.onDragStartedCallback,
    this.onDragEndCallback,
  });

  @override
  State<ExpandableWorkoutCard> createState() => _ExpandableWorkoutCardState();
}

class _ExpandableWorkoutCardState extends State<ExpandableWorkoutCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    HapticFeedback.lightImpact();
  }

  int _estimateWorkoutDuration(Workout workout) {
    // Estimate 2-3 minutes per set plus 1 minute per exercise for setup
    final totalSets = workout.totalSets;
    final exerciseCount = workout.exercises.length;
    return (totalSets * 3 + exerciseCount * 1).round();
  }

  Widget _buildWorkoutStat(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _startWorkout() async {
    try {
      await WorkoutSessionService.instance.startWorkout(widget.workout);
      HapticFeedback.mediumImpact();
      
      if (mounted) {
        // Navigate to the Workouts tab (index 1)
        // The WorkoutBuilderScreen on that tab will then display the ActiveWorkoutScreen
        NavigationHelper.goToTab(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start workout: $e'),
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

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Map<String, dynamic>>(
      key: ValueKey(widget.workout.id),
      data: {
        'workoutId': widget.workout.id,
        'index': widget.index,
        'type': 'workout',
      },
      delay: const Duration(milliseconds: 500),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
        widget.onDragStartedCallback?.call();
      },
      onDragEnd: (details) {
        widget.onDragEndCallback?.call();
      },
      feedback: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha((255 * 0.9).round()),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.workout.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workout.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.workout.exercises.length} exercise${widget.workout.exercises.length != 1 ? 's' : ''} • ${widget.workout.totalSets} sets',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.grey[800]?.withAlpha((255 * 0.5).round()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[700]!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.workout.name,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.workout.exercises.length} exercise${widget.workout.exercises.length != 1 ? 's' : ''} • ${widget.workout.totalSets} sets',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isExpanded ? Colors.blue.withAlpha((255 * 0.5).round()) : Colors.grey[800]!,
            width: _isExpanded ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggleExpansion,
            child: Column(
              children: [
                // Main card content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.workout.color.withAlpha((255 * 0.2).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.workout.icon,
                          color: widget.workout.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.workout.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.fitness_center_outlined,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.workout.exercises.length} ${widget.workout.exercises.length == 1 ? "exercise" : "exercises"}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.layers_outlined,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.workout.totalSets} ${widget.workout.totalSets == 1 ? "set" : "sets"}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onPressed: widget.onMorePressed,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Expandable content
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Workout stats
                          Text(
                            'Workout Details',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildWorkoutStat(
                                  '${widget.workout.exercises.length}',
                                  widget.workout.exercises.length == 1 ? 'exercise' : 'exercises',
                                ),
                              ),
                              Expanded(
                                child: _buildWorkoutStat(
                                  '${widget.workout.totalSets}',
                                  widget.workout.totalSets == 1 ? 'set' : 'sets',
                                ),
                              ),
                              Expanded(
                                child: _buildWorkoutStat(
                                  '~${_estimateWorkoutDuration(widget.workout)}',
                                  'min',
                                ),
                              ),
                            ],
                          ),
                          
                          // Exercise list preview
                          if (widget.workout.exercises.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Exercises',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...widget.workout.exercises.take(3).map((exercise) => 
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        exercise.exercise.name,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${exercise.sets.length} ${exercise.sets.length == 1 ? "set" : "sets"}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.workout.exercises.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '+${widget.workout.exercises.length - 3} more ${widget.workout.exercises.length - 3 == 1 ? "exercise" : "exercises"}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Start workout button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _startWorkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Start Workout',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
