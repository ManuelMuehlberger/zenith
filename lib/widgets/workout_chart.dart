import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/insights_service.dart';

class WorkoutChart extends StatelessWidget {
  final String title;
  final List<MonthlyDataPoint> data;
  final Color color;
  final String unit;
  final bool showGrid;
  final bool showTitles;
  final double height;
  //final String? unitPreference;

  const WorkoutChart({
    super.key,
    required this.title,
    required this.data,
    required this.color,
    required this.unit,
    this.showGrid = true,
    this.showTitles = true,
    this.height = 200,
    //this.unitPreference, // Added
  });

  String _formatYAxisLabel(double value) {
    // No conversion, just display the value as-is
    if (value > 999) {
      // For chart y-axis, 'k' without 'kg' or 'lbs' to save space
      return '${(value / 1000).toStringAsFixed(0)}k'; 
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: showGrid,
                  drawVerticalLine: false,
                  horizontalInterval: null,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: showTitles,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false, reservedSize: 60), // shift graph left
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false, reservedSize: 30),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: showTitles,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          final month = data[value.toInt()].month;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${month.month}/${month.year.toString().substring(2)}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: showTitles,
                      reservedSize: 28, //shift graph left
                      getTitlesWidget: (double value, TitleMeta meta) {
                        String label;
                        // Only apply special formatting if it's a weight chart
                        if (unit.toLowerCase() == 'kg' || unit.toLowerCase() == 'lbs') {
                           label = _formatYAxisLabel(value);
                        } else {
                          label = value.toInt().toString();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8.0,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withAlpha((255 * 0.1).round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
