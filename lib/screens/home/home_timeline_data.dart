import '../../models/workout.dart';
import '../../services/workout_timeline_grouping_service.dart';
import '../../widgets/timeline/timeline_list_item.dart';

class HomeTimelineData {
  final List<TimelineListItem> items;
  final List<MonthlyWorkoutGroup> archiveGroups;

  const HomeTimelineData({required this.items, required this.archiveGroups});
}

class HomeTimelineAssembler {
  static HomeTimelineData build(List<Workout> workouts) {
    final buckets = WorkoutTimelineGroupingService.splitWorkouts(workouts);
    final recentLimited = buckets.recent.take(10).toList();
    final items = <TimelineListItem>[];

    if (recentLimited.isNotEmpty) {
      DateTime? currentDay;
      List<Workout> currentGroup = [];

      for (final workout in recentLimited) {
        final date = workout.completedAt ?? workout.startedAt ?? DateTime.now();
        final day = DateTime(date.year, date.month, date.day);

        if (currentDay == null) {
          currentDay = day;
          currentGroup.add(workout);
          continue;
        }

        if (currentDay == day) {
          currentGroup.add(workout);
          continue;
        }

        items.add(
          TimelineDayGroupItem(
            date: currentDay,
            workouts: List<Workout>.from(currentGroup),
          ),
        );
        currentDay = day;
        currentGroup = [workout];
      }

      if (currentGroup.isNotEmpty && currentDay != null) {
        items.add(
          TimelineDayGroupItem(
            date: currentDay,
            workouts: List<Workout>.from(currentGroup),
          ),
        );
      }
    }

    final allCompletedWorkouts = workouts
        .where((workout) => workout.status == WorkoutStatus.completed)
        .toList();

    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);

    int currentMonthCount = 0;
    double currentMonthVolume = 0;
    int lastMonthCount = 0;
    double lastMonthVolume = 0;

    for (final workout in allCompletedWorkouts) {
      final date = workout.completedAt ?? workout.startedAt;
      if (date == null) {
        continue;
      }

      if (date.year == now.year && date.month == now.month) {
        currentMonthCount++;
        currentMonthVolume += workout.totalWeight;
      } else if (date.year == lastMonthDate.year &&
          date.month == lastMonthDate.month) {
        lastMonthCount++;
        lastMonthVolume += workout.totalWeight;
      }
    }

    if (recentLimited.isNotEmpty || buckets.archive.isNotEmpty) {
      items.add(
        TimelineMetricsItem(
          currentMonthWorkouts: currentMonthCount,
          currentMonthVolume: currentMonthVolume,
          lastMonthWorkouts: lastMonthCount,
          lastMonthVolume: lastMonthVolume,
        ),
      );
    }

    if (buckets.archive.isNotEmpty) {
      items.add(const TimelineFooterItem());
    }

    return HomeTimelineData(items: items, archiveGroups: buckets.archive);
  }
}
