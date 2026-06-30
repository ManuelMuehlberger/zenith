import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../screens/insights/insights_view_data.dart';
import '../../services/insights/weight_trend_provider.dart';
import '../../services/insights/workout_insights_provider.dart';
import '../../services/insights/workout_trend_provider.dart';
import '../../services/insights_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../app_bottom_sheet.dart';
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
              DecoratedBox(decoration: BoxDecoration(color: headerSurface)),
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

    return Container(
      decoration: BoxDecoration(color: headerSurface),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
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
                const SizedBox(width: 8),
              ],
            ),
          ),
          if (hasAnyFilter) ...[
            const SizedBox(width: 8),
            CupertinoButton(
              key: const Key('clear_all_button'),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onClearAll,
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 20,
                color: context.appScheme.primary,
              ),
            ),
          ],
          const SizedBox(width: 8),
          _InsightsTimeframeTag(
            timeframeOptions: timeframeOptions,
            selectedTimeframe: selectedTimeframe,
            onTimeframeChanged: onTimeframeChanged,
          ),
        ],
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
    final colors = context.appColors;
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
            color: colors.warning,
            unit: 'workouts',
            provider: WorkoutTrendProvider(WorkoutTrendType.count),
            filters: providerFilters,
            timeframeMainValueBuilder: _workoutAverageValue,
            timeframeSubLabelBuilder: _workoutAverageLabel,
          ),
          WeeklyTrendCard(
            title: 'Duration',
            icon: CupertinoIcons.clock_fill,
            color: colorScheme.primary,
            unit: 'min',
            provider: WorkoutTrendProvider(WorkoutTrendType.duration),
            filters: providerFilters,
            dailyBarValueBuilder: (point) => point.value * 60,
            mainValueBuilder: _averageDurationValue,
            subLabelBuilder: (data) => 'Avg / Workout',
          ),
          WeeklyTrendCard(
            title: 'Volume',
            icon: CupertinoIcons.layers_fill,
            color: colors.success,
            unit: 'sets',
            provider: WorkoutTrendProvider(WorkoutTrendType.sets),
            filters: providerFilters,
            dailyBarValueBuilder: (point) => point.value,
            mainValueBuilder: _averageSetsValue,
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

  static String _workoutAverageValue(
    List<InsightDataPoint> data,
    String timeframe,
  ) {
    if (data.isEmpty) return '0';

    final grouping = InsightsService.getGroupingForTimeframe(timeframe);
    final total = _sumValues(data);

    if (grouping == InsightsGrouping.day) {
      return total.toStringAsFixed(0);
    }

    return (total / data.length).toStringAsFixed(1);
  }

  static String _workoutAverageLabel(
    List<InsightDataPoint> data,
    String timeframe,
  ) {
    switch (InsightsService.getGroupingForTimeframe(timeframe)) {
      case InsightsGrouping.day:
        return timeframe == '1W' ? 'This Week' : 'This Month';
      case InsightsGrouping.week:
        return 'Avg / Week';
      case InsightsGrouping.month:
        return 'Avg / Month';
    }
  }

  static String _averageDurationValue(List<InsightDataPoint> data) {
    if (data.isEmpty) return '0m';
    var totalDurationMinutes = 0.0;
    var totalWorkouts = 0;
    for (final entry in data) {
      totalDurationMinutes += entry.value * 60;
      totalWorkouts += entry.count ?? 0;
    }
    if (totalWorkouts == 0) return '0m';
    return '${(totalDurationMinutes / totalWorkouts).toStringAsFixed(0)}m';
  }

  static String _averageSetsValue(List<InsightDataPoint> data) {
    if (data.isEmpty) return '0';
    var totalSets = 0.0;
    var totalWorkouts = 0;
    for (final entry in data) {
      totalSets += entry.value;
      totalWorkouts += entry.count ?? 0;
    }
    if (totalWorkouts == 0) return '0';
    return (totalSets / totalWorkouts).toStringAsFixed(0);
  }

  static double _sumValues(List<InsightDataPoint> data) {
    return data.fold(0.0, (sum, entry) => sum + entry.value);
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

  List<double> _buildWeightPreviewValues(List<InsightDataPoint> data) {
    final measuredValues = data
        .where((point) => (point.count ?? 0) > 0)
        .map((point) => point.value)
        .toList();
    if (measuredValues.isEmpty) {
      return data.map((_) => 0.0).toList();
    }

    var lastKnown = measuredValues.first;
    return data.map((point) {
      if ((point.count ?? 0) > 0) {
        lastKnown = point.value;
      }
      return lastKnown;
    }).toList();
  }

  double? _buildWeightPreviewMinY(
    List<InsightDataPoint> data,
    String unitLabel,
  ) {
    final values = _buildWeightPreviewValues(
      data,
    ).where((value) => value > 0).toList();
    if (values.isEmpty) {
      return null;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final halfSpan = math.max(
      unitLabel == 'kg' ? 4.0 : 9.0,
      (maxValue - minValue) * 2.5,
    );
    final center = (minValue + maxValue) / 2;
    return center - halfSpan;
  }

  double? _buildWeightPreviewMaxY(
    List<InsightDataPoint> data,
    String unitLabel,
  ) {
    final values = _buildWeightPreviewValues(
      data,
    ).where((value) => value > 0).toList();
    if (values.isEmpty) {
      return null;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final halfSpan = math.max(
      unitLabel == 'kg' ? 4.0 : 9.0,
      (maxValue - minValue) * 2.5,
    );
    final center = (minValue + maxValue) / 2;
    return center + halfSpan;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserService.instance,
      builder: _buildTrendsContent,
    );
  }

  Widget _buildTrendsContent(BuildContext context, Widget? child) {
    final textTheme = context.appText;
    final colors = context.appColors;

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
          ..._buildTrendCards(context),
        ],
      ),
    );
  }

  List<Widget> _buildTrendCards(BuildContext context) {
    final colors = context.appColors;
    final providerFilters = filters.toProviderFilters();

    return [
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
      _buildBodyWeightTrendCard(colors, {'timeframe': filters.timeframe}),
    ];
  }

  Widget _buildBodyWeightTrendCard(
    AppThemeTokens colors,
    Map<String, dynamic> weightFilters,
  ) {
    return TrendInsightCard(
      title: 'Body Weight',
      color: colors.info,
      unit: weightUnitLabel,
      icon: Icons.monitor_weight_outlined,
      filters: weightFilters,
      provider: WeightTrendProvider(),
      showFiltersInDetail: false,
      compactValuesBuilder: _buildWeightPreviewValues,
      compactMinYBuilder: (data) =>
          _buildWeightPreviewMinY(data, weightUnitLabel),
      compactMaxYBuilder: (data) =>
          _buildWeightPreviewMaxY(data, weightUnitLabel),
      mainValueBuilder: _buildBodyWeightMainValue,
      subLabelBuilder: _buildBodyWeightSubLabel,
    );
  }

  String _buildBodyWeightMainValue(List<InsightDataPoint> data) {
    final latestPoint = data.lastWhere(
      (point) => point.count != null && point.count! > 0,
      orElse: () => InsightDataPoint(date: DateTime.now(), value: 0),
    );
    return latestPoint.value.toStringAsFixed(1);
  }

  String _buildBodyWeightSubLabel(List<InsightDataPoint> data) {
    final hasData = data.any(
      (point) => point.count != null && point.count! > 0,
    );
    return hasData ? 'Latest Entry' : '';
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
    final textTheme = context.appText;
    final colors = context.appColors;
    final colorScheme = context.appScheme;

    return _InsightsHeaderTagButton(
      buttonKey: Key('${title.toLowerCase()}_filter_tag_button'),
      title: title,
      isSelected: isSelected,
      selectedLabel: selectedItem,
      onPressed: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: colors.transparent,
          elevation: 0,
          isDismissible: true,
          enableDrag: true,
          isScrollControlled: true,
          builder: (context) => _InsightsFilterSheet(
            title: title,
            eyebrow: title.toUpperCase(),
            description: 'Choose a ${title.toLowerCase()} filter for insights.',
            items: items,
            selectedItem: selectedItem,
            searchHint: title == 'Workout' ? 'Search workouts' : null,
            heightFactor: title == 'Workout' ? 0.58 : 0.5,
          ),
        );
        if (selected == null) return;
        onItemSelected(selected);
      },
      textStyle: textTheme.bodyMedium?.copyWith(
        color: isSelected ? colorScheme.primary : colors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      iconColor: isSelected ? colorScheme.primary : colors.textTertiary,
    );
  }
}

class _InsightsTimeframeTag extends StatelessWidget {
  final List<InsightsTimeframeOption> timeframeOptions;
  final String selectedTimeframe;
  final void Function(String, int) onTimeframeChanged;

  const _InsightsTimeframeTag({
    required this.timeframeOptions,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return _InsightsHeaderTagButton(
      buttonKey: const Key('time_filter_tag_button'),
      title: 'Time',
      isSelected: true,
      selectedLabel: selectedTimeframe,
      onPressed: () async {
        final selected = await showModalBottomSheet<InsightsTimeframeOption>(
          context: context,
          backgroundColor: colors.transparent,
          elevation: 0,
          isDismissible: true,
          enableDrag: true,
          isScrollControlled: true,
          builder: (context) => _InsightsTimeframeSheet(
            options: timeframeOptions,
            selectedLabel: selectedTimeframe,
          ),
        );
        if (selected == null) return;
        onTimeframeChanged(selected.label, selected.months);
      },
      textStyle: textTheme.bodyMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      iconColor: colors.textSecondary,
    );
  }
}

class _InsightsHeaderTagButton extends StatelessWidget {
  final Key buttonKey;
  final String title;
  final bool isSelected;
  final String? selectedLabel;
  final VoidCallback onPressed;
  final TextStyle? textStyle;
  final Color iconColor;

  const _InsightsHeaderTagButton({
    required this.buttonKey,
    required this.title,
    required this.isSelected,
    required this.selectedLabel,
    required this.onPressed,
    required this.textStyle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      key: buttonKey,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      onPressed: onPressed,
      minimumSize: Size.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isSelected ? selectedLabel! : title, style: textStyle),
          const SizedBox(width: 4),
          Icon(CupertinoIcons.chevron_down, size: 12, color: iconColor),
        ],
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
    final textTheme = context.appText;
    final colors = context.appColors;

    return CupertinoButton(
      key: const Key('bodyweight_filter_tag_button'),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      onPressed: onPressed,
      minimumSize: Size.zero,
      child: Text(
        'Bodyweight',
        style: textTheme.bodyMedium?.copyWith(
          color: isSelected ? context.appScheme.primary : colors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _InsightsFilterSheet extends StatefulWidget {
  final String title;
  final String eyebrow;
  final String description;
  final List<String> items;
  final String? selectedItem;
  final String? searchHint;
  final double heightFactor;

  const _InsightsFilterSheet({
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.items,
    required this.selectedItem,
    this.searchHint,
    required this.heightFactor,
  });

  @override
  State<_InsightsFilterSheet> createState() => _InsightsFilterSheetState();
}

class _InsightsFilterSheetState extends State<_InsightsFilterSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final query = _searchController.text.trim().toLowerCase();
    final filteredItems = widget.items.where((item) {
      return query.isEmpty || item.toLowerCase().contains(query);
    }).toList();

    return AppBottomSheet(
      height: MediaQuery.of(context).size.height * widget.heightFactor,
      child: Column(
        children: [
          const AppBottomSheetHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.eyebrow,
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.description, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              if (widget.selectedItem != null)
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(widget.selectedItem),
                  child: const Text('Clear'),
                ),
            ],
          ),
          if (widget.searchHint != null) ...[
            const SizedBox(height: 14),
            SearchBar(
              controller: _searchController,
              leading: const Padding(
                padding: EdgeInsetsDirectional.only(start: 4),
                child: Icon(Icons.search),
              ),
              hintText: widget.searchHint,
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                colors.field.withValues(alpha: 0.55),
              ),
              side: WidgetStatePropertyAll(
                BorderSide(color: colorScheme.outline.withValues(alpha: 0.16)),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == filteredItems.length - 1 ? 0 : 8,
                  ),
                  child: AppBottomSheetOptionTile(
                    key: Key(
                      '${widget.title.toLowerCase()}_filter_option_${item.toLowerCase().replaceAll(' ', '_')}',
                    ),
                    label: item,
                    selected: item == widget.selectedItem,
                    onTap: () => Navigator.of(context).pop(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsTimeframeSheet extends StatelessWidget {
  final List<InsightsTimeframeOption> options;
  final String selectedLabel;

  const _InsightsTimeframeSheet({
    required this.options,
    required this.selectedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return AppBottomSheet(
      maxHeight: MediaQuery.of(context).size.height * 0.46,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHandle(),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIMEFRAME',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how much history to use for the insights view.',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == options.length - 1 ? 0 : 8,
                  ),
                  child: AppBottomSheetOptionTile(
                    key: Key('timeframe_option_${option.label.toLowerCase()}'),
                    label: option.label,
                    selected: option.label == selectedLabel,
                    onTap: () => Navigator.of(context).pop(option),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
