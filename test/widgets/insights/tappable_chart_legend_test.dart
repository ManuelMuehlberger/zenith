import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/theme/app_theme.dart';
import 'package:zenith/widgets/insights/tappable_chart_legend.dart';

void main() {
  testWidgets('toggles a series off and back on', (tester) async {
    final controller = ChartSeriesVisibilityController(series: _series);

    await tester.pumpWidget(_legendHarness(controller));

    expect(controller.isVisible('baseline'), isTrue);

    await tester.tap(find.byKey(const Key('test_legend_baseline')));
    await tester.pump();

    expect(controller.isVisible('baseline'), isFalse);

    await tester.tap(find.byKey(const Key('test_legend_baseline')));
    await tester.pump();

    expect(controller.isVisible('baseline'), isTrue);
  });

  testWidgets('refuses to hide the last visible series', (tester) async {
    final controller = ChartSeriesVisibilityController(series: _series);

    await tester.pumpWidget(_legendHarness(controller));

    await tester.tap(find.byKey(const Key('test_legend_baseline')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('test_legend_latest')));
    await tester.pump();

    expect(controller.isVisible('baseline'), isFalse);
    expect(controller.isVisible('latest'), isTrue);
  });

  testWidgets('exposes tappable semantics for each item', (tester) async {
    final controller = ChartSeriesVisibilityController(series: _series);

    await tester.pumpWidget(_legendHarness(controller));

    expect(
      tester.getSemantics(find.byKey(const Key('test_legend_baseline'))),
      matchesSemantics(
        label: 'Hide baseline',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });
}

List<ChartLegendSeries> get _series => const [
  ChartLegendSeries(id: 'baseline', label: 'baseline', color: Colors.grey),
  ChartLegendSeries(id: 'latest', label: 'latest', color: Colors.blue),
];

Widget _legendHarness(ChartSeriesVisibilityController controller) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(
        child: TappableChartLegend(
          series: _series,
          controller: controller,
          keyPrefix: 'test_legend',
        ),
      ),
    ),
  );
}
