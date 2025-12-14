import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'expandable_insight_card.dart';
import '../../screens/insight_detail_screen.dart';

/// A unified card widget for displaying insights.
/// 
/// This widget can be configured to display various types of insights,
/// including bar charts, line charts, and statistics. It supports
/// both expandable and non-expandable modes.
class InsightCard<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String unit;
  final T initialData;
  
  /// Function to fetch data when filters or timeframe change.
  /// Required for expandable cards that support filtering.
  final Future<T> Function(String timeframe, int monthsBack, Map<String, dynamic> filters)? dataFetcher;
  
  /// Builder for the main value displayed in the card.
  /// If null, no main value is displayed.
  final String Function(T data)? mainValueBuilder;
  
  /// Builder for the sub-label displayed below the main value.
  final String Function(T data)? subLabelBuilder;
  
  /// Builder for the content displayed in the collapsed view (card).
  final Widget Function(T data) collapsedContentBuilder;
  
  /// Builder for the content displayed in the expanded view (detail screen).
  /// Required if [isExpandable] is true.
  final Widget Function(BuildContext context, T data, String timeframe, int monthsBack)? expandedContentBuilder;
  
  /// Builder for the axis in the expanded view.
  final Widget? Function(BuildContext context, T data, String timeframe, int monthsBack)? axisBuilder;
  
  /// Builder for the width of each data item in the expanded view.
  final double? Function(String timeframe)? itemWidthBuilder;
  
  /// Builder for the count of data points.
  final int Function(T data)? dataCountBuilder;
  
  final Map<String, dynamic> initialFilters;
  final double? height;
  final String? heroTag;
  final bool isExpandable;

  const InsightCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.unit,
    required this.initialData,
    required this.collapsedContentBuilder,
    this.dataFetcher,
    this.mainValueBuilder,
    this.subLabelBuilder,
    this.expandedContentBuilder,
    this.axisBuilder,
    this.itemWidthBuilder,
    this.dataCountBuilder,
    this.initialFilters = const {},
    this.height,
    this.heroTag,
    this.isExpandable = true,
  });

  @override
  Widget build(BuildContext context) {
    final mainValue = mainValueBuilder?.call(initialData);
    final subLabel = subLabelBuilder?.call(initialData);
    final collapsedContent = collapsedContentBuilder(initialData);

    Widget card = ExpandableInsightCard(
      title: title,
      icon: icon,
      iconColor: color,
      mainValue: mainValue,
      subLabel: subLabel,
      collapsedChart: collapsedContent,
      expandedChart: isExpandable && expandedContentBuilder != null
          ? expandedContentBuilder!(context, initialData, '6M', 6) // Default initial view
          : const SizedBox.shrink(),
      heroTag: heroTag,
      // Only provide detail page if expandable
      detailPage: isExpandable && dataFetcher != null && expandedContentBuilder != null
          ? InsightDetailScreen(
              title: title,
              icon: icon,
              color: color,
              unit: unit,
              initialFilters: initialFilters,
              dataFetcher: (timeframe, months, filters) async {
                return dataFetcher!(timeframe, months, filters);
              },
              mainValueBuilder: (data) => mainValueBuilder?.call(data as T) ?? '',
              subLabelBuilder: (data) => subLabelBuilder?.call(data as T) ?? '',
              dataCountBuilder: (data) => dataCountBuilder?.call(data as T) ?? 0,
              itemWidthBuilder: (timeframe) => itemWidthBuilder?.call(timeframe) ?? 50.0,
              chartBuilder: (context, data, timeframe, months) {
                return expandedContentBuilder!(context, data as T, timeframe, months);
              },
              axisBuilder: (context, data, timeframe, months) {
                return axisBuilder?.call(context, data as T, timeframe, months);
              },
              heroTag: heroTag,
            )
          : null,
    );

    if (height != null) {
      return SizedBox(height: height, child: card);
    }
    return card;
  }
}
