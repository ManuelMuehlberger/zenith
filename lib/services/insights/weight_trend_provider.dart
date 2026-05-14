import '../../models/user_data.dart';
import '../insights_service.dart';
import '../user_service.dart';
import 'insight_data_provider.dart';
import 'insights_timeframe_resolver.dart';

// policy: allow-public-api shared insight provider consumed by the body-weight trend UI.
class WeightTrendProvider implements InsightDataProvider {
  final List<WeightEntry> Function()? weightHistoryProvider;

  WeightTrendProvider({this.weightHistoryProvider});

  @override
  Future<List<InsightDataPoint>> getData({
    required String timeframe,
    required int monthsBack,
    Map<String, dynamic> filters = const {},
  }) async {
    final grouping = InsightsService.getGroupingForTimeframe(timeframe);
    final weeksBack = (timeframe == '1W' && monthsBack <= 1) ? 1 : null;
    final now = DateTime.now();
    final entries = [..._getWeightHistory()]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final validEntries = entries
        .where((entry) => !entry.timestamp.isAfter(now))
        .toList();
    if (validEntries.isEmpty) {
      return [];
    }

    final latestEntryDate = validEntries.last.timestamp;
    final referenceDate = latestEntryDate.isAfter(now) ? now : latestEntryDate;
    final cutoffDate = InsightsTimeframeResolver.resolveWindowStart(
      referenceDate: referenceDate,
      monthsBack: monthsBack,
      weeksBack: weeksBack,
      grouping: grouping,
    );

    final visibleEntries = validEntries.where((entry) {
      return !entry.timestamp.isBefore(cutoffDate) &&
          !entry.timestamp.isAfter(now);
    }).toList();

    if (visibleEntries.isEmpty) {
      return [];
    }

    final slots = InsightsTimeframeResolver.resolveSlotCount(
      referenceDate: referenceDate,
      monthsBack: monthsBack,
      weeksBack: weeksBack,
      grouping: grouping,
    );

    final points = <InsightDataPoint>[];

    for (var index = 0; index < slots; index++) {
      final reverseIndex = slots - index - 1;
      final slotBounds = _slotBounds(
        referenceDate: referenceDate,
        grouping: grouping,
        reverseIndex: reverseIndex,
      );
      final slotEntries = visibleEntries.where((entry) {
        return !entry.timestamp.isBefore(slotBounds.start) &&
            entry.timestamp.isBefore(slotBounds.end);
      }).toList();

      if (slotEntries.isEmpty && grouping == InsightsGrouping.week) {
        continue;
      }

      if (slotEntries.isEmpty) {
        points.add(
          InsightDataPoint(
            date: slotBounds.start,
            value: 0,
            minValue: 0,
            maxValue: 0,
            count: 0,
          ),
        );
        continue;
      }

      final latest = slotEntries.last.value;
      final values = slotEntries.map((entry) => entry.value).toList();

      points.add(
        InsightDataPoint(
          date: slotBounds.start,
          value: latest,
          minValue: values.reduce((a, b) => a < b ? a : b),
          maxValue: values.reduce((a, b) => a > b ? a : b),
          count: slotEntries.length,
        ),
      );
    }

    return points;
  }

  List<WeightEntry> _getWeightHistory() {
    return weightHistoryProvider?.call() ??
        UserService.instance.currentProfile?.weightHistory ??
        const [];
  }

  ({DateTime start, DateTime end}) _slotBounds({
    required DateTime referenceDate,
    required InsightsGrouping grouping,
    required int reverseIndex,
  }) {
    if (grouping == InsightsGrouping.month) {
      final start = DateTime(
        referenceDate.year,
        referenceDate.month - reverseIndex,
        1,
      );
      return (start: start, end: DateTime(start.year, start.month + 1, 1));
    }

    if (grouping == InsightsGrouping.week) {
      final weekStart = _weekStart(
        referenceDate,
      ).subtract(Duration(days: reverseIndex * 7));
      return (start: weekStart, end: weekStart.add(const Duration(days: 7)));
    }

    final dayStart = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    ).subtract(Duration(days: reverseIndex));
    return (start: dayStart, end: dayStart.add(const Duration(days: 1)));
  }

  DateTime _weekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysFromMonday));
  }
}
