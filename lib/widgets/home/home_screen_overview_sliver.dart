import 'package:flutter/material.dart';

import '../../models/workout.dart';
import '../../screens/home/home_timeline_data.dart';
import '../../theme/app_theme.dart';

// policy: no-test-needed covered by Home screen widget tests for the overview flow.
// policy: allow-public-api sliver consumed by the Home screen composition.
class HomeScreenOverviewSliver extends StatelessWidget {
  final HomeOverviewData overview;
  final Future<void> Function(Workout workout) onStartWorkout;
  final VoidCallback onOpenWorkoutBuilder;

  const HomeScreenOverviewSliver({
    super.key,
    required this.overview,
    required this.onStartWorkout,
    required this.onOpenWorkoutBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final templates = overview.suggestedWorkouts;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(label: 'Up Next'),
            const SizedBox(height: 10),
            _HorizontalRail(
              children: templates.isEmpty
                  ? [
                      _UpNextEmptyCard(
                        key: const ValueKey('home_up_next_empty_card'),
                        onOpenWorkoutBuilder: onOpenWorkoutBuilder,
                      ),
                    ]
                  : templates
                        .map(
                          (workout) => _UpNextWorkoutCard(
                            key: ValueKey('home_up_next_${workout.id}'),
                            workout: workout,
                            onStartWorkout: onStartWorkout,
                          ),
                        )
                        .toList(),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(label: 'My Consistency'),
            const SizedBox(height: 8),
            _ConsistencyRail(overview: overview),
          ],
        ),
      ),
    );
  }
}

// policy: allow-public-api sliver consumed by the Home screen composition.
class HomeScreenRecentActivityHeaderSliver extends StatelessWidget {
  const HomeScreenRecentActivityHeaderSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 16, 12),
        child: _SectionHeader(label: 'Recent Activity'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        label.toUpperCase(),
        style: context.appText.labelMedium?.copyWith(
          color: context.appColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HorizontalRail extends StatelessWidget {
  final List<Widget> children;

  const _HorizontalRail({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(width: 12),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _UpNextWorkoutCard extends StatelessWidget {
  final Workout workout;
  final Future<void> Function(Workout workout) onStartWorkout;

  const _UpNextWorkoutCard({
    super.key,
    required this.workout,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final colors = context.appColors;
    final textTheme = context.appText;
    final exerciseCount = workout.exercises.length;
    final setCount = workout.totalSets;

    return SizedBox(
      width: 304,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppTheme.workoutCardBorderRadius,
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: workout.color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(workout.icon, color: workout.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Suggested for today',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                workout.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _workoutDetail(
                  exerciseCount: exerciseCount,
                  setCount: setCount,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: () => onStartWorkout(workout),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('Start Workout'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _workoutDetail({required int exerciseCount, required int setCount}) {
    if (exerciseCount == 0 && setCount == 0) {
      return 'Ready when you are';
    }

    final exerciseLabel = exerciseCount == 1 ? 'exercise' : 'exercises';
    final setLabel = setCount == 1 ? 'set' : 'sets';
    return '$exerciseCount $exerciseLabel, $setCount $setLabel';
  }
}

class _UpNextEmptyCard extends StatelessWidget {
  final VoidCallback onOpenWorkoutBuilder;

  const _UpNextEmptyCard({super.key, required this.onOpenWorkoutBuilder});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;

    return SizedBox(
      width: 304,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppTheme.workoutCardBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 14),
              Text(
                'Build your next workout',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No routine queued yet.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onOpenWorkoutBuilder,
                  icon: const Icon(Icons.fitness_center_rounded, size: 18),
                  label: const Text('Open Builder'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsistencyRail extends StatefulWidget {
  final HomeOverviewData overview;

  const _ConsistencyRail({required this.overview});

  @override
  State<_ConsistencyRail> createState() => _ConsistencyRailState();
}

class _ConsistencyRailState extends State<_ConsistencyRail> {
  late final PageController _pageController;
  var _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _consistencyPages(widget.overview);

    return SizedBox(
      height: 126,
      child: Column(
        children: [
          SizedBox(
            height: 106,
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: pages
                  .map(
                    (page) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: page.child,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),
          _PageDots(currentPage: _currentPage, pageCount: pages.length),
        ],
      ),
    );
  }

  List<_ConsistencyPageSpec> _consistencyPages(HomeOverviewData overview) {
    return [
      _ConsistencyPageSpec(child: _WeekTrack(summary: overview.weekSummary)),
      _ConsistencyPageSpec(child: _MomentumPage(overview: overview)),
    ];
  }
}

class _ConsistencyPageSpec {
  final Widget child;

  const _ConsistencyPageSpec({required this.child});
}

class _PageDots extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _PageDots({required this.currentPage, required this.pageCount});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: isActive ? 16 : 6,
          height: 6,
          margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
          decoration: BoxDecoration(
            color: isActive ? colors.textTertiary : colors.field,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _MomentumPage extends StatelessWidget {
  final HomeOverviewData overview;

  const _MomentumPage({required this.overview});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 104,
      child: Row(
        children: [
          Expanded(
            child: _MomentumMetric(
              label: 'Weekly Streak',
              value: '${overview.weeklyStreak}',
              unit: overview.weeklyStreak == 1 ? 'week' : 'weeks',
              icon: Icons.repeat_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 54,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: colors.field,
          ),
          Expanded(child: _TrendMetric(trend: overview.durationTrend)),
        ],
      ),
    );
  }
}

class _WeekTrack extends StatelessWidget {
  final HomeWeekSummary summary;

  const _WeekTrack({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final colors = context.appColors;
    final textTheme = context.appText;

    return SizedBox(
      height: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly Streak',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  summary.workoutCount == 0
                      ? 'No sessions ${summary.weekLabel.toLowerCase()}'
                      : '${summary.workoutCount}/7 ${summary.weekLabel.toLowerCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 18,
                  right: 18,
                  top: 16,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: colors.field,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: summary.days.map((day) {
                    final isCompleted = day.hasWorkout;
                    return _WeekDayDot(
                      label: day.label,
                      isCompleted: isCompleted,
                      isToday: day.isToday,
                      completedColor: colorScheme.primary,
                      idleColor: colors.field,
                      textColor: isCompleted
                          ? colorScheme.onPrimary
                          : colors.textSecondary,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentumMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _MomentumMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final colors = context.appColors;
    final textTheme = context.appText;

    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorScheme.primary, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendMetric extends StatelessWidget {
  final HomeMetricTrend trend;

  const _TrendMetric({required this.trend});

  @override
  Widget build(BuildContext context) {
    final directionIcon = switch (trend.direction) {
      HomeTrendDirection.up => Icons.arrow_upward_rounded,
      HomeTrendDirection.down => Icons.arrow_downward_rounded,
      HomeTrendDirection.flat => Icons.trending_flat_rounded,
      HomeTrendDirection.none => Icons.remove_rounded,
    };
    final trendValue = trend.percentChange == null
        ? trend.value
        : '${trend.percentChange! > 0 ? '+' : '-'}${(trend.percentChange!.abs() * 100).round()}%';
    final trendUnit = trend.percentChange == null
        ? trend.comparisonLabel
        : 'vs avg';

    return _MomentumMetric(
      label: trend.label,
      value: trendValue,
      unit: trendUnit,
      icon: directionIcon,
    );
  }
}

class _WeekDayDot extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isToday;
  final Color completedColor;
  final Color idleColor;
  final Color textColor;

  const _WeekDayDot({
    required this.label,
    required this.isCompleted,
    required this.isToday,
    required this.completedColor,
    required this.idleColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? completedColor : idleColor,
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(color: completedColor, width: 2)
                : Border.all(color: idleColor, width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: context.appText.labelMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
