import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/widgets/insights/dynamic_chart_labels.dart';

void main() {
  group('dynamic chart labels', () {
    test('keeps first and last labels when space allows', () {
      final selected = selectDynamicChartLabels(
        candidates: buildExtremaLabelCandidates(
          values: const [1, 2, 3],
          labels: const ['start', 'mid', 'end'],
          positions: const [0, 100, 200],
        ),
        minPixelGap: 52,
      );

      expect(selected.map((label) => label.label), ['start', 'end']);
    });

    test('selects prominent local maxima and minima', () {
      final selected = selectDynamicChartLabels(
        candidates: buildExtremaLabelCandidates(
          values: const [1, 4, 1, 3, 1],
          labels: const ['a', 'peak', 'low', 'rise', 'e'],
          positions: const [0, 100, 200, 300, 400],
          prominenceRatio: 0.05,
        ),
        minPixelGap: 52,
      );

      expect(selected.map((label) => label.label), [
        'a',
        'peak',
        'low',
        'rise',
        'e',
      ]);
    });

    test('drops labels that are too close', () {
      final selected = selectDynamicChartLabels(
        candidates: const [
          DynamicChartLabelCandidate(
            index: 0,
            position: 0,
            label: 'start',
            kind: DynamicChartLabelKind.edge,
          ),
          DynamicChartLabelCandidate(
            index: 1,
            position: 20,
            label: 'peak',
            kind: DynamicChartLabelKind.localMaximum,
            prominence: 10,
          ),
          DynamicChartLabelCandidate(
            index: 2,
            position: 100,
            label: 'end',
            kind: DynamicChartLabelKind.edge,
          ),
        ],
        minPixelGap: 52,
      );

      expect(selected.map((label) => label.label), ['start', 'end']);
    });

    test('suppresses low-prominence extrema', () {
      final candidates = buildExtremaLabelCandidates(
        values: const [10, 10.1, 10, 12],
        labels: const ['a', 'tiny', 'c', 'd'],
        positions: const [0, 100, 200, 300],
        prominenceRatio: 0.1,
      );

      expect(
        candidates.where(
          (candidate) => candidate.kind == DynamicChartLabelKind.localMaximum,
        ),
        isEmpty,
      );
    });

    test('prefers higher-priority labels when candidates collide', () {
      final selected = selectDynamicChartLabels(
        candidates: const [
          DynamicChartLabelCandidate(
            index: 1,
            position: 48,
            label: 'peak',
            kind: DynamicChartLabelKind.localMaximum,
            prominence: 100,
          ),
          DynamicChartLabelCandidate(
            index: 0,
            position: 0,
            label: 'start',
            kind: DynamicChartLabelKind.edge,
          ),
        ],
        minPixelGap: 52,
      );

      expect(selected.single.label, 'start');
    });
  });
}
