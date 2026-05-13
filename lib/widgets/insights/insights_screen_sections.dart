import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../constants/app_constants.dart';
import '../../screens/insights/insights_view_data.dart';
import '../../services/insights/workout_insights_provider.dart';
import '../../services/insights/weight_trend_provider.dart';
import '../../services/insights/workout_trend_provider.dart';
import '../../services/insights_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../dated_workout_list_view.dart';
import '../profile_icon_button.dart';
import '../shared_calendar_view.dart';
import '../workout_stats_card.dart';
import 'large_trend_card.dart';
import 'small_bar_card.dart';

class InsightsAppBar extends StatelessWidget {
  final bool showCalendar;
  final VoidCallback onShowCalendar;
  final VoidCallback onHideCalendar;

  const InsightsAppBar({
    super.key,
    required this.showCalendar,
    required this.onShowCalendar,
    required this.onHideCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final headerSurface = theme.scaffoldBackgroundColor;
    final smallTitleStyle = textTheme.titleLarge;
    final transparentSurface = theme.colorScheme.surface.withValues(alpha: 0);

    final smallTitle = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: showCalendar
          ? Text(
              'Calendar',
              key: const ValueKey('calendar_title'),
              textAlign: TextAlign.center,
              style: smallTitleStyle,
            )
          : Text(
              'Insights',
              key: const ValueKey('insights_title'),
              textAlign: TextAlign.center,
              style: smallTitleStyle,
            ),
    );

    return SliverAppBar(
      pinned: true,
      stretch: true,
      centerTitle: true,
      automaticallyImplyLeading: false,
      backgroundColor: transparentSurface,
      elevation: 0,
      expandedHeight: AppConstants.HEADER_EXTRA_HEIGHT + kToolbarHeight,
      leading: showCalendar
          ? IconButton(
              icon: Icon(
                CupertinoIcons.chevron_back,
                color: colorScheme.onSurface,
                size: 24,
              ),
              onPressed: onHideCalendar,
            )
          : GestureDetector(
              onTap: onShowCalendar,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.calendar,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
      actions: [
        if (!showCalendar)
          const ProfileIconButton()
        else
          const SizedBox(width: 48),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                    sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                  ),
                  child: ColoredBox(
                    color: headerSurface.withValues(alpha: 0.94),
                  ),
                ),
              ),
              FlexibleSpaceBar(
                centerTitle: true,
                title: smallTitle,
                background: Container(color: transparentSurface),
                collapseMode: CollapseMode.parallax,
              ),
            ],
          );
        },
      ),
    );
  }
}

class InsightsFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<InsightsTimeframeOption> timeframeOptions;
  final String selectedTimeframe;
  final String? selectedWorkoutName;
  final String? selectedMuscleGroup;
  final String? selectedEquipment;
  final bool? selectedBodyWeight;
  final List<String> availableWorkoutNames;
  final ValueChanged<String?> onWorkoutChanged;
  final ValueChanged<String?> onMuscleChanged;
  final ValueChanged<String?> onEquipmentChanged;
  final VoidCallback onBodyWeightChanged;
  final VoidCallback onClearAll;
  final void Function(String, int) onTimeframeChanged;

  InsightsFilterHeaderDelegate({
    required this.timeframeOptions,
    required this.selectedTimeframe,
    required this.selectedWorkoutName,
    required this.selectedMuscleGroup,
    required this.selectedEquipment,
    required this.selectedBodyWeight,
    required this.availableWorkoutNames,
    required this.onWorkoutChanged,
    required this.onMuscleChanged,
    required this.onEquipmentChanged,
    required this.onBodyWeightChanged,
    required this.onClearAll,
    required this.onTimeframeChanged,
  });

  @override
  double get minExtent => 52.0;

  @override
  double get maxExtent => 52.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = context.appScheme;
    final colors = context.appColors;
    final outlineColor = colorScheme.outline;
    final headerSurface = Theme.of(context).scaffoldBackgroundColor;
    final muscleGroups = AppMuscleGroup.values
        .where((group) => group != AppMuscleGroup.na)
        .map((group) => group.displayName)
        .toList();
    final equipmentList = EquipmentType.values
        .map((equipment) => equipment.displayName)
        .toList();
    final hasAnyFilter =
        selectedWorkoutName != null ||
        selectedMuscleGroup != null ||
        selectedEquipment != null ||
        selectedBodyWeight != null;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppConstants.GLASS_BLUR_SIGMA,
          sigmaY: AppConstants.GLASS_BLUR_SIGMA,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: headerSurface.withValues(alpha: 0.96),
            border: Border(bottom: BorderSide(color: outlineColor, width: 0.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (hasAnyFilter) ...[
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: onClearAll,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: outlineColor, width: 0.5),
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _InsightsFilterTag(
                      title: 'Workout',
                      isSelected: selectedWorkoutName != null,
                      items: availableWorkoutNames,
                      selectedItem: selectedWorkoutName,
                      onItemSelected: (value) => onWorkoutChanged(
                        value == selectedWorkoutName ? null : value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _InsightsFilterTag(
                      title: 'Muscle',
                      isSelected: selectedMuscleGroup != null,
                      items: muscleGroups,
                      selectedItem: selectedMuscleGroup,
                      onItemSelected: (value) => onMuscleChanged(
                        value == selectedMuscleGroup ? null : value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _InsightsFilterTag(
                      title: 'Equipment',
                      isSelected: selectedEquipment != null,
                      items: equipmentList,
                      selectedItem: selectedEquipment,
                      onItemSelected: (value) => onEquipmentChanged(
                        value == selectedEquipment ? null : value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _InsightsBodyweightTag(
                      isSelected: selectedBodyWeight == true,
                      onPressed: onBodyWeightChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _InsightsTimeframeDropdown(
                timeframeOptions: timeframeOptions,
                selectedTimeframe: selectedTimeframe,
                onTimeframeChanged: onTimeframeChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class InsightsGraphCardsGrid extends StatelessWidget {
  final InsightsFilterSnapshot filters;

  const InsightsGraphCardsGrid({super.key, required this.filters});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final providerFilters = filters.toProviderFilters();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12.0,
        crossAxisSpacing: 12.0,
        childAspectRatio: 1.0,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          WeeklyTrendCard(
            title: 'Workouts',
            icon: CupertinoIcons.flame_fill,
            color: context.appColors.warning,
            unit: 'workouts',
            provider: WorkoutTrendProvider(WorkoutTrendType.count),
            filters: providerFilters,
            timeframeMainValueBuilder: (data, timeframe) {
              if (data.isEmpty) return '0';

              final grouping = InsightsService.getGroupingForTimeframe(
                timeframe,
              );
              final total = data.fold(0.0, (sum, entry) => sum + entry.value);

              if (grouping == InsightsGrouping.day) {
                return total.toStringAsFixed(0);
              }

              return (total / data.length).toStringAsFixed(1);
            },
            timeframeSubLabelBuilder: (data, timeframe) {
              switch (InsightsService.getGroupingForTimeframe(timeframe)) {
                case InsightsGrouping.day:
                  return timeframe == '1W' ? 'This Week' : 'This Month';
                case InsightsGrouping.week:
                  return 'Avg / Week';
                case InsightsGrouping.month:
                  return 'Avg / Month';
              }
            },
          ),
          WeeklyTrendCard(
            title: 'Duration',
            icon: CupertinoIcons.clock_fill,
            color: colorScheme.primary,
            unit: 'min',
            provider: WorkoutTrendProvider(WorkoutTrendType.duration),
            filters: providerFilters,
            dailyBarValueBuilder: (point) => point.value * 60,
            mainValueBuilder: (data) {
              if (data.isEmpty) return '0m';
              double totalDurationMinutes = 0;
              int totalWorkouts = 0;
              for (final entry in data) {
                totalDurationMinutes += entry.value * 60;
                totalWorkouts += entry.count ?? 0;
              }
              if (totalWorkouts == 0) return '0m';
              return '${(totalDurationMinutes / totalWorkouts).toStringAsFixed(0)}m';
            },
            subLabelBuilder: (data) => 'Avg / Workout',
          ),
          WeeklyTrendCard(
            title: 'Volume',
            icon: CupertinoIcons.layers_fill,
            color: context.appColors.success,
            unit: 'sets',
            provider: WorkoutTrendProvider(WorkoutTrendType.sets),
            filters: providerFilters,
            dailyBarValueBuilder: (point) => point.value,
            mainValueBuilder: (data) {
              if (data.isEmpty) return '0';
              double totalSets = 0;
              int totalWorkouts = 0;
              for (final entry in data) {
                totalSets += entry.value;
                totalWorkouts += entry.count ?? 0;
              }
              if (totalWorkouts == 0) return '0';
              return (totalSets / totalWorkouts).toStringAsFixed(0);
            },
            subLabelBuilder: (data) => 'Avg Sets / Workout',
          ),
          WorkoutStatsCard(
            provider: WorkoutInsightsProvider(),
            filters: providerFilters,
          ),
        ],
      ),
    );
  }
}

class InsightsQuickActionsCard extends StatelessWidget {
  final VoidCallback onBrowseExercises;

  const InsightsQuickActionsCard({super.key, required this.onBrowseExercises});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: onBrowseExercises,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.search,
                  color: colors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Browse Exercises',
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.chevron_right,
                color: colors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InsightsTrendsSection extends StatelessWidget {
  final InsightsFilterSnapshot filters;
  final String weightUnitLabel;

  const InsightsTrendsSection({
    super.key,
    required this.filters,
    required this.weightUnitLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        final textTheme = context.appText;
        final colors = context.appColors;
        final providerFilters = filters.toProviderFilters();
        final weightFilters = {'timeframe': filters.timeframe};

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trends',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              TrendInsightCard(
                title: 'Workouts',
                color: colors.warning,
                unit: 'workouts',
                icon: CupertinoIcons.flame_fill,
                filters: providerFilters,
                provider: WorkoutTrendProvider(WorkoutTrendType.count),
              ),
              const SizedBox(height: 12),
              TrendInsightCard(
                title: 'Hours',
                color: context.appScheme.primary,
                unit: 'hours',
                icon: CupertinoIcons.clock_fill,
                filters: providerFilters,
                provider: WorkoutTrendProvider(WorkoutTrendType.duration),
              ),
              const SizedBox(height: 12),
              TrendInsightCard(
                title: 'Weight Lifted',
                color: colors.success,
                unit: weightUnitLabel,
                icon: CupertinoIcons.chart_bar_square_fill,
                filters: providerFilters,
                provider: WorkoutTrendProvider(WorkoutTrendType.volume),
              ),
              const SizedBox(height: 12),
              TrendInsightCard(
                title: 'Body Weight',
                color: colors.info,
                unit: weightUnitLabel,
                icon: Icons.monitor_weight_outlined,
                filters: weightFilters,
                provider: WeightTrendProvider(),
                showFiltersInDetail: false,
                mainValueBuilder: (data) {
                  final latestPoint = data.lastWhere(
                    (point) => point.count != null && point.count! > 0,
                    orElse: () =>
                        InsightDataPoint(date: DateTime.now(), value: 0),
                  );
                  return latestPoint.value.toStringAsFixed(1);
                },
                subLabelBuilder: (data) {
                  final hasData = data.any(
                    (point) => point.count != null && point.count! > 0,
                  );
                  return hasData ? 'Latest Entry' : '';
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class InsightsCalendarSlivers {
  static List<Widget> build({
    required bool isLoading,
    required DateTime selectedDate,
    required DateTime focusedDate,
    required List<DateTime> workoutDates,
    required List<WorkoutDisplayItem> selectedDateWorkoutItems,
    required ValueChanged<DateTime> onDateSelected,
    required ValueChanged<DateTime> onMonthChanged,
  }) {
    if (isLoading) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: CupertinoActivityIndicator(radius: 14)),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Builder(
          builder: (context) {
            final colorScheme = context.appScheme;

            return Container(
              margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.CARD_RADIUS),
                border: Border.all(color: colorScheme.outline, width: 0.5),
              ),
              child: SharedCalendarView(
                selectedDate: selectedDate,
                focusedDate: focusedDate,
                workoutDates: workoutDates,
                onDateSelected: onDateSelected,
                onMonthChanged: onMonthChanged,
              ),
            );
          },
        ),
      ),
      SliverFillRemaining(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: DatedWorkoutListView(
            selectedDate: selectedDate,
            workouts: selectedDateWorkoutItems
                .map((item) => item.workout)
                .toList(),
            isLoading: isLoading,
          ),
        ),
      ),
    ];
  }
}

class InsightsLoadingSliver extends StatelessWidget {
  const InsightsLoadingSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      ),
    );
  }
}

class InsightsEmptyStateSliver extends StatelessWidget {
  final Animation<double> fadeAnimation;

  const InsightsEmptyStateSliver({super.key, required this.fadeAnimation});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colorScheme = context.appScheme;
    final colors = context.appColors;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    CupertinoIcons.chart_bar_fill,
                    size: 40,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 24),
                Text('No Activity Data', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  'Complete workouts to see your insights',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightsFilterTag extends StatelessWidget {
  final String title;
  final bool isSelected;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String> onItemSelected;

  const _InsightsFilterTag({
    required this.title,
    required this.isSelected,
    required this.items,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final outlineColor = colorScheme.outline;

    return PullDownButton(
      itemBuilder: (context) => items
          .map(
            (item) => PullDownMenuItem.selectable(
              title: item,
              selected: selectedItem == item,
              onTap: () => onItemSelected(item),
            ),
          )
          .toList(),
      buttonBuilder: (context, showMenu) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: showMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isSelected ? colorScheme.primary : outlineColor,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSelected ? selectedItem! : title,
                style: textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_down,
                size: 12,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsBodyweightTag extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onPressed;

  const _InsightsBodyweightTag({
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final outlineColor = colorScheme.outline;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? colorScheme.primary : outlineColor,
            width: 0.5,
          ),
        ),
        child: Text(
          'Bodyweight',
          style: textTheme.bodyMedium?.copyWith(
            color: isSelected ? colorScheme.onPrimary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : null,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _InsightsTimeframeDropdown extends StatelessWidget {
  final List<InsightsTimeframeOption> timeframeOptions;
  final String selectedTimeframe;
  final void Function(String, int) onTimeframeChanged;

  const _InsightsTimeframeDropdown({
    required this.timeframeOptions,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final outlineColor = colorScheme.outline;

    return PullDownButton(
      itemBuilder: (context) => timeframeOptions
          .map(
            (option) => PullDownMenuItem.selectable(
              title: option.label,
              selected: selectedTimeframe == option.label,
              onTap: () => onTimeframeChanged(option.label, option.months),
            ),
          )
          .toList(),
      buttonBuilder: (context, showMenu) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: showMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: outlineColor, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedTimeframe,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_down,
                size: 16,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
