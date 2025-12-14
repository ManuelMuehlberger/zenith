import 'package:flutter/cupertino.dart';
import '../../services/insights/insight_data_provider.dart';
import '../../models/insights.dart';
import 'insight_card.dart';
import '../workout_chart.dart';

class TrendInsightCard extends StatefulWidget {
  final String title;
  final Color color;
  final String unit;
  final IconData icon;
  final Map<String, dynamic> filters;
  final InsightDataProvider provider;
  final String Function(List<InsightDataPoint>)? mainValueBuilder;
  final String Function(List<InsightDataPoint>)? subLabelBuilder;

  const TrendInsightCard({
    super.key,
    required this.title,
    required this.color,
    required this.unit,
    required this.icon,
    required this.filters,
    required this.provider,
    this.mainValueBuilder,
    this.subLabelBuilder,
  });

  @override
  State<TrendInsightCard> createState() => _TrendInsightCardState();
}

class _TrendInsightCardState extends State<TrendInsightCard> {
  List<InsightDataPoint> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(TrendInsightCard oldWidget) {
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
          _data = [];
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
    return InsightCard<List<InsightDataPoint>>(
      title: widget.title,
      icon: widget.icon,
      color: widget.color,
      unit: widget.unit,
      initialData: _data,
      initialFilters: widget.filters,
      height: 200,
      heroTag: 'trend_${widget.title}',
      dataFetcher: (timeframe, monthsBack, filters) async {
        return widget.provider.getData(
          timeframe: timeframe,
          monthsBack: monthsBack,
          filters: filters,
        );
      },
      mainValueBuilder: widget.mainValueBuilder ?? (data) {
        if (data.isEmpty) return "0";
        final average = data.map((e) => e.value).reduce((a, b) => a + b) / data.length;
        return average.toStringAsFixed(1);
      },
      subLabelBuilder: widget.subLabelBuilder ?? (data) => "Average ${widget.unit}",
      collapsedContentBuilder: (data) {
        if (_isLoading) {
           return const Center(child: CupertinoActivityIndicator());
        }
        return CompactChart(
          values: data.map((e) => e.value).toList(),
          color: widget.color,
          height: 100,
        );
      },
      expandedContentBuilder: (context, data, timeframe, monthsBack) {
        return WorkoutChart(
          title: widget.title,
          data: data,
          color: widget.color,
          unit: widget.unit,
          showGrid: true,
          showTitles: true,
          height: 350,
          barWidth: _getBarWidth(timeframe),
          dotRadius: _getDotRadius(timeframe),
          showContainer: false,
          showHeader: false,
          timeframe: timeframe,
        );
      },
      itemWidthBuilder: _getItemWidth,
      dataCountBuilder: (data) => data.length,
    );
  }

  double? _getItemWidth(String timeframe) {
    switch (timeframe) {
      case '1W': return 50.0;
      case '1M': return 12.0;
      case '3M': return 30.0;
      case '6M': return 20.0;
      case '1Y': return 30.0;
      case '2Y': return 30.0;
      case 'All': return 30.0;
      default: return 40.0;
    }
  }

  double _getBarWidth(String timeframe) {
    switch (timeframe) {
      case '1W': return 6.0;
      case '1M': return 2.0;
      case '3M': return 4.0;
      case '6M': return 3.0;
      case '1Y': return 2.5;
      default: return 2.0;
    }
  }

  double _getDotRadius(String timeframe) {
    switch (timeframe) {
      case '1W': return 6.0;
      case '1M': return 2.0;
      case '3M': return 4.5;
      case '6M': return 4.0;
      case '1Y': return 3.0;
      default: return 2.5;
    }
  }
}
