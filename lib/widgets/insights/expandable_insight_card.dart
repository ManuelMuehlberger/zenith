import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ExpandableInsightCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String? mainValue;
  final String? subLabel;
  final Widget collapsedChart;
  final Widget expandedChart;
  final Widget? extraExpandedContent;
  final String? unit;
  final Widget? detailPage;
  final String? heroTag;

  const ExpandableInsightCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    this.mainValue,
    this.subLabel,
    required this.collapsedChart,
    required this.expandedChart,
    this.extraExpandedContent,
    this.unit,
    this.detailPage,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return GestureDetector(
      onTap: () => _openExpandedView(context),
      child: Hero(
        tag: heroTag ?? 'insight_card_$title',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.labelMedium?.copyWith(
                          color: iconColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Main Value
                if (mainValue != null) ...[
                  Text(
                    mainValue!,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (subLabel != null)
                    Text(subLabel!, style: textTheme.bodySmall),
                  const SizedBox(height: 8),
                ],
                // Collapsed Chart
                Expanded(child: collapsedChart),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openExpandedView(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: backgroundColor,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child:
                detailPage ??
                _ExpandedInsightView(
                  title: title,
                  icon: icon,
                  iconColor: iconColor,
                  mainValue: mainValue,
                  subLabel: subLabel,
                  expandedChart: expandedChart,
                  extraContent: extraExpandedContent,
                  heroTag: heroTag,
                ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _ExpandedInsightView extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String? mainValue;
  final String? subLabel;
  final Widget expandedChart;
  final Widget? extraContent;
  final String? heroTag;

  const _ExpandedInsightView({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.mainValue,
    this.subLabel,
    required this.expandedChart,
    this.extraContent,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textTheme = context.appText;
    final colors = context.appColors;
    final colorScheme = context.appScheme;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.xmark_circle_fill,
            color: colors.textSecondary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Hero(
        tag: heroTag ?? 'insight_card_$title',
        child: Material(
          color: backgroundColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(color: iconColor),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Stats
                if (mainValue != null) ...[
                  Text(
                    mainValue!,
                    style: textTheme.displaySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (subLabel != null)
                    Text(
                      subLabel!,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  const SizedBox(height: 32),
                ],

                // Expanded Chart
                SizedBox(height: 300, child: expandedChart),

                if (extraContent != null) ...[
                  const SizedBox(height: 32),
                  extraContent!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
