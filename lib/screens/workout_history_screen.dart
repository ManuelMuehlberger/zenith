import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../models/workout.dart';
import '../services/user_service.dart';
import '../services/workout_achievement_service.dart';
import '../services/workout_service.dart';
import '../theme/app_theme.dart';
import '../utils/unit_converter.dart';
import '../widgets/timeline/timeline_row.dart';
import '../widgets/timeline/workout_achievement_awards.dart';
import '../widgets/timeline/workout_timeline_card.dart';
import 'workout_detail_screen.dart';

// policy: allow-public-api main history entry point.
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<_HistoryMonthKey> _expandedMonths = <_HistoryMonthKey>{};
  List<Workout> _workouts = const [];
  bool _isLoading = true;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    unawaited(_loadWorkouts());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
    });
    await WorkoutService.instance.loadData();
    if (!mounted) {
      return;
    }
    setState(() {
      _workouts = _completedWorkouts(WorkoutService.instance.workouts);
      _isLoading = false;
    });
  }

  Future<void> _openWorkoutDetail(Workout workout) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workout: workout),
      ),
    );

    if (deleted == true) {
      await _loadWorkouts();
    }
  }

  void _close() {
    Navigator.of(context).pop();
  }

  List<_HistoryMonthGroup> get _monthGroups {
    final groupsByMonth = <_HistoryMonthKey, List<Workout>>{};
    for (final workout in _workouts) {
      final timestamp = _timestampOf(workout);
      if (timestamp == null) {
        continue;
      }
      final key = _HistoryMonthKey(timestamp.year, timestamp.month);
      (groupsByMonth[key] ??= <Workout>[]).add(workout);
    }

    final keys = groupsByMonth.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final key in keys)
        _HistoryMonthGroup.fromWorkouts(key, groupsByMonth[key]!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;
    final groups = _monthGroups;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildHeaderSliver(context),
          if (_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(color: scheme.primary),
                ),
              ),
            )
          else if (groups.isEmpty)
            const SliverToBoxAdapter(child: _EmptyHistoryState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _buildHistoryItem(groups, index);
                }, childCount: _historyItemCount(groups)),
              ),
            ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeaderSliver(BuildContext context) {
    final headerSurface = Theme.of(context).scaffoldBackgroundColor;
    final transparentSurface = Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: 0);

    return SliverAppBar(
      pinned: true,
      stretch: true,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Center(
          child: IconButton(
            icon: Icon(CupertinoIcons.back, color: context.appScheme.onSurface),
            onPressed: _close,
          ),
        ),
      ),
      backgroundColor: transparentSurface,
      elevation: 0,
      expandedHeight: AppConstants.HEADER_EXTRA_HEIGHT + kToolbarHeight,
      actions: const [SizedBox(width: kToolbarHeight)],
      flexibleSpace: LayoutBuilder(
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: headerSurface.withValues(alpha: 0.98),
                ),
              ),
              FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'Workout History',
                  textAlign: TextAlign.center,
                  style: context.appText.titleLarge,
                ),
                background: ColoredBox(color: transparentSurface),
                collapseMode: CollapseMode.parallax,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(List<_HistoryMonthGroup> groups, int itemIndex) {
    if (itemIndex == _historyItemCount(groups) - 1) {
      return _HistoryEndcap(
        lineHighlightProgress: _timelineGlowForIndex(itemIndex),
      );
    }

    var cursor = 0;
    for (final group in groups) {
      final isExpanded = _expandedMonths.contains(group.key);
      if (itemIndex == cursor) {
        return _MonthTimelineRow(
          group: group,
          isExpanded: isExpanded,
          lineHighlightProgress: _timelineGlowForIndex(itemIndex),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedMonths.remove(group.key);
              } else {
                _expandedMonths.add(group.key);
              }
            });
          },
        );
      }
      cursor++;

      if (!isExpanded) {
        continue;
      }

      if (itemIndex == cursor) {
        return _TimelineConnectorRow(
          isOpen: true,
          lineHighlightProgress: _timelineGlowForIndex(itemIndex),
        );
      }
      cursor++;

      for (final workout in group.workouts) {
        if (itemIndex == cursor) {
          final animationDelay = (cursor * 45).clamp(0, 450).toInt();
          final achievements = buildWorkoutAchievementAwards(
            context,
            WorkoutAchievementService.resolveForWorkout(workout),
          );
          return GestureDetector(
            onTap: () => _openWorkoutDetail(workout),
            child: TimelineRow(
              timestamp: _timestampOf(workout) ?? group.key.startOfMonth,
              index: itemIndex,
              isNested: true,
              trackWidth: 86,
              contentStart: 66,
              nodeRadius: 9,
              animateLineColor: true,
              animationDelay: animationDelay,
              lineHighlightProgress: _timelineGlowForIndex(itemIndex),
              node: _WorkoutNode(workout: workout),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: WorkoutTimelineCard(
                  workout: workout,
                  primaryMetricsLabel: _primaryMetrics(workout),
                  achievements: achievements,
                  compact: true,
                ),
              ),
            ),
          );
        }
        cursor++;
      }

      if (itemIndex == cursor) {
        return _TimelineConnectorRow(
          isOpen: false,
          animationDelay: group.workouts.length * 45,
          lineHighlightProgress: _timelineGlowForIndex(itemIndex),
        );
      }
      cursor++;
    }

    return const SizedBox.shrink();
  }

  int _historyItemCount(List<_HistoryMonthGroup> groups) {
    var count = 1;
    for (final group in groups) {
      count++;
      if (_expandedMonths.contains(group.key)) {
        count += group.workouts.length + 2;
      }
    }
    return count;
  }

  double _timelineGlowForIndex(int itemIndex) {
    final progress = ((_scrollOffset - 40) / 220) - (itemIndex * 0.08);
    return progress.clamp(0.0, 1.0);
  }

  String _primaryMetrics(Workout workout) {
    final duration = _durationOf(workout);
    final durationText = _formatDuration(duration);
    final setsText = '${workout.totalSets} sets';
    if (workout.totalWeight > 0) {
      return '$durationText • $setsText • ${_formatWeight(workout.totalWeight)}';
    }
    return '$durationText • $setsText';
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) {
      return '0m';
    }

    var totalMinutes = duration.inMinutes;
    if (duration.inSeconds % 60 != 0) {
      totalMinutes += 1;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes}m';
  }

  String _formatWeight(double weight) {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    final unitLabel = UnitConverter.getWeightUnit(units.name);
    final kUnitLabel = units == Units.imperial ? 'k lbs' : 'k kg';

    if (weight.abs() > 999) {
      return '${(weight / 1000).toStringAsFixed(1)} $kUnitLabel';
    }
    return '${weight.toStringAsFixed(1)} $unitLabel';
  }
}

class _HistoryEndcap extends StatelessWidget {
  const _HistoryEndcap({required this.lineHighlightProgress});

  final double lineHighlightProgress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final endcapNodeColor = Color.lerp(
      colors.textTertiary,
      context.appScheme.onSurface,
      lineHighlightProgress.clamp(0.0, 1.0),
    )!;

    return TimelineRow(
      timestamp: DateTime.now(),
      index: 0,
      style: TimelineLineStyle.straight,
      isDotted: true,
      isLast: true,
      nodeRadius: 6,
      lineHighlightProgress: lineHighlightProgress,
      node: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: endcapNodeColor,
          shape: BoxShape.circle,
        ),
      ),
      child: const SizedBox(height: 34),
    );
  }
}

class _MonthTimelineRow extends StatelessWidget {
  const _MonthTimelineRow({
    required this.group,
    required this.isExpanded,
    required this.lineHighlightProgress,
    required this.onTap,
  });

  final _HistoryMonthGroup group;
  final bool isExpanded;
  final double lineHighlightProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = context.appScheme;
    final textTheme = context.appText;

    return TimelineRow(
      timestamp: group.key.startOfMonth,
      index: 0,
      style: TimelineLineStyle.straight,
      isExpandable: true,
      isExpanded: isExpanded,
      lineHighlightProgress: lineHighlightProgress,
      nodeRadius: 10,
      node: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isExpanded ? scheme.primary : colors.textTertiary,
          shape: BoxShape.circle,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppTheme.workoutCardBorderRadius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 10, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(group.key.label, style: textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Text(
                          _monthSubtitle(group),
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      color: colors.textSecondary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _monthSubtitle(_HistoryMonthGroup group) {
    final workoutText = group.workouts.length == 1
        ? '1 workout'
        : '${group.workouts.length} workouts';
    final hours = group.totalDuration.inMinutes / 60;
    return '$workoutText • ${hours.toStringAsFixed(1)} hrs';
  }
}

class _TimelineConnectorRow extends StatelessWidget {
  const _TimelineConnectorRow({
    required this.isOpen,
    required this.lineHighlightProgress,
    this.animationDelay = 0,
  });

  final bool isOpen;
  final double lineHighlightProgress;
  final int animationDelay;

  @override
  Widget build(BuildContext context) {
    return _DelayedAnimator(
      delay: animationDelay,
      builder: (context, value) {
        final dimColor = context.appScheme.onSurface.withValues(alpha: 0.3);
        final brightColor = context.appScheme.onSurface;
        final highlightedBaseColor = Color.lerp(
          dimColor,
          brightColor,
          lineHighlightProgress,
        )!;
        final color = Color.lerp(highlightedBaseColor, brightColor, value)!;

        return SizedBox(
          height: 18,
          child: CustomPaint(
            painter: _ConnectorPainter(
              isOpen: isOpen,
              startX: 23,
              endX: 43,
              color: color,
              isGradient: !isOpen,
              animationValue: value,
              dimColor: highlightedBaseColor,
              brightColor: brightColor,
            ),
          ),
        );
      },
    );
  }
}

class _DelayedAnimator extends StatefulWidget {
  const _DelayedAnimator({required this.delay, required this.builder});

  final int delay;
  final Widget Function(BuildContext context, double value) builder;

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
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

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
      builder: (context, child) => widget.builder(context, _animation.value),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.isOpen,
    required this.startX,
    required this.endX,
    required this.color,
    required this.dimColor,
    required this.brightColor,
    this.isGradient = false,
    this.animationValue = 0,
  });

  final bool isOpen;
  final double startX;
  final double endX;
  final Color color;
  final Color dimColor;
  final Color brightColor;
  final bool isGradient;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isGradient) {
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, dimColor],
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
        oldDelegate.dimColor != dimColor ||
        oldDelegate.brightColor != brightColor ||
        oldDelegate.isGradient != isGradient ||
        oldDelegate.animationValue != animationValue;
  }
}

class _WorkoutNode extends StatelessWidget {
  const _WorkoutNode({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: workout.color, shape: BoxShape.circle),
      child: Center(
        child: Icon(
          workout.icon,
          size: 12,
          color: context.appColors.overlayMedium,
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'No completed workouts yet',
          style: context.appText.bodyMedium,
        ),
      ),
    );
  }
}

class _HistoryMonthKey implements Comparable<_HistoryMonthKey> {
  const _HistoryMonthKey(this.year, this.month);

  final int year;
  final int month;

  DateTime get startOfMonth => DateTime(year, month);

  String get label => DateFormat('MMMM yyyy').format(startOfMonth);

  @override
  int compareTo(_HistoryMonthKey other) {
    if (year != other.year) {
      return year.compareTo(other.year);
    }
    return month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) {
    return other is _HistoryMonthKey &&
        year == other.year &&
        month == other.month;
  }

  @override
  int get hashCode => Object.hash(year, month);
}

class _HistoryMonthGroup {
  const _HistoryMonthGroup({
    required this.key,
    required this.workouts,
    required this.totalDuration,
  });

  final _HistoryMonthKey key;
  final List<Workout> workouts;
  final Duration totalDuration;

  factory _HistoryMonthGroup.fromWorkouts(
    _HistoryMonthKey key,
    List<Workout> workouts,
  ) {
    workouts.sort((a, b) => _timestampOf(b)!.compareTo(_timestampOf(a)!));
    return _HistoryMonthGroup(
      key: key,
      workouts: List<Workout>.unmodifiable(workouts),
      totalDuration: workouts.fold<Duration>(
        Duration.zero,
        (sum, workout) => sum + _durationOf(workout),
      ),
    );
  }
}

List<Workout> _completedWorkouts(List<Workout> workouts) {
  return workouts.where((workout) {
    return workout.status == WorkoutStatus.completed &&
        _timestampOf(workout) != null;
  }).toList()..sort((a, b) => _timestampOf(b)!.compareTo(_timestampOf(a)!));
}

DateTime? _timestampOf(Workout workout) =>
    workout.completedAt ?? workout.startedAt;

Duration _durationOf(Workout workout) {
  final startedAt = workout.startedAt;
  final completedAt = workout.completedAt;
  if (startedAt == null || completedAt == null) {
    return Duration.zero;
  }
  final duration = completedAt.difference(startedAt);
  if (duration.isNegative) {
    return Duration.zero;
  }
  return duration;
}
