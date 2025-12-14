import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants/app_constants.dart';

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
    return GestureDetector(
      onTap: () => _openExpandedView(context),
      child: Hero(
        tag: heroTag ?? 'insight_card_$title',
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
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
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (subLabel != null)
                    Text(
                      subLabel!,
                      style: const TextStyle(
                        color: AppConstants.TEXT_TERTIARY_COLOR,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                // Collapsed Chart
                Expanded(
                  child: collapsedChart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openExpandedView(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black, // Changed to black for full screen feel
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: detailPage ?? _ExpandedInsightView(
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
          return FadeTransition(
            opacity: animation,
            child: child,
          );
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Hero(
        tag: heroTag ?? 'insight_card_$title',
        child: Material(
          color: Colors.black,
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
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Main Stats
                if (mainValue != null) ...[
                  Text(
                    mainValue!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (subLabel != null)
                    Text(
                      subLabel!,
                      style: const TextStyle(
                        color: AppConstants.TEXT_TERTIARY_COLOR,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
                
                // Expanded Chart
                SizedBox(
                  height: 300,
                  child: expandedChart,
                ),
                
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
