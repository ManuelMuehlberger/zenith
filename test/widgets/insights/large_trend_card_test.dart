import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/insights.dart';
import 'package:zenith/services/insights/insight_data_provider.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/insights/large_trend_card.dart';

class _FakeInsightDataProvider implements InsightDataProvider {
  @override
  Future<List<InsightDataPoint>> getData({
    required String timeframe,
    required int monthsBack,
    Map<String, dynamic> filters = const {},
  }) async {
    return [
      InsightDataPoint(date: DateTime(2026, 5, 1), value: 61.2, count: 1),
      InsightDataPoint(date: DateTime(2026, 5, 8), value: 61.6, count: 1),
    ];
  }
}

void main() {
  group('TrendInsightCard', () {
    testWidgets('can open detail view without showing filters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TrendInsightCard(
              title: 'Body Weight',
              color: Colors.lightBlue,
              unit: 'kg',
              icon: Icons.monitor_weight_outlined,
              filters: const {'timeframe': '6M'},
              provider: _FakeInsightDataProvider(),
              showFiltersInDetail: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Body Weight').first);
      await tester.pumpAndSettle();

      expect(find.text('6M'), findsOneWidget);
      expect(find.text('Workout'), findsNothing);
    });
  });
}
