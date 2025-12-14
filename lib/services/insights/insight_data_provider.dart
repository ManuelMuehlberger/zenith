import '../../models/insights.dart';

abstract class InsightDataProvider {
  Future<List<InsightDataPoint>> getData({
    required String timeframe,
    required int monthsBack,
    Map<String, dynamic> filters = const {},
  });
}
