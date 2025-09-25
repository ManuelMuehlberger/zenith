import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../screens/workout_detail_screen.dart';
import '../services/user_service.dart';
import '../constants/app_constants.dart';

class PastWorkoutListItem extends StatelessWidget {
  final Workout workout;
  final VoidCallback? onDeleted;

  const PastWorkoutListItem({
    super.key,
    required this.workout,
    this.onDeleted,
  });

  String _formatWeight(double weight) {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    final isImperial = units == Units.imperial;
    final unitLabel = isImperial ? 'lbs' : 'kg';
    final kUnitLabel = isImperial ? 'k lbs' : 'kkg';

    if (weight > 999) {
      return '${(weight / 1000).toStringAsFixed(1)} $kUnitLabel';
    }
    return '${weight.toStringAsFixed(1)} $unitLabel';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final workoutDate = DateTime(date.year, date.month, date.day);

    if (workoutDate == today) {
      return 'Today';
    } else if (workoutDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailScreen(workout: workout),
              ),
            );
            if (result == true) {
              onDeleted?.call();
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppConstants.CARD_VERTICAL_GAP),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[800]!,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16), 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Workout icon 
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: workout.color.withAlpha((255 * 0.2).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      workout.icon, // Use workout icon or a default
                      color: workout.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16), 
                  // Workout details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                workout.name,
                                style: AppConstants.CARD_TITLE_TEXT_STYLE,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(workout.startedAt ?? DateTime.now()),
                              style: AppConstants.IOS_SUBTEXT_STYLE,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Subtext row (Duration, Sets, Weight)
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: AppConstants.TEXT_TERTIARY_COLOR,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(workout.completedAt != null
                                  ? workout.completedAt!.difference(workout.startedAt ?? DateTime.now())
                                  : Duration.zero),
                              style: AppConstants.IOS_SUBTEXT_STYLE,
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.layers_outlined,
                              size: 16,
                              color: AppConstants.TEXT_TERTIARY_COLOR,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${workout.totalSets} sets',
                              style: AppConstants.IOS_SUBTEXT_STYLE,
                            ),
                            if (workout.exercises.fold(0.0, (sum, exercise) =>
                                    sum +
                                    exercise.sets.fold(
                                        0.0, (setSum, set) => setSum + (set.actualWeight ?? 0.0) * (set.actualReps ?? 0))) >
                                0) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.fitness_center_outlined,
                                size: 16,
                                color: AppConstants.TEXT_TERTIARY_COLOR,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _formatWeight(workout.exercises.fold(
                                      0.0,
                                      (sum, exercise) =>
                                          sum +
                                          exercise.sets.fold(
                                              0.0,
                                              (setSum, set) =>
                                                  setSum + (set.actualWeight ?? 0.0) * (set.actualReps ?? 0)))),
                                  style: AppConstants.IOS_SUBTEXT_STYLE,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if ((workout.notes ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            workout.notes ?? '',
                            style: AppConstants.IOS_SUBTEXT_STYLE.copyWith(fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Chevron icon to indicate it's tappable
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[600], 
                    size: 24, 
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
