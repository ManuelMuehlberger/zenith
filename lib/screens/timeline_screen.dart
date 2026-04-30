import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  static final Logger _logger = Logger('TimelineScreen');

  @override
  void initState() {
    super.initState();
    _logger.info('Opening development timeline screen');
  }

  @override
  void dispose() {
    _logger.fine('Disposing development timeline screen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + kToolbarHeight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: _buildMainContent(headerHeight)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                  sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                ),
                child: Container(
                  height: headerHeight,
                  color: colors.overlayMedium,
                  child: SafeArea(bottom: false, child: _buildHeaderContent()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent() {
    final textTheme = context.appText;
    final colorScheme = context.appScheme;

    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                onPressed: () {
                  _logger.fine('Closing development timeline screen');
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  CupertinoIcons.back,
                  color: colorScheme.onSurface,
                  size: 28,
                ),
              ),
            ),
            Expanded(
              child: Text('Development Timeline', style: textTheme.titleMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(double headerHeight) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: headerHeight)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.2),
                        colors.warning.withValues(alpha: 0.16),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.rocket_fill,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Roadmap', style: textTheme.headlineSmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track the evolution of your workout companion',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildTimelineItem(
                  version: '1.0.0',
                  title: 'Foundation',
                  subtitle: 'Core workout tracking & basic features',
                  status: TimelineStatus.completed,
                  features: const [
                    'Workout creation and tracking',
                    'Exercise database integration',
                    'Basic statistics and insights',
                    'Profile management',
                    'Data export/import',
                  ],
                  icon: CupertinoIcons.checkmark_seal_fill,
                  color: colors.success,
                ),
                _buildTimelineItem(
                  version: '0.2.0',
                  title: 'Enhanced Experience',
                  subtitle: 'Exercise renders & smooth animations',
                  status: TimelineStatus.inProgress,
                  features: const [
                    'Exercise demonstration videos',
                    'Smooth page transitions',
                    'Enhanced workout animations',
                    'Improved exercise selection UI',
                    'Better visual feedback',
                  ],
                  icon: CupertinoIcons.play_circle_fill,
                  color: colorScheme.primary,
                ),
                _buildTimelineItem(
                  version: '0.3.0',
                  title: 'Insights & Widgets',
                  subtitle: 'Advanced analytics & home screen widgets',
                  status: TimelineStatus.planned,
                  features: const [
                    'Home screen widgets',
                    'Advanced workout analytics',
                    'Progress tracking charts',
                    'Workout streak counters',
                    'Performance predictions',
                  ],
                  icon: CupertinoIcons.chart_bar_fill,
                  color: colors.warning,
                ),
                _buildTimelineItem(
                  version: '0.4.0',
                  title: 'Social & Sharing',
                  subtitle: 'Connect with friends & share progress',
                  status: TimelineStatus.planned,
                  features: const [
                    'Workout sharing capabilities',
                    'Progress photo integration',
                    'Achievement system',
                    'Workout challenges',
                    'Community features',
                  ],
                  icon: CupertinoIcons.person_2_fill,
                  color: colors.textSecondary,
                ),
                _buildTimelineItem(
                  version: '0.5.0',
                  title: 'AI Integration',
                  subtitle: 'Smart recommendations & form analysis',
                  status: TimelineStatus.future,
                  features: const [
                    'AI workout recommendations',
                    'Form analysis using camera',
                    'Personalized training plans',
                    'Smart rest period suggestions',
                    'Injury prevention insights',
                  ],
                  icon: CupertinoIcons.lightbulb_fill,
                  color: colors.textSecondary,
                ),
                _buildTimelineItem(
                  version: '1.0.0+',
                  title: 'Beyond',
                  subtitle: 'Wearable integration & advanced features',
                  status: TimelineStatus.future,
                  features: const [
                    'Apple Watch integration',
                    'Heart rate monitoring',
                    'Advanced biometric tracking',
                    'Nutrition integration',
                    'Sleep pattern analysis',
                  ],
                  icon: CupertinoIcons.infinite,
                  color: colors.textTertiary,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.heart_fill,
                        color: colorScheme.error,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Built with passion for fitness',
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your feedback shapes our roadmap',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String version,
    required String title,
    required String subtitle,
    required TimelineStatus status,
    required List<String> features,
    required IconData icon,
    required Color color,
  }) {
    final textTheme = context.appText;
    final colorScheme = context.appScheme;
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: status == TimelineStatus.completed
                      ? color
                      : status == TimelineStatus.inProgress
                      ? color.withValues(alpha: 0.7)
                      : colors.textTertiary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: status == TimelineStatus.completed
                        ? color
                        : status == TimelineStatus.inProgress
                        ? color
                        : colors.textSecondary,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: status == TimelineStatus.completed
                      ? colorScheme.onPrimary
                      : status == TimelineStatus.inProgress
                      ? colorScheme.onPrimary
                      : colors.textSecondary,
                  size: 20,
                ),
              ),
              if (version != '1.0.0+')
                Container(width: 2, height: 60, color: colors.textTertiary),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: status == TimelineStatus.inProgress
                      ? color.withValues(alpha: 0.5)
                      : AppThemeColors.clear,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          version,
                          style: textTheme.labelMedium?.copyWith(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...features.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.circle_fill,
                            size: 6,
                            color: colors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TimelineStatus status) {
    final textTheme = context.appText;

    Color color;
    String text;
    IconData icon;

    switch (status) {
      case TimelineStatus.completed:
        color = context.appColors.success;
        text = 'Released';
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case TimelineStatus.inProgress:
        color = context.appScheme.primary;
        text = 'In Progress';
        icon = CupertinoIcons.clock_fill;
        break;
      case TimelineStatus.planned:
        color = context.appColors.warning;
        text = 'Planned';
        icon = CupertinoIcons.calendar;
        break;
      case TimelineStatus.future:
        color = context.appColors.textSecondary;
        text = 'Future';
        icon = CupertinoIcons.star_fill;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum TimelineStatus { completed, inProgress, planned, future }
