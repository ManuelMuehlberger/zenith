import 'package:flutter/material.dart';
import '../screens/insights_screen.dart';

class ExpandableWorkoutList extends StatefulWidget {
  final DateTime selectedDate;
  final List<WorkoutHistoryDisplayItem> workoutDisplayItems; 
  final bool isExpanded;
  final VoidCallback onToggleExpansion;

  const ExpandableWorkoutList({
    super.key,
    required this.selectedDate,
    required this.workoutDisplayItems,
    required this.isExpanded,
    required this.onToggleExpansion,
  });

  @override
  State<ExpandableWorkoutList> createState() => _ExpandableWorkoutListState();
}

class _ExpandableWorkoutListState extends State<ExpandableWorkoutList> {

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.3).round()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Workouts on ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (widget.workoutDisplayItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${widget.workoutDisplayItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content section
          Expanded(
            child: widget.workoutDisplayItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No workouts on this date',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.workoutDisplayItems.length,
                    itemBuilder: (context, index) {
                      final displayItem = widget.workoutDisplayItems[index];
                      final workoutHistory = displayItem.history;
                      final workoutDetails = displayItem.workoutDetails;

                      final IconData iconData = workoutDetails?.icon ?? Icons.fitness_center;
                      final Color iconColor = workoutDetails?.color ?? Colors.blue;
                      
                      return Card(
                        color: Colors.grey[850],
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row with icon and workout name
                              Row(
                                children: [
                                  // Squircle background for icon
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: iconColor.withAlpha((255 * 0.2).round()),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: iconColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      workoutHistory.workoutName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Bottom row with stats
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(workoutHistory.duration),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.fitness_center,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${workoutHistory.exercises.length} exercise${workoutHistory.exercises.length != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.repeat,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${workoutHistory.totalSets} sets',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
