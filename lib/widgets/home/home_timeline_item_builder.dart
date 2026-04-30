import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../models/workout.dart';
import '../../services/user_service.dart';
import '../../services/workout_timeline_grouping_service.dart';
import '../timeline/archive_workout_row.dart';
import '../timeline/award_stack.dart';
import '../timeline/hide_history_trigger.dart';
import '../timeline/month_summary_card.dart';
import '../timeline/performance_metrics_card.dart';
import '../timeline/timeline_header_row.dart';
import '../timeline/timeline_list_item.dart';
import '../timeline/timeline_row.dart';
import '../timeline/workout_timeline_card.dart';

class HomeTimelineItemBuilder {
  final List<TimelineListItem> items;
  final Set<MonthKey> expandedMonths;
  final Future<void> Function(Workout workout) onOpenWorkout;
  final ValueChanged<MonthKey> onToggleMonth;
  final Future<void> Function() onHideArchive;

  const HomeTimelineItemBuilder({
    required this.items,
    required this.expandedMonths,
    required this.onOpenWorkout,
    required this.onToggleMonth,
    required this.onHideArchive,
  });

  Widget build(BuildContext context, TimelineListItem item, int index) {
    if (item is TimelineDayGroupItem) {
      final workouts = item.workouts;
      final firstWorkout = workouts.first;
      final timestamp = item.date;

      var isLastInBlock = false;
      if (index < items.length - 1) {
        final nextItem = items[index + 1];
        if (nextItem is TimelineMonthSummaryItem ||
            nextItem is TimelineArchiveHeaderItem) {
          isLastInBlock = true;
        }
      }

      final style =
          isLastInBlock ? TimelineLineStyle.curved : TimelineLineStyle.straight;

      final uniqueAwards = <String, Award>{};
      for (final workout in workouts) {
        for (final award in _awardsForWorkout(workout)) {
          uniqueAwards.putIfAbsent(award.title, () => award);
        }
      }

      return TimelineRow(
        timestamp: timestamp,
        index: index,
        isNested: false,
        style: style,
        nodeRadius: 9,
        node: _buildWorkoutNode(firstWorkout),
        child: TimelineHeaderRow(
          dateText: _relativeDayLabel(timestamp),
          awards: uniqueAwards.values.toList(),
          child: Column(
            children: workouts.map((workout) {
              final isLast = workout == workouts.last;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
                child: GestureDetector(
                  onTap: () => onOpenWorkout(workout),
                  child: WorkoutTimelineCard(
                    workout: workout,
                    primaryMetricsLabel: _primaryMetrics(workout),
                    compact: false,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    if (item is TimelineWorkoutItem) {
      final workout = item.workout;
      final timestamp =
          workout.completedAt ?? workout.startedAt ?? DateTime.now();

      if (item.isNested) {
        return GestureDetector(
          onTap: () => onOpenWorkout(workout),
          child: TimelineRow(
            timestamp: timestamp,
            index: index,
            isNested: true,
            style: TimelineLineStyle.straight,
            trackWidth: 86,
            nodeRadius: 9,
            animateLineColor: true,
            animationDelay: item.animationDelay,
            node: _buildWorkoutNode(workout),
            child: ArchiveWorkoutRow(workout: workout),
          ),
        );
      }

      return const SizedBox.shrink();
    }

    if (item is TimelineMonthSummaryItem) {
      final group = item.group;
      final timestamp = group.key.startOfMonth;
      final isExpanded = expandedMonths.contains(group.key);

      return TimelineRow(
        timestamp: timestamp,
        index: index,
        style: TimelineLineStyle.straight,
        nodeRadius: 11,
        node: TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            begin: Colors.grey[600]!,
            end: isExpanded ? Colors.white : Colors.grey[600]!,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          builder: (context, color, child) {
            return Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        isExpandable: true,
        isExpanded: isExpanded,
        child: MonthSummaryCard(
          group: group,
          isExpanded: isExpanded,
          onTap: () => onToggleMonth(group.key),
        ),
      );
    }

    if (item is TimelineMetricsItem) {
      return TimelineRow(
        timestamp: DateTime.now(),
        index: index,
        style: TimelineLineStyle.straight,
        node: const SizedBox.shrink(),
        nodeRadius: 0,
        child: PerformanceMetricsCard(
          currentMonthWorkouts: item.currentMonthWorkouts,
          currentMonthVolume: item.currentMonthVolume,
          lastMonthWorkouts: item.lastMonthWorkouts,
          lastMonthVolume: item.lastMonthVolume,
        ),
      );
    }

    if (item is TimelineHideHistoryItem) {
      return HideHistoryTrigger(onTrigger: onHideArchive);
    }

    if (item is TimelineArchiveHeaderItem) {
      return TimelineRow(
        timestamp: DateTime.now(),
        index: index,
        style: TimelineLineStyle.curved,
        node: const SizedBox.shrink(),
        child: const SizedBox(height: 32),
      );
    }

    if (item is TimelineMonthOpenItem) {
      return _DelayedAnimator(
        delay: item.animationDelay,
        builder: (context, value) {
          final color = Color.lerp(
            const Color(0xFFE5E5EA).withAlpha((255 * 0.3).round()),
            Colors.white,
            value,
          )!;
          return SizedBox(
            height: 16,
            child: CustomPaint(
              painter: _ConnectorPainter(
                isOpen: true,
                startX: 23,
                endX: 43,
                color: color,
              ),
            ),
          );
        },
      );
    }

    if (item is TimelineMonthCloseItem) {
      return _DelayedAnimator(
        delay: item.animationDelay,
        builder: (context, value) {
          return SizedBox(
            height: 16,
            child: CustomPaint(
              painter: _ConnectorPainter(
                isOpen: false,
                startX: 23,
                endX: 43,
                isGradient: true,
                animationValue: value,
              ),
            ),
          );
        },
      );
    }

    if (item is TimelineEndcapItem) {
      return TimelineRow(
        timestamp: DateTime.now(),
        index: index,
        style: TimelineLineStyle.straight,
        isLast: true,
        isDotted: true,
        node: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            shape: BoxShape.circle,
          ),
        ),
        nodeRadius: 6,
        child: const SizedBox(height: 32),
      );
    }

    if (item is TimelineYearItem) {
      return TimelineRow(
        timestamp: DateTime.now(),
        index: index,
        style: TimelineLineStyle.straight,
        isDotted: true,
        node: const SizedBox.shrink(),
        nodeRadius: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          alignment: Alignment.centerLeft,
          child: Text(
            item.year.toString(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _relativeDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (normalizedDate == today) {
      return 'Today';
    }
    if (normalizedDate == yesterday) {
      return 'Yesterday';
    }

    final diffDays = today.difference(normalizedDate).inDays;
    if (diffDays > 1 && diffDays < 7) {
      return '$diffDays days ago';
    }

    if (date.year != now.year) {
      return DateFormat('E, MMM d, y').format(date);
    }

    return DateFormat('E, MMM d').format(date);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  String _formatWeight(double weight) {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    final unitLabel = units == Units.imperial ? 'lbs' : 'kg';

    if (weight.abs() >= 1000) {
      return '${(weight / 1000).toStringAsFixed(1)}k $unitLabel';
    }

    return '${weight.toStringAsFixed(0)} $unitLabel';
  }

  String _primaryMetrics(Workout workout) {
    final started = workout.startedAt;
    final completed = workout.completedAt;
    final duration = (started != null && completed != null)
        ? completed.difference(started)
        : Duration.zero;

    final durationText = _formatDuration(duration);
    final setsText = '${workout.totalSets} sets';

    if (workout.totalWeight > 0) {
      final volumeText = _formatWeight(workout.totalWeight);
      return '$durationText • $setsText • $volumeText';
    }

    return '$durationText • $setsText';
  }

  List<Award> _awardsForWorkout(Workout workout) {
    final started = workout.startedAt;
    final completed = workout.completedAt;
    final duration = (started != null && completed != null)
        ? completed.difference(started)
        : Duration.zero;

    final awards = <Award>[];

    if (workout.totalSets >= 20) {
      awards.add(
        const Award(
          title: 'High Volume',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        ),
      );
    }

    if (duration.inMinutes >= 60) {
      awards.add(
        const Award(
          title: 'Long Session',
          icon: Icons.timer_outlined,
          color: Colors.lightBlue,
        ),
      );
    }

    if (workout.totalWeight >= 10000) {
      awards.add(
        const Award(
          title: 'Heavy',
          icon: Icons.fitness_center,
          color: Colors.green,
        ),
      );
    }

    if (awards.isEmpty) {
      awards.add(
        const Award(
          title: 'Completed',
          icon: Icons.check_circle,
          color: AppConstants.ACCENT_COLOR,
        ),
      );
    }

    return awards;
  }

  Widget _buildWorkoutNode(Workout workout) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: workout.color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          workout.icon,
          size: 12,
          color: Colors.black.withAlpha((255 * 0.7).round()),
        ),
      ),
    );
  }
}

class _DelayedAnimator extends StatefulWidget {
  final int delay;
  final Widget Function(BuildContext, double) builder;

  const _DelayedAnimator({
    required this.delay,
    required this.builder,
  });

  @override
  State<_DelayedAnimator> createState() => _DelayedAnimatorState();
}

class _DelayedAnimatorState extends State<_DelayedAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return widget.builder(context, _animation.value);
      },
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final bool isOpen;
  final double startX;
  final double endX;
  final Color color;
  final bool isGradient;
  final double animationValue;

  const _ConnectorPainter({
    required this.isOpen,
    required this.startX,
    required this.endX,
    this.color = Colors.white,
    this.isGradient = false,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isGradient) {
      final dimColor = const Color(0xFFE5E5EA).withAlpha((255 * 0.3).round());
      final topColor = Color.lerp(dimColor, Colors.white, animationValue)!;

      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, dimColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = color;
    }

    final path = Path();
    final midY = size.height / 2;
    const radius = 10.0;

    if (isOpen) {
      path.moveTo(startX, 0);
      path.lineTo(startX, midY - radius);
      path.quadraticBezierTo(startX, midY, startX + radius, midY);
      path.lineTo(endX - radius, midY);
      path.quadraticBezierTo(endX, midY, endX, midY + radius);
      path.lineTo(endX, size.height);
    } else {
      path.moveTo(endX, 0);
      path.lineTo(endX, midY - radius);
      path.quadraticBezierTo(endX, midY, endX - radius, midY);
      path.lineTo(startX + radius, midY);
      path.quadraticBezierTo(startX, midY, startX, midY + radius);
      path.lineTo(startX, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    return oldDelegate.isOpen != isOpen ||
        oldDelegate.startX != startX ||
        oldDelegate.endX != endX ||
        oldDelegate.color != color ||
        oldDelegate.isGradient != isGradient ||
        oldDelegate.animationValue != animationValue;
  }
}