import '../../models/workout.dart';
import '../../services/workout_timeline_grouping_service.dart';

// policy: no-test-needed immutable display item containers are exercised via timeline assembly tests.
sealed class TimelineListItem {
  const TimelineListItem();
}

class TimelineWorkoutItem extends TimelineListItem {
  final Workout workout;
  final bool isNested;
  final int animationDelay;

  const TimelineWorkoutItem({
    required this.workout,
    required this.isNested,
    this.animationDelay = 0,
  });
}

class TimelineDayGroupItem extends TimelineListItem {
  final DateTime date;
  final List<Workout> workouts;

  const TimelineDayGroupItem({required this.date, required this.workouts});
}

class TimelineMonthSummaryItem extends TimelineListItem {
  final MonthlyWorkoutGroup group;

  const TimelineMonthSummaryItem({required this.group});
}

class TimelineMetricsItem extends TimelineListItem {
  final int currentMonthWorkouts;
  final double currentMonthVolume;
  final int lastMonthWorkouts;
  final double lastMonthVolume;

  const TimelineMetricsItem({
    required this.currentMonthWorkouts,
    required this.currentMonthVolume,
    required this.lastMonthWorkouts,
    required this.lastMonthVolume,
  });
}

class TimelineFooterItem extends TimelineListItem {
  const TimelineFooterItem();
}

class TimelineHideHistoryItem extends TimelineListItem {
  const TimelineHideHistoryItem();
}

class TimelineArchiveHeaderItem extends TimelineListItem {
  const TimelineArchiveHeaderItem();
}

class TimelineMonthOpenItem extends TimelineListItem {
  final int animationDelay;
  const TimelineMonthOpenItem({this.animationDelay = 0});
}

class TimelineMonthCloseItem extends TimelineListItem {
  final int animationDelay;
  const TimelineMonthCloseItem({this.animationDelay = 0});
}

class TimelineEndcapItem extends TimelineListItem {
  const TimelineEndcapItem();
}

class TimelineYearItem extends TimelineListItem {
  final int year;
  const TimelineYearItem({required this.year});
}
