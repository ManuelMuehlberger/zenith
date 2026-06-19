import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

// policy: allow-public-api shared series descriptor for tappable insights legends.
class ChartLegendSeries {
  const ChartLegendSeries({
    required this.id,
    required this.label,
    required this.color,
  });

  final String id;
  final String label;
  final Color color;
}

// policy: allow-public-api reusable visibility state for multi-series insights charts.
class ChartSeriesVisibilityController extends ChangeNotifier {
  ChartSeriesVisibilityController({required List<ChartLegendSeries> series})
    : _visibleSeriesIds = series.map((item) => item.id).toSet();

  Set<String> _visibleSeriesIds;

  bool isVisible(String id) => _visibleSeriesIds.contains(id);

  Set<String> get visibleSeriesIds => Set.unmodifiable(_visibleSeriesIds);

  void syncSeries(List<ChartLegendSeries> series) {
    final ids = series.map((item) => item.id).toSet();
    final next = _visibleSeriesIds.intersection(ids);
    _visibleSeriesIds = next.isEmpty ? ids : next;
  }

  bool toggle(String id) {
    if (!_visibleSeriesIds.contains(id)) {
      _visibleSeriesIds = {..._visibleSeriesIds, id};
      notifyListeners();
      return true;
    }

    if (_visibleSeriesIds.length <= 1) {
      return false;
    }

    final next = {..._visibleSeriesIds}..remove(id);
    _visibleSeriesIds = next;
    notifyListeners();
    return true;
  }
}

// policy: allow-public-api mandatory shared legend control for multi-series insights charts.
class TappableChartLegend extends StatelessWidget {
  const TappableChartLegend({
    super.key,
    required this.series,
    required this.controller,
    this.isInteractive = true,
    this.spacing = 12,
    this.runSpacing = 4,
    this.dotSize = 8,
    this.keyPrefix = 'chart_legend',
  });

  final List<ChartLegendSeries> series;
  final ChartSeriesVisibilityController controller;
  final bool isInteractive;
  final double spacing;
  final double runSpacing;
  final double dotSize;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    controller.syncSeries(series);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: WrapAlignment.center,
          children: [
            for (final item in series)
              _TappableChartLegendItem(
                key: Key('${keyPrefix}_${item.id}'),
                item: item,
                isInteractive: isInteractive,
                isVisible: isInteractive ? controller.isVisible(item.id) : true,
                dotSize: dotSize,
                onTap: isInteractive ? () => controller.toggle(item.id) : null,
              ),
          ],
        );
      },
    );
  }
}

class _TappableChartLegendItem extends StatelessWidget {
  const _TappableChartLegendItem({
    super.key,
    required this.item,
    required this.isInteractive,
    required this.isVisible,
    required this.dotSize,
    required this.onTap,
  });

  final ChartLegendSeries item;
  final bool isInteractive;
  final bool isVisible;
  final double dotSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final opacity = !isInteractive || isVisible ? 1.0 : 0.38;
    final textStyle = context.appText.labelSmall?.copyWith(
      color: context.appColors.textSecondary.withValues(alpha: opacity),
      fontWeight: FontWeight.w700,
      decoration: !isInteractive || isVisible
          ? TextDecoration.none
          : TextDecoration.lineThrough,
      decorationColor: context.appColors.textSecondary.withValues(alpha: 0.65),
    );

    return Semantics(
      button: isInteractive,
      selected: isInteractive ? isVisible : null,
      label: isInteractive
          ? '${isVisible ? 'Hide' : 'Show'} ${item.label}'
          : item.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
