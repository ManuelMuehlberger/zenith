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
              color: AppConstants.CARD_BG_COLOR,
              borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
              border: Border.all(
                color: AppConstants.CARD_STROKE_COLOR,
                width: AppConstants.CARD_STROKE_WIDTH,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.15).round()),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.CARD_PADDING), 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Workout icon with rounded modern styling
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: workout.color.withAlpha((255 * 0.15).round()),
                      borderRadius: BorderRadius.circular(26), // Fully rounded
                      border: Border.all(
                        color: workout.color.withAlpha((255 * 0.3).round()),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      workout.icon,
                      color: workout.color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppConstants.ITEM_HORIZONTAL_GAP), 
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
                        const SizedBox(height: 8),
                        // Stats row with modern pill styling
                        Row(
                          children: [
                            // Duration
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConstants.TEXT_TERTIARY_COLOR.withAlpha((255 * 0.1).round()),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 12,
                                    color: AppConstants.TEXT_SECONDARY_COLOR,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(workout.completedAt != null
                                        ? workout.completedAt!.difference(workout.startedAt ?? DateTime.now())
                                        : Duration.zero),
                                    style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Sets
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConstants.TEXT_TERTIARY_COLOR.withAlpha((255 * 0.1).round()),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.layers_outlined,
                                    size: 12,
                                    color: AppConstants.TEXT_SECONDARY_COLOR,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${workout.totalSets}',
                                    style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Weight (if available)
                            if (workout.exercises.fold(0.0, (sum, exercise) =>
                                    sum +
                                    exercise.sets.fold(
                                        0.0, (setSum, set) => setSum + (set.actualWeight ?? 0.0) * (set.actualReps ?? 0))) >
                                0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppConstants.ACCENT_COLOR.withAlpha((255 * 0.1).round()),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fitness_center_outlined,
                                      size: 12,
                                      color: AppConstants.ACCENT_COLOR,
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
                                        style: AppConstants.IOS_LABEL_TEXT_STYLE.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.ACCENT_COLOR,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if ((workout.notes ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppConstants.TEXT_TERTIARY_COLOR.withAlpha((255 * 0.08).round()),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppConstants.CARD_STROKE_COLOR,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.note_outlined,
                                  size: 14,
                                  color: AppConstants.TEXT_SECONDARY_COLOR,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    workout.notes ?? '',
                                    style: AppConstants.IOS_SUBTEXT_STYLE.copyWith(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Chevron icon without background
                  Icon(
                    Icons.chevron_right,
                    color: AppConstants.TEXT_SECONDARY_COLOR,
                    size: 20,
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
