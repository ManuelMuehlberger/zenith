import 'package:flutter/cupertino.dart';

import '../../models/weekly_bar_data.dart';
import '../../services/insights/insight_data_provider.dart';
import '../../services/insights_service.dart';
import 'insight_card.dart';
import 'simple_bar_chart.dart';

class WeeklyTrendCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String unit;
  final InsightDataProvider provider;
  final Map<String, dynamic> filters;
  final String Function(List<InsightDataPoint>)? mainValueBuilder;
  final String Function(List<InsightDataPoint>, String timeframe)?
  timeframeMainValueBuilder;
  final String Function(List<InsightDataPoint>)? subLabelBuilder;
  final String Function(List<InsightDataPoint>, String timeframe)?
  timeframeSubLabelBuilder;
  final double Function(InsightDataPoint point)? dailyBarValueBuilder;

  const WeeklyTrendCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.unit,
    required this.provider,
    required this.filters,
    this.mainValueBuilder,
    this.timeframeMainValueBuilder,
    this.subLabelBuilder,
    this.timeframeSubLabelBuilder,
    this.dailyBarValueBuilder,
  });

  @override
  State<WeeklyTrendCard> createState() => _WeeklyTrendCardState();
}

class _WeeklyTrendCardState extends State<WeeklyTrendCard> {
  List<InsightDataPoint> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(WeeklyTrendCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filters != oldWidget.filters) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

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
          if (timeframe == 'All') {
            _data = _trimData(data);
          } else {
            _data = data;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _data = [];
          _isLoading = false;
        });
      }
    }
  }

  int _getMonthsBack(String timeframe) {
    switch (timeframe) {
      case '1W':
        return 1;
      case '1M':
        return 1;
      case '3M':
        return 3;
      case '6M':
        return 6;
      case '1Y':
        return 12;
      case '2Y':
        return 24;
      case 'All':
        return 999;
      default:
        return 6;
    }
  }

  List<InsightDataPoint> _trimData(List<InsightDataPoint> data) {
    int firstDataIndex = -1;
    final count = data.length;

    for (int i = 0; i < count; i++) {
      final hasData = data[i].value > 0 || (data[i].maxValue ?? 0) > 0;
      if (hasData) {
        firstDataIndex = i;
        break;
      }
    }

    if (firstDataIndex == -1) {
      const keepCount = 6;
      if (count <= keepCount) return data;
      return data.sublist(count - keepCount);
    }

    const padding = 2;
    final startIndex = (firstDataIndex - padding).clamp(0, count);

    if (startIndex == 0) return data;
    return data.sublist(startIndex);
  }

  @override
  Widget build(BuildContext context) {
    return InsightCard<List<InsightDataPoint>>(
      title: widget.title,
      icon: widget.icon,
      color: widget.color,
      unit: widget.unit,
      initialData: _data,
      initialFilters: widget.filters,
      heroTag: 'weekly_${widget.title}',
      dataFetcher: (timeframe, monthsBack, filters) async {
        final data = await widget.provider.getData(
          timeframe: timeframe,
          monthsBack: monthsBack,
          filters: filters,
        );
        return timeframe == 'All' ? _trimData(data) : data;
      },
      timeframeMainValueBuilder: widget.timeframeMainValueBuilder,
      mainValueBuilder:
          widget.mainValueBuilder ??
          (data) {
            if (data.isEmpty) return "0";
            final average =
                data.map((e) => e.value).reduce((a, b) => a + b) / data.length;
            return average.toStringAsFixed(1);
          },
      timeframeSubLabelBuilder: widget.timeframeSubLabelBuilder,
      subLabelBuilder: widget.subLabelBuilder ?? (data) => "Avg / Week",
      collapsedContentBuilder: (data) {
        if (_isLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }
        final timeframe = widget.filters['timeframe'] ?? '6M';
        final grouping = InsightsService.getGroupingForTimeframe(timeframe);
        final weeklyData = _prepareChartData(data, grouping);
        final maxY = _calculateMaxY(weeklyData);

        return SimpleBarChart(
          weeklyData: weeklyData,
          maxYValue: maxY,
          color: widget.color,
          showTitles: false,
          showGrid: false,
          showBorder: false,
          grouping: grouping,
        );
      },
      expandedContentBuilder: (context, data, timeframe, months) {
        final grouping = InsightsService.getGroupingForTimeframe(timeframe);
        final weeklyData = _prepareChartData(data, grouping);
        final maxY = _calculateMaxY(weeklyData);

        return SimpleBarChart(
          weeklyData: weeklyData,
          maxYValue: maxY,
          color: widget.color,
          showTitles: false,
          showGrid: true,
          showBorder: false,
          touchEnabled: true,
          barWidth: _getBarWidth(timeframe),
          grouping: grouping,
        );
      },
      axisBuilder: (context, data, timeframe, months) {
        final grouping = InsightsService.getGroupingForTimeframe(timeframe);
        final weeklyData = _prepareChartData(data, grouping);
        final maxY = _calculateMaxY(weeklyData);

        return SimpleBarChart(
          weeklyData: weeklyData,
          maxYValue: maxY,
          color: widget.color,
          onlyAxis: true,
          showTitles: true,
          showGrid: false,
          showBorder: false,
          grouping: grouping,
        );
      },
      itemWidthBuilder: _getItemWidth,
      dataCountBuilder: (data) => data.length,
    );
  }

  double? _getItemWidth(String timeframe) {
    switch (timeframe) {
      case '1W':
        return 50.0;
      case '1M':
        return 10.0;
      case '3M':
        return 24.0;
      case '6M':
        return 18.0;
      case '1Y':
        return 24.0;
      case '2Y':
        return 24.0;
      case 'All':
        return 24.0;
      default:
        return 40.0;
    }
  }

  double _getBarWidth(String timeframe) {
    switch (timeframe) {
      case '1W':
        return 20.0;
      case '1M':
        return 4.0;
      case '3M':
        return 8.0;
      case '6M':
        return 6.0;
      case '1Y':
        return 8.0;
      case '2Y':
        return 8.0;
      case 'All':
        return 8.0;
      default:
        return 16.0;
    }
  }

  List<WeeklyBarData> _prepareChartData(
    List<InsightDataPoint> data,
    InsightsGrouping grouping,
  ) {
    return List.generate(data.length, (index) {
      final dataPoint = data[index];
      final label = _generateLabel(index, data.length, dataPoint.date);

      if (grouping == InsightsGrouping.day) {
        final dailyTotal =
            widget.dailyBarValueBuilder?.call(dataPoint) ?? dataPoint.value;
        return WeeklyBarData(
          label: label,
          minValue: 0,
          maxValue: dailyTotal,
          weekStart: dataPoint.date,
        );
      }

      return WeeklyBarData(
        label: label,
        minValue: dataPoint.minValue ?? 0,
        maxValue: dataPoint.maxValue ?? dataPoint.value,
        weekStart: dataPoint.date,
      );
    });
  }

  static String _generateLabel(int index, int totalSlots, DateTime weekStart) {
    final isLast = index == totalSlots - 1;
    final isSecondLast = index == totalSlots - 2;

    // For 6-8 time slots (weekly grouping)
    if (totalSlots <= 8) {
      if (isLast) return 'This Week';
      if (isSecondLast) return 'Last Week';
      final weeksAgo = totalSlots - index - 1;
      return '${weeksAgo}w ago';
    }

    // For 9+ time slots (monthly grouping)
    if (isLast) return 'This Mo';
    if (isSecondLast) return 'Last Mo';
    final monthsAgo = totalSlots - index - 1;
    return '${monthsAgo}mo ago';
  }

  static double _calculateMaxY(List<WeeklyBarData> data) {
    if (data.isEmpty) return 10;

    final maxValue = data
        .map((d) => d.maxValue)
        .reduce((a, b) => a > b ? a : b);

    // Round up to next even number for cleaner axis
    final roundedMax = (maxValue * 1.1).ceil().toDouble();
    return roundedMax.clamp(4, double.infinity);
  }
}
