import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/workout_chart.dart';

void main() {
  group('CompactChart', () {
    testWidgets('renders with an explicit preview range', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: CompactChart(
              values: [61.2, 61.6, 61.4],
              color: Colors.blue,
              minY: 56,
              maxY: 66,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
