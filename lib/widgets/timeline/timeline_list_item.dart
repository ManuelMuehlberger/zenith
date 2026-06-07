import 'package:flutter/foundation.dart';

import '../../models/workout.dart';

// policy: no-test-needed immutable display item containers are exercised via timeline assembly tests.
sealed class TimelineListItem {
  const TimelineListItem();
}

class TimelineDayGroupItem extends TimelineListItem {
  final DateTime date;
  final List<Workout> workouts;

  const TimelineDayGroupItem({required this.date, required this.workouts});
}

@immutable
// policy: allow-public-api container for history navigation element.
class TimelineHistoryEndcapItem extends TimelineListItem {
  final int completedWorkoutCount;

  const TimelineHistoryEndcapItem({required this.completedWorkoutCount});
}
