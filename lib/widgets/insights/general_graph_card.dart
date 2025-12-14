import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/insights_service.dart';
import 'insight_card.dart';
import '../workout_chart.dart';

class GeneralGraphCard extends StatelessWidget {
  final String title;
  final List<InsightDataPoint> data;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const GeneralGraphCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return InsightCard<List<InsightDataPoint>>(
      title: title,
      icon: icon,
      color: color,
      unit: unit,
      initialData: data,
      dataFetcher: (timeframe, monthsBack, filters) async {
        // Static data for now
        return data;
      },
      mainValueBuilder: (data) => value,
      subLabelBuilder: (data) => unit,
      collapsedContentBuilder: (data) {
        return CompactChart(
          values: data.map((e) => e.value).toList(),
          color: color,
          height: 60,
        );
      },
      expandedContentBuilder: (context, data, timeframe, monthsBack) {
        return WorkoutChart(
          title: title,
          data: data,
          color: color,
          unit: unit,
          showGrid: true,
          showTitles: true,
          height: 350,
          barWidth: _getBarWidth(timeframe),
          dotRadius: _getDotRadius(timeframe),
          showContainer: false,
          showHeader: false,
        );
      },
      itemWidthBuilder: (timeframe) => 40.0,
      dataCountBuilder: (data) => data.length,
    );
  }

  double _getBarWidth(String timeframe) {
    switch (timeframe) {
      case '1W': return 6.0;
      case '1M': return 5.0;
      case '3M': return 4.0;
      case '6M': return 3.0;
      case '1Y': return 2.5;
      default: return 2.0;
    }
  }

  double _getDotRadius(String timeframe) {
    switch (timeframe) {
      case '1W': return 6.0;
      case '1M': return 5.0;
      case '3M': return 4.5;
      case '6M': return 4.0;
      case '1Y': return 3.0;
      default: return 2.5;
    }
  }
}
