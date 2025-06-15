import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  final VoidCallback onMorePressed;
  final int index;

  const WorkoutCard({
    super.key,
    required this.workout,
    required this.onTap,
    required this.onMorePressed,
    required this.index,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Map<String, dynamic>>(
      key: ValueKey(workout.id),
      data: {
        'workoutId': workout.id,
        'index': index,
        'type': 'workout',
      },
      delay: const Duration(milliseconds: 500),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
      },
      feedback: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha((255 * 0.9).round()),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ListTile(
            leading: Icon(workout.icon, color: Colors.white, size: 32),
            title: Text(
              workout.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${workout.exercises.length} exercise${workout.exercises.length != 1 ? 's' : ''} • ${workout.totalSets} sets',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
      childWhenDragging: Card(
        color: Colors.grey[800]?.withAlpha((255 * 0.5).round()),
        margin: const EdgeInsets.only(bottom: 8.0),
        child: ListTile(
          leading: Icon(Icons.fitness_center, color: Colors.grey[600], size: 32),
          title: Text(
            workout.name,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${workout.exercises.length} exercise${workout.exercises.length != 1 ? 's' : ''} • ${workout.totalSets} sets',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
      child: Card(
        color: Colors.grey[900],
        margin: const EdgeInsets.only(bottom: 8.0),
        child: ListTile(
          leading: Icon(workout.icon, color: workout.color, size: 32),
          title: Text(
            workout.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 18
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${workout.exercises.length} exercise${workout.exercises.length != 1 ? 's' : ''} • ${workout.totalSets} sets',
                style: TextStyle(color: Colors.blue[300]),
              ),
              if (workout.lastUsed != null)
                Text(
                  'Last used: ${_formatDate(DateTime.parse(workout.lastUsed!))}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                )
              else
                Text(
                  'Last used: Never',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 24),
            onPressed: onMorePressed,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
