import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/app_constants.dart';
import '../services/insights/workout_insights_provider.dart';
import '../models/insights.dart';
import '../utils/unit_converter.dart';
import '../services/user_service.dart';
import 'insights/insight_card.dart';

class WorkoutStatsCard extends StatefulWidget {
  final WorkoutInsightsProvider provider;
  final Map<String, dynamic> filters;

  const WorkoutStatsCard({
    super.key,
    required this.provider,
    required this.filters,
  });

  @override
  State<WorkoutStatsCard> createState() => _WorkoutStatsCardState();
}

class _WorkoutStatsCardState extends State<WorkoutStatsCard> {
  WorkoutInsights? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(WorkoutStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filters != oldWidget.filters) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    
    try {
      final timeframe = widget.filters['timeframe'] ?? '6M';
      final monthsBack = _getMonthsBack(timeframe);
      
      final data = await widget.provider.getData(
        timeframe: timeframe,
        monthsBack: monthsBack,
        filters: widget.filters,
      );
      
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _data = null;
          _isLoading = false;
        });
      }
    }
  }

  int _getMonthsBack(String timeframe) {
    switch (timeframe) {
      case '1W': return 1;
      case '1M': return 1;
      case '3M': return 3;
      case '6M': return 6;
      case '1Y': return 12;
      case '2Y': return 24;
      case 'All': return 999;
      default: return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _data == null) {
      final dummyData = WorkoutInsights(
        totalWorkouts: 0,
        totalHours: 0,
        totalWeight: 0,
        trendWorkouts: [],
        trendHours: [],
        trendWeight: [],
        averageWorkoutDuration: 0,
        averageWeightPerWorkout: 0,
        lastUpdated: DateTime.now(),
      );
      
      return InsightCard<WorkoutInsights>(
        title: 'Summary',
        icon: CupertinoIcons.chart_bar_square_fill,
        color: AppConstants.ACCENT_COLOR,
        unit: '',
        initialData: dummyData,
        isExpandable: false,
        collapsedContentBuilder: (data) => const Center(child: CupertinoActivityIndicator()),
      );
    }

    return InsightCard<WorkoutInsights>(
      title: 'Summary',
      icon: CupertinoIcons.chart_bar_square_fill,
      color: AppConstants.ACCENT_COLOR,
      unit: '',
      initialData: _data!,
      isExpandable: false,
      collapsedContentBuilder: (data) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem(
              value: data.totalWorkouts.toString(),
              label: 'Workouts',
              color: AppConstants.ACCENT_COLOR_ORANGE,
            ),
            const SizedBox(height: 4),
            _buildStatItem(
              value: '${(data.averageWorkoutDuration * 60).toStringAsFixed(0)}m',
              label: 'Avg Duration',
              color: AppConstants.ACCENT_COLOR,
            ),
            const SizedBox(height: 4),
            _buildStatItem(
              value: _formatWeight(data.averageWeightPerWorkout),
              label: 'Avg Weight',
              color: AppConstants.ACCENT_COLOR_GREEN,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.TEXT_TERTIARY_COLOR,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  String _formatWeight(double weight) {
    final units = UserService.instance.currentProfile?.units ?? Units.metric;
    final unitLabel = UnitConverter.getWeightUnit(units.name);
    final kUnitLabel = units == Units.imperial ? 'k lbs' : 'k kg';

    if (weight > 999) {
      return '${(weight / 1000).toStringAsFixed(1)}$kUnitLabel';
    }
    return '${weight.toStringAsFixed(0)} $unitLabel';
  }
}
