import 'dart:math' as math;

// policy: allow-public-api reusable label kind contract for insight chart axes.
enum DynamicChartLabelKind {
  edge,
  localMaximum,
  localMinimum,
  changePoint,
  fallback,
}

// policy: allow-public-api candidate label model shared by insight chart selectors.
class DynamicChartLabelCandidate {
  final int index;
  final double position;
  final String label;
  final DynamicChartLabelKind kind;
  final double value;
  final double prominence;

  const DynamicChartLabelCandidate({
    required this.index,
    required this.position,
    required this.label,
    required this.kind,
    this.value = 0,
    this.prominence = 0,
  });
}

// policy: allow-public-api selected label point returned by the chart label helper.
class DynamicChartLabelPoint {
  final int index;
  final double position;
  final String label;
  final DynamicChartLabelKind kind;

  const DynamicChartLabelPoint({
    required this.index,
    required this.position,
    required this.label,
    required this.kind,
  });
}

List<DynamicChartLabelPoint> selectDynamicChartLabels({
  required List<DynamicChartLabelCandidate> candidates,
  required double minPixelGap,
  int? maxLabelCount,
}) {
  final visibleCandidates = candidates
      .where((candidate) => candidate.label.isNotEmpty)
      .toList(growable: false);
  if (visibleCandidates.isEmpty) {
    return const [];
  }

  final sorted = [...visibleCandidates]
    ..sort((a, b) {
      final priority = _kindPriority(b.kind).compareTo(_kindPriority(a.kind));
      if (priority != 0) return priority;
      final prominence = b.prominence.compareTo(a.prominence);
      if (prominence != 0) return prominence;
      return a.index.compareTo(b.index);
    });

  final selected = <DynamicChartLabelCandidate>[];
  final limit = maxLabelCount ?? sorted.length;
  for (final candidate in sorted) {
    if (selected.length >= limit) break;
    final hasCollision = selected.any((accepted) {
      return (accepted.position - candidate.position).abs() < minPixelGap;
    });
    if (!hasCollision) {
      selected.add(candidate);
    }
  }

  selected.sort((a, b) => a.position.compareTo(b.position));
  return selected
      .map(
        (candidate) => DynamicChartLabelPoint(
          index: candidate.index,
          position: candidate.position,
          label: candidate.label,
          kind: candidate.kind,
        ),
      )
      .toList(growable: false);
}

List<DynamicChartLabelCandidate> buildExtremaLabelCandidates({
  required List<double> values,
  required List<String> labels,
  required List<double> positions,
  double prominenceRatio = 0.05,
}) {
  if (values.isEmpty ||
      labels.length != values.length ||
      positions.length != values.length) {
    return const [];
  }

  final minValue = values.reduce(math.min);
  final maxValue = values.reduce(math.max);
  final minProminence = (maxValue - minValue).abs() * prominenceRatio;
  final candidates = <DynamicChartLabelCandidate>[
    DynamicChartLabelCandidate(
      index: 0,
      position: positions.first,
      label: labels.first,
      kind: DynamicChartLabelKind.edge,
      value: values.first,
      prominence: double.infinity,
    ),
  ];

  for (var index = 1; index < values.length - 1; index++) {
    final previous = values[index - 1];
    final current = values[index];
    final next = values[index + 1];
    final isMaximum = current > previous && current > next;
    final isMinimum = current < previous && current < next;
    if (!isMaximum && !isMinimum) continue;

    final prominence = math.min(
      (current - previous).abs(),
      (current - next).abs(),
    );
    if (prominence < minProminence) continue;

    candidates.add(
      DynamicChartLabelCandidate(
        index: index,
        position: positions[index],
        label: labels[index],
        kind: isMaximum
            ? DynamicChartLabelKind.localMaximum
            : DynamicChartLabelKind.localMinimum,
        value: current,
        prominence: prominence,
      ),
    );
  }

  if (values.length > 1) {
    candidates.add(
      DynamicChartLabelCandidate(
        index: values.length - 1,
        position: positions.last,
        label: labels.last,
        kind: DynamicChartLabelKind.edge,
        value: values.last,
        prominence: double.infinity,
      ),
    );
  }

  return candidates;
}

List<DynamicChartLabelCandidate> buildChangePointLabelCandidates({
  required List<bool> states,
  required List<String> labels,
  required List<double> positions,
}) {
  if (states.isEmpty ||
      labels.length != states.length ||
      positions.length != states.length) {
    return const [];
  }

  final candidates = <DynamicChartLabelCandidate>[
    DynamicChartLabelCandidate(
      index: 0,
      position: positions.first,
      label: labels.first,
      kind: DynamicChartLabelKind.edge,
      prominence: double.infinity,
    ),
  ];

  for (var index = 1; index < states.length; index++) {
    if (states[index] == states[index - 1]) continue;
    candidates.add(
      DynamicChartLabelCandidate(
        index: index,
        position: positions[index],
        label: labels[index],
        kind: DynamicChartLabelKind.changePoint,
        prominence: 1,
      ),
    );
  }

  if (states.length > 1) {
    candidates.add(
      DynamicChartLabelCandidate(
        index: states.length - 1,
        position: positions.last,
        label: labels.last,
        kind: DynamicChartLabelKind.edge,
        prominence: double.infinity,
      ),
    );
  }

  return candidates;
}

int _kindPriority(DynamicChartLabelKind kind) {
  return switch (kind) {
    DynamicChartLabelKind.edge => 100,
    DynamicChartLabelKind.changePoint => 85,
    DynamicChartLabelKind.localMaximum => 70,
    DynamicChartLabelKind.localMinimum => 70,
    DynamicChartLabelKind.fallback => 20,
  };
}
