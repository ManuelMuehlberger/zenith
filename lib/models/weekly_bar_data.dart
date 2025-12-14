/// Data structure for weekly bar chart data
class WeeklyBarData {
  final String label; // e.g., "5w ago", "This Week"
  final double minValue;
  final double maxValue;
  final DateTime weekStart;

  WeeklyBarData({
    required this.label,
    required this.minValue,
    required this.maxValue,
    required this.weekStart,
  });
}
