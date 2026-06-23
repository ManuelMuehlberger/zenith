import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/insight_feed.dart';
import '../../models/workout_achievement.dart';
import '../../services/insights/insight_feed_service.dart';
import '../../theme/app_theme.dart';
import '../timeline/award_balloons.dart';
import '../timeline/workout_achievement_awards.dart';
import 'dynamic_chart_labels.dart';
import 'tappable_chart_legend.dart';

const double _insightLinePlotLeftPadding = 34.0;
const double _insightLinePlotRightPadding = 4.0;
const double _dynamicXLabelMinGap = 52.0;
const double _dynamicXLabelWidth = 56.0;
const String _baselineSeriesId = 'baseline';
const String _latestSeriesId = 'latest';
const String _primarySeriesId = 'primary';
const String _referenceSeriesId = 'reference';
const String _averageSeriesId = 'average';

// policy: allow-public-api top-of-screen section that renders the daily insights feed.
class InsightsFeedSection extends StatefulWidget {
  const InsightsFeedSection({super.key, this.service, this.refreshToken = 0});

  final InsightFeedService? service;
  final int refreshToken;

  @override
  State<InsightsFeedSection> createState() => _InsightsFeedSectionState();
}

class _InsightsFeedSectionState extends State<InsightsFeedSection> {
  late Future<List<InsightFeedStack>> _stacksFuture;

  InsightFeedService get _service =>
      widget.service ?? InsightFeedService.instance;

  @override
  void initState() {
    super.initState();
    _stacksFuture = _service.getCardStacks();
  }

  @override
  void didUpdateWidget(covariant InsightsFeedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.service != oldWidget.service ||
        widget.refreshToken != oldWidget.refreshToken) {
      _stacksFuture = _service.getCardStacks(
        forceRefresh: widget.refreshToken != oldWidget.refreshToken,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InsightFeedStack>>(
      future: _stacksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CupertinoActivityIndicator(radius: 14)),
          );
        }

        final stacks = snapshot.data ?? const <InsightFeedStack>[];
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stacks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _InsightFeedFallbackCard(),
                )
              else
                for (final stack in stacks) ...[
                  _InsightFeedStackHeader(title: stack.title),
                  const SizedBox(height: 10),
                  _InsightFeedStackRail(cards: stack.cards),
                  const SizedBox(height: 20),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _InsightFeedStackRail extends StatefulWidget {
  const _InsightFeedStackRail({required this.cards});

  final List<InsightFeedCard> cards;

  @override
  State<_InsightFeedStackRail> createState() => _InsightFeedStackRailState();
}

class _InsightFeedStackRailState extends State<_InsightFeedStackRail>
    with SingleTickerProviderStateMixin {
  static const double _pageTurnDistanceFraction = 0.14;
  static const double _pageTurnVelocity = 220;
  static const Duration _settleDuration = Duration(milliseconds: 210);

  var _currentPage = 0;
  var _dragOffset = 0.0;
  int? _settlingPage;
  late final AnimationController _settleController;
  Animation<double>? _settleAnimation;

  @override
  void initState() {
    super.initState();
    _settleController =
        AnimationController(duration: _settleDuration, vsync: this)
          ..addListener(_handleSettleTick)
          ..addStatusListener(_handleSettleStatusChanged);
  }

  @override
  void didUpdateWidget(covariant _InsightFeedStackRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.cards.length) {
      _currentPage = math.max(0, widget.cards.length - 1);
    }
    if (_settlingPage != null && _settlingPage! >= widget.cards.length) {
      _settleController.stop();
      _settlingPage = null;
      _dragOffset = 0;
    }
  }

  @override
  void dispose() {
    _settleController.dispose();
    super.dispose();
  }

  void _handleSettleTick() {
    final animation = _settleAnimation;
    if (animation == null || !mounted) {
      return;
    }
    setState(() {
      _dragOffset = animation.value;
    });
  }

  void _handleSettleStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    setState(() {
      final settledPage = _settlingPage;
      if (settledPage != null) {
        _currentPage = settledPage;
      }
      _settlingPage = null;
      _dragOffset = 0;
      _settleAnimation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    final hasDots = cards.length > 1;
    final dotsHeight = hasDots ? 10.0 : 0.0;
    final dotsGap = hasDots ? 6.0 : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = _activeCardHeight(cards, constraints.maxWidth);
        return SizedBox(
          key: const Key('insight_feed_stack_rail'),
          height: cardHeight + dotsGap + dotsHeight,
          child: Column(
            children: [
              SizedBox(
                height: cardHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: cards.length > 1
                      ? (_) => _stopSettleAnimation()
                      : null,
                  onHorizontalDragUpdate: cards.length > 1
                      ? (details) =>
                            _handleHorizontalDragUpdate(details, constraints)
                      : null,
                  onHorizontalDragEnd: cards.length > 1
                      ? (details) => _handleHorizontalDragEnd(
                          details,
                          constraints.maxWidth,
                        )
                      : null,
                  onHorizontalDragCancel: cards.length > 1
                      ? () => _animateToPageOffset(width: 0)
                      : null,
                  child: ClipRect(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: _buildSwipePages(
                        cards: cards,
                        width: constraints.maxWidth,
                      ),
                    ),
                  ),
                ),
              ),
              if (hasDots) ...[
                SizedBox(height: dotsGap),
                _InsightFeedPageDots(
                  currentPage: _currentPage,
                  pageCount: cards.length,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSwipePages({
    required List<InsightFeedCard> cards,
    required double width,
  }) {
    final pages = <Widget>[
      _buildPositionedPage(card: cards[_currentPage], offset: _dragOffset),
    ];
    final targetPage = _targetPage(cards);
    if (targetPage != _currentPage) {
      final direction = targetPage > _currentPage ? 1 : -1;
      pages.add(
        _buildPositionedPage(
          card: cards[targetPage],
          offset: _dragOffset + direction * width,
        ),
      );
    }
    return pages;
  }

  Widget _buildPositionedPage({
    required InsightFeedCard card,
    required double offset,
  }) {
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            primary: false,
            child: SizedBox(
              key: Key('insight_feed_page_card_${card.id}'),
              height: _cardHeight(card),
              child: InsightFeedCardWidget(card: card),
            ),
          ),
        ),
      ),
    );
  }

  int _targetPage(List<InsightFeedCard> cards) {
    if (_settlingPage != null) {
      return _settlingPage!;
    }
    if (_dragOffset < 0 && _currentPage < cards.length - 1) {
      return _currentPage + 1;
    }
    if (_dragOffset > 0 && _currentPage > 0) {
      return _currentPage - 1;
    }
    return _currentPage;
  }

  void _handleHorizontalDragUpdate(
    DragUpdateDetails details,
    BoxConstraints constraints,
  ) {
    _stopSettleAnimation();
    final width = constraints.maxWidth;
    final proposedOffset = (_dragOffset + details.delta.dx).clamp(
      -width,
      width,
    );
    final canDragNext =
        proposedOffset < 0 && _currentPage < widget.cards.length - 1;
    final canDragPrevious = proposedOffset > 0 && _currentPage > 0;
    setState(() {
      _dragOffset = canDragNext || canDragPrevious ? proposedOffset : 0;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details, double width) {
    final velocity =
        details.primaryVelocity ?? details.velocity.pixelsPerSecond.dx;
    final shouldAdvance =
        (_dragOffset < -width * _pageTurnDistanceFraction ||
            velocity < -_pageTurnVelocity) &&
        _currentPage < widget.cards.length - 1;
    final shouldGoBack =
        (_dragOffset > width * _pageTurnDistanceFraction ||
            velocity > _pageTurnVelocity) &&
        _currentPage > 0;

    if (shouldAdvance) {
      _animateToPageOffset(width: -width, targetPage: _currentPage + 1);
    } else if (shouldGoBack) {
      _animateToPageOffset(width: width, targetPage: _currentPage - 1);
    } else {
      _animateToPageOffset(width: 0);
    }
  }

  void _animateToPageOffset({required double width, int? targetPage}) {
    _settleController.stop();
    _settlingPage = targetPage;
    _settleAnimation = Tween<double>(begin: _dragOffset, end: width).animate(
      CurvedAnimation(parent: _settleController, curve: Curves.easeOutCubic),
    );
    _settleController
      ..reset()
      ..forward();
  }

  void _stopSettleAnimation() {
    if (!_settleController.isAnimating) {
      return;
    }
    _settleController.stop();
    _settlingPage = null;
    _settleAnimation = null;
  }

  double _activeCardHeight(List<InsightFeedCard> cards, double width) {
    if (cards.isEmpty) {
      return 0;
    }
    final currentHeight = _cardHeight(cards[_currentPage]);
    final targetPage = _targetPage(cards);
    if (targetPage == _currentPage) {
      return currentHeight;
    }
    final targetHeight = _cardHeight(cards[targetPage]);
    final progress = width <= 0
        ? 0.0
        : (_dragOffset.abs() / width).clamp(0.0, 1.0);
    return currentHeight + (targetHeight - currentHeight) * progress;
  }

  double _cardHeight(InsightFeedCard card) {
    final hasVisual =
        card.visualType != InsightFeedVisualType.none &&
        card.visualData.isNotEmpty;
    if (card.visualType == InsightFeedVisualType.awardPreview && hasVisual) {
      return 142;
    }
    if (card.type == InsightFeedCardType.workoutMotivation && !hasVisual) {
      return _estimatedMotivationCardHeight(card);
    }
    if (!hasVisual) {
      return 148;
    }
    if (card.visualType == InsightFeedVisualType.radar) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 216,
        InsightFeedCardSize.wide => 256,
        InsightFeedCardSize.featured => 344,
      };
    }
    if (card.visualType == InsightFeedVisualType.baselineBars) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 232,
        InsightFeedCardSize.wide => 248,
        InsightFeedCardSize.featured => 414,
      };
    }
    if (card.visualType == InsightFeedVisualType.trainingVelocityLine) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 280,
        InsightFeedCardSize.wide => 312,
        InsightFeedCardSize.featured => 454,
      };
    }
    if (card.visualType == InsightFeedVisualType.bodyWeightLine) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 244,
        InsightFeedCardSize.wide => 300,
        InsightFeedCardSize.featured => 420,
      };
    }
    if (card.visualType == InsightFeedVisualType.balanceFingerprint) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 244,
        InsightFeedCardSize.wide => 300,
        InsightFeedCardSize.featured => 420,
      };
    }
    if (card.visualType == InsightFeedVisualType.calendarStrip) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 196,
        InsightFeedCardSize.wide => 236,
        InsightFeedCardSize.featured => 368,
      };
    }
    return switch (card.size) {
      InsightFeedCardSize.compact => 220,
      InsightFeedCardSize.wide => 264,
      InsightFeedCardSize.featured => 396,
    };
  }

  double _estimatedMotivationCardHeight(InsightFeedCard card) {
    final titleLines = _estimatedLineCount(
      card.title,
      charactersPerLine: 18,
      maxLines: 2,
    );
    final bodyLines = _estimatedLineCount(
      card.body,
      charactersPerLine: 30,
      maxLines: 3,
    );
    final estimatedHeight = 84 + (titleLines - 1) * 20 + (bodyLines - 1) * 22;
    return estimatedHeight.clamp(104, 148).toDouble();
  }
}

class _InsightFeedPageDots extends StatelessWidget {
  const _InsightFeedPageDots({
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      key: const Key('insight_feed_page_dots'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: isActive ? 16 : 6,
          height: 6,
          margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
          decoration: BoxDecoration(
            color: isActive ? colors.textTertiary : colors.field,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _InsightFeedStackHeader extends StatelessWidget {
  const _InsightFeedStackHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title.toUpperCase(),
        style: context.appText.labelMedium?.copyWith(
          color: context.appColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// policy: allow-public-api shared feed card renderer for insights feed entries.
class InsightFeedCardWidget extends StatelessWidget {
  const InsightFeedCardWidget({super.key, required this.card});

  final InsightFeedCard card;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;
    final accent = _accentColor(context, card.accent);
    final hasVisual =
        card.visualType != InsightFeedVisualType.none &&
        card.visualData.isNotEmpty;

    if (card.visualType == InsightFeedVisualType.awardPreview && hasVisual) {
      return _AwardInsightFeedCard(
        card: card,
        accent: accent,
        icon: _iconFor(card.icon),
      );
    }

    if (hasVisual) {
      return _VisualInsightFeedCard(
        card: card,
        accent: accent,
        icon: _iconFor(card.icon),
      );
    }

    return Container(
      constraints: BoxConstraints(
        minHeight: card.type == InsightFeedCardType.workoutMotivation
            ? _estimatedMotivationMinHeight(card)
            : 132,
      ),
      padding: const EdgeInsets.all(16),
      decoration: _insightCardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(card.icon), color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        card.title,
                        style: textTheme.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (card.metric.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        card.metric,
                        style: textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  card.body,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _accentColor(BuildContext context, String accent) {
    final colors = context.appColors;
    final scheme = context.appScheme;
    return switch (accent) {
      'success' => colors.success,
      'warning' => colors.warning,
      'info' => colors.info,
      'primary' => scheme.primary,
      _ => scheme.primary,
    };
  }

  IconData _iconFor(String icon) {
    return switch (icon) {
      'award' => CupertinoIcons.rosette,
      'bolt' => CupertinoIcons.bolt_fill,
      'calendar' => CupertinoIcons.calendar,
      'chart' => CupertinoIcons.chart_bar_square_fill,
      'flame' => CupertinoIcons.flame_fill,
      'radar' => Icons.radar_outlined,
      'return' => CupertinoIcons.arrow_turn_up_left,
      'spark' => CupertinoIcons.sparkles,
      'weight' => Icons.monitor_weight_outlined,
      _ => CupertinoIcons.sparkles,
    };
  }

  double _estimatedMotivationMinHeight(InsightFeedCard card) {
    final titleLines = _estimatedLineCount(
      card.title,
      charactersPerLine: 18,
      maxLines: 2,
    );
    final bodyLines = _estimatedLineCount(
      card.body,
      charactersPerLine: 30,
      maxLines: 3,
    );
    final estimatedHeight = 88 + (titleLines - 1) * 18 + (bodyLines - 1) * 20;
    return estimatedHeight.clamp(96, 132).toDouble();
  }
}

class _AwardInsightFeedCard extends StatelessWidget {
  const _AwardInsightFeedCard({
    required this.card,
    required this.accent,
    required this.icon,
  });

  final InsightFeedCard card;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;
    final achievements = _achievementsFromVisualData(card.visualData);
    final awards = buildWorkoutAchievementAwards(context, achievements);
    if (awards.isEmpty) {
      return const SizedBox.shrink();
    }
    final award = awards.first;

    return KeyedSubtree(
      key: const Key('insight_feed_visual_awardPreview'),
      child: Material(
        color: colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.workoutCardBorderRadius,
          onTap: () => showAwardDetailSheet(context, [award]),
          child: Container(
            constraints: const BoxConstraints(minHeight: 142),
            padding: const EdgeInsets.fromLTRB(16, 16, 10, 10),
            decoration: _insightCardDecoration(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            key: const Key('insight_feed_award_icon_container'),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.title,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  card.body,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textSecondary,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: award.title,
                  child: Semantics(
                    button: true,
                    label: 'View ${award.title} award',
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: Center(
                        child: AwardThumbnailImage(award: award, size: 84),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisualInsightFeedCard extends StatelessWidget {
  const _VisualInsightFeedCard({
    required this.card,
    required this.accent,
    required this.icon,
  });

  final InsightFeedCard card;
  final Color accent;
  final IconData icon;

  bool get _isRadarCard => card.visualType == InsightFeedVisualType.radar;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;
    final showMetric =
        card.metric.isNotEmpty &&
        card.visualType != InsightFeedVisualType.radar;
    final showComparisonLabel =
        card.comparisonLabel != null &&
        card.visualType != InsightFeedVisualType.radar &&
        card.visualType != InsightFeedVisualType.baselineBars &&
        card.visualType != InsightFeedVisualType.trainingVelocityLine &&
        card.visualType != InsightFeedVisualType.bodyWeightLine &&
        card.visualType != InsightFeedVisualType.balanceFingerprint;

    return Container(
      constraints: BoxConstraints(minHeight: _minHeight()),
      padding: EdgeInsets.all(_isRadarCard ? 14 : 16),
      decoration: _insightCardDecoration(context),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            card.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (showMetric) ...[
                          const SizedBox(width: 10),
                          _RotatingInsightMetric(
                            values: _metricValues(),
                            color: accent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                    if (showComparisonLabel) ...[
                      const SizedBox(height: 8),
                      Text(
                        card.comparisonLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: _isRadarCard ? 18 : 16),
          if (_usesFlexibleVisual)
            Expanded(
              child: _InsightFeedVisualContent(card: card, accent: accent),
            )
          else
            SizedBox(
              height: _visualHeight(),
              child: _InsightFeedVisualContent(card: card, accent: accent),
            ),
        ],
      ),
    );
  }

  bool get _usesFlexibleVisual =>
      card.visualType == InsightFeedVisualType.calendarStrip;

  double _minHeight() {
    if (card.visualType == InsightFeedVisualType.awardPreview) {
      return 225;
    }
    if (card.visualType == InsightFeedVisualType.baselineBars) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 232,
        InsightFeedCardSize.wide => 248,
        InsightFeedCardSize.featured => 414,
      };
    }
    if (card.visualType == InsightFeedVisualType.trainingVelocityLine) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 280,
        InsightFeedCardSize.wide => 312,
        InsightFeedCardSize.featured => 454,
      };
    }
    if (card.visualType == InsightFeedVisualType.bodyWeightLine) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 244,
        InsightFeedCardSize.wide => 300,
        InsightFeedCardSize.featured => 420,
      };
    }
    if (card.visualType == InsightFeedVisualType.balanceFingerprint) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 244,
        InsightFeedCardSize.wide => 300,
        InsightFeedCardSize.featured => 420,
      };
    }
    if (card.visualType == InsightFeedVisualType.calendarStrip) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 196,
        InsightFeedCardSize.wide => 236,
        InsightFeedCardSize.featured => 368,
      };
    }
    if (_isRadarCard) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 216,
        InsightFeedCardSize.wide => 256,
        InsightFeedCardSize.featured => 344,
      };
    }
    return switch (card.size) {
      InsightFeedCardSize.compact => 220,
      InsightFeedCardSize.wide => 264,
      InsightFeedCardSize.featured => 396,
    };
  }

  double _visualHeight() {
    if (card.visualType == InsightFeedVisualType.awardPreview) {
      return 100;
    }
    if (card.visualType == InsightFeedVisualType.baselineBars) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 88,
        InsightFeedCardSize.wide => 126,
        InsightFeedCardSize.featured => 244,
      };
    }
    if (card.visualType == InsightFeedVisualType.trainingVelocityLine) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 154,
        InsightFeedCardSize.wide => 206,
        InsightFeedCardSize.featured => 306,
      };
    }
    if (card.visualType == InsightFeedVisualType.bodyWeightLine) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 112,
        InsightFeedCardSize.wide => 168,
        InsightFeedCardSize.featured => 282,
      };
    }
    if (card.visualType == InsightFeedVisualType.balanceFingerprint) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 112,
        InsightFeedCardSize.wide => 168,
        InsightFeedCardSize.featured => 282,
      };
    }
    if (card.visualType == InsightFeedVisualType.calendarStrip) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 92,
        InsightFeedCardSize.wide => 138,
        InsightFeedCardSize.featured => 252,
      };
    }
    if (_isRadarCard) {
      return switch (card.size) {
        InsightFeedCardSize.compact => 82,
        InsightFeedCardSize.wide => 116,
        InsightFeedCardSize.featured => 222,
      };
    }
    return switch (card.size) {
      InsightFeedCardSize.compact => 76,
      InsightFeedCardSize.wide => 112,
      InsightFeedCardSize.featured => 230,
    };
  }

  List<String> _metricValues() {
    if (card.visualType != InsightFeedVisualType.baselineBars) {
      return [card.metric];
    }
    final values = _listOfMaps(card.visualData['items'])
        .map((item) => _signedPercentLabel(_string(item['deltaLabel'])))
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    return values.isEmpty ? [card.metric] : values;
  }
}

class _RotatingInsightMetric extends StatefulWidget {
  const _RotatingInsightMetric({required this.values, required this.color});

  final List<String> values;
  final Color color;

  @override
  State<_RotatingInsightMetric> createState() => _RotatingInsightMetricState();
}

class _RotatingInsightMetricState extends State<_RotatingInsightMetric> {
  Timer? _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _configureTimer();
  }

  @override
  void didUpdateWidget(covariant _RotatingInsightMetric oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameValues(widget.values, oldWidget.values)) {
      _index = 0;
      _configureTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _configureTimer() {
    _timer?.cancel();
    if (widget.values.length < 2) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _index = (_index + 1) % widget.values.length;
      });
    });
  }

  bool _sameValues(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = math.min(_index, widget.values.length - 1);
    final value = widget.values[safeIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: Text(
        value,
        key: ValueKey(value),
        style: context.appText.titleMedium?.copyWith(
          color: widget.color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InsightFeedVisualContent extends StatelessWidget {
  const _InsightFeedVisualContent({required this.card, required this.accent});

  final InsightFeedCard card;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: Key('insight_feed_visual_${card.visualType.name}'),
      child: switch (card.visualType) {
        InsightFeedVisualType.baselineBars => _BaselineBarsVisual(
          data: card.visualData,
          accent: accent,
        ),
        InsightFeedVisualType.trainingVelocityLine =>
          _TrainingVelocityLineVisual(data: card.visualData, accent: accent),
        InsightFeedVisualType.calendarStrip => _CalendarStripVisual(
          data: card.visualData,
          accent: accent,
        ),
        InsightFeedVisualType.sparklineBand => _SparklineBandVisual(
          data: card.visualData,
          accent: accent,
        ),
        InsightFeedVisualType.percentileDot => _PercentileDotVisual(
          data: card.visualData,
          accent: accent,
        ),
        InsightFeedVisualType.radar => _RadarVisual(
          data: card.visualData,
          accent: accent,
        ),
        InsightFeedVisualType.bodyWeightLine => _SparklineBandVisual(
          data: card.visualData,
          accent: accent,
          smooth: true,
        ),
        InsightFeedVisualType.balanceFingerprint => _BalanceFingerprintVisual(
          data: card.visualData,
          accent: accent,
        ),
        InsightFeedVisualType.coachNote => const SizedBox.shrink(),
        InsightFeedVisualType.awardPreview => const SizedBox.shrink(),
        InsightFeedVisualType.none => const SizedBox.shrink(),
      },
    );
  }
}

class _BaselineBarsVisual extends StatefulWidget {
  const _BaselineBarsVisual({required this.data, required this.accent});

  final Map<String, Object?> data;
  final Color accent;

  @override
  State<_BaselineBarsVisual> createState() => _BaselineBarsVisualState();
}

class _BaselineBarsVisualState extends State<_BaselineBarsVisual> {
  late final ChartSeriesVisibilityController _visibilityController =
      ChartSeriesVisibilityController(series: _legendSeries);

  List<ChartLegendSeries> get _legendSeries => [
    ChartLegendSeries(
      id: _baselineSeriesId,
      label: 'baseline',
      color: context.appColors.textTertiary,
    ),
    ChartLegendSeries(
      id: _latestSeriesId,
      label: 'latest',
      color: widget.accent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _listOfMaps(widget.data['items']);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    if (items.first.containsKey('baseline')) {
      return AnimatedBuilder(
        animation: _visibilityController,
        builder: (context, child) {
          final showBaseline = _visibilityController.isVisible(
            _baselineSeriesId,
          );
          final showLatest = _visibilityController.isVisible(_latestSeriesId);
          return Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final item in items) ...[
                      Expanded(
                        child: _ComparisonMetricBars(
                          item: item,
                          accent: widget.accent,
                          showBaseline: showBaseline,
                          showActual: showLatest,
                        ),
                      ),
                      if (item != items.last) const SizedBox(width: 14),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TappableChartLegend(
                series: _legendSeries,
                controller: _visibilityController,
                isInteractive: false,
                keyPrefix: 'insight_feed_baseline_bars_legend',
              ),
            ],
          );
        },
      );
    }

    final maxValue = items
        .map((item) => _num(item['value']))
        .fold<double>(0, math.max)
        .clamp(1, double.infinity)
        .toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final item in items) ...[
          Expanded(
            child: _SingleMetricBar(
              label: _string(item['label']),
              value: _num(item['value']),
              maxValue: maxValue,
              accent: item == items.last
                  ? widget.accent
                  : context.appColors.textTertiary,
            ),
          ),
          if (item != items.last) const SizedBox(width: 18),
        ],
      ],
    );
  }
}

class _SingleMetricBar extends StatelessWidget {
  const _SingleMetricBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.accent,
  });

  final String label;
  final double value;
  final double maxValue;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;
    final factor = (value / maxValue).clamp(0.08, 1.0).toDouble();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: factor,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value.toStringAsFixed(value >= 10 ? 0 : 1),
          textAlign: TextAlign.center,
          style: textTheme.labelMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }
}

class _ComparisonMetricBars extends StatelessWidget {
  const _ComparisonMetricBars({
    required this.item,
    required this.accent,
    required this.showBaseline,
    required this.showActual,
  });

  final Map<String, Object?> item;
  final Color accent;
  final bool showBaseline;
  final bool showActual;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;
    final baseline = _num(item['baseline']);
    final actual = _num(item['actual']);
    final deltaLabel = _string(item['deltaLabel']);
    final maxValue = math.max(math.max(baseline, actual), 1);
    final baselineHeight = (baseline / maxValue).clamp(0.08, 1.0).toDouble();
    final actualHeight = (actual / maxValue).clamp(0.08, 1.0).toDouble();

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showBaseline)
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor: baselineHeight,
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      key: const Key('insight_feed_baseline_bar'),
                      decoration: BoxDecoration(
                        color: colors.textTertiary.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              if (showBaseline && showActual) const SizedBox(width: 4),
              if (showActual)
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor: actualHeight,
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      key: const Key('insight_feed_latest_bar'),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: deltaLabel.isEmpty
                          ? null
                          : Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    deltaLabel,
                                    maxLines: 1,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: context.appScheme.onPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _string(item['label']),
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CalendarStripVisual extends StatefulWidget {
  const _CalendarStripVisual({required this.data, required this.accent});

  final Map<String, Object?> data;
  final Color accent;

  @override
  State<_CalendarStripVisual> createState() => _CalendarStripVisualState();
}

class _CalendarStripVisualState extends State<_CalendarStripVisual> {
  final ScrollController _scrollController = ScrollController();
  bool _didSetInitialScroll = false;

  @override
  void didUpdateWidget(covariant _CalendarStripVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _didSetInitialScroll = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recent = _boolList(widget.data['recentDays']);
    final baseline = _boolList(widget.data['baselineDays']);
    final future = List<bool>.filled(3, false, growable: false);
    final baselineLabels = _dayLabels(
      widget.data['baselineLabels'],
      fallbackCount: baseline.length,
    );
    final recentLabels = _dayLabels(
      widget.data['recentLabels'],
      fallbackCount: recent.length,
    );
    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }

    final days = [...baseline, ...recent, ...future];
    final labels = [...baselineLabels, ...recentLabels];
    final todayIndex = baseline.length + recent.length - 1;
    final hasWorkoutToday = todayIndex >= 0 && todayIndex < days.length
        ? days[todayIndex]
        : false;
    _scheduleInitialTimelineScroll(todayIndex);

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: _rhythmTimelineVerticalCompactFactor,
              child: _RhythmTimelinePlot(
                controller: _scrollController,
                days: days,
                labels: labels,
                todayIndex: todayIndex,
                hasWorkoutToday: hasWorkoutToday,
                accent: widget.accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          key: const Key('insight_feed_rhythm_workout_legend'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: widget.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Workout day',
              style: context.appText.labelSmall?.copyWith(
                color: context.appColors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _scheduleInitialTimelineScroll(int todayIndex) {
    if (_didSetInitialScroll) {
      return;
    }
    _didSetInitialScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final target = math.max(
        0.0,
        todayIndex * _rhythmTimelineStep - _rhythmTimelineViewportInset,
      );
      _scrollController.jumpTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    });
  }
}

const double _rhythmTimelineTickWidth = 18;
const double _rhythmTimelineIndicatorWidth = 10;
const double _rhythmTimelineTickGap = 0.5;
const double _rhythmTimelineStep =
    _rhythmTimelineTickWidth + _rhythmTimelineTickGap;
const double _rhythmTimelineHorizontalPadding = 12;
const double _rhythmTimelineViewportInset = 170;
const double _rhythmTimelineEdgeTaperWidth = 54;
const double _rhythmTimelineLabelEdgeLift = 24;
const double _rhythmTimelineLabelHeight = 18;
const double _rhythmTimelineVerticalCompactFactor = 0.9;

class _RhythmTimelinePlot extends StatelessWidget {
  const _RhythmTimelinePlot({
    required this.controller,
    required this.days,
    required this.labels,
    required this.todayIndex,
    required this.hasWorkoutToday,
    required this.accent,
  });

  final ScrollController controller;
  final List<bool> days;
  final List<String> labels;
  final int todayIndex;
  final bool hasWorkoutToday;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }
    final totalWidth =
        _rhythmTimelineHorizontalPadding * 2 +
        days.length * _rhythmTimelineTickWidth +
        math.max(0, days.length - 1) * _rhythmTimelineTickGap;

    return LayoutBuilder(
      builder: (context, viewportConstraints) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final scrollOffset = controller.hasClients
                ? controller.offset
                : 0.0;
            return SingleChildScrollView(
              key: const Key('insight_feed_rhythm_timeline_scroll'),
              controller: controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                key: const Key('insight_feed_rhythm_timeline_plot'),
                width: totalWidth,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildTickRow(
                        scrollOffset: scrollOffset,
                        viewportWidth: viewportConstraints.maxWidth,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: _rhythmTimelineLabelHeight,
                      child: _buildLabelRow(
                        scrollOffset: scrollOffset,
                        viewportWidth: viewportConstraints.maxWidth,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTickRow({
    required double scrollOffset,
    required double viewportWidth,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _rhythmTimelineHorizontalPadding,
      ),
      child: Row(
        children: [
          for (var index = 0; index < days.length; index++) ...[
            SizedBox(
              width: _rhythmTimelineTickWidth,
              child: _RhythmTimelineTick(
                key: Key('insight_feed_rhythm_tick_$index'),
                isActive: days[index],
                isFuture: index > todayIndex,
                isToday: index == todayIndex,
                color: accent,
                heightFactor: _heightFactorForTick(
                  index: index,
                  scrollOffset: scrollOffset,
                  viewportWidth: viewportWidth,
                ),
              ),
            ),
            if (index != days.length - 1)
              const SizedBox(width: _rhythmTimelineTickGap),
          ],
        ],
      ),
    );
  }

  Widget _buildLabelRow({
    required double scrollOffset,
    required double viewportWidth,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _rhythmTimelineHorizontalPadding,
      ),
      child: Row(
        children: [
          for (var index = 0; index < days.length; index++) ...[
            SizedBox(
              width: _rhythmTimelineTickWidth,
              child: _RhythmTimelineLabel(
                label: _rhythmTimelineLabelAt(
                  labels: labels,
                  index: index,
                  todayIndex: todayIndex,
                ),
                isToday: index == todayIndex,
                highlightToday: hasWorkoutToday,
                isActive: days[index],
                accent: accent,
                edgeFactor: _heightFactorForTick(
                  index: index,
                  scrollOffset: scrollOffset,
                  viewportWidth: viewportWidth,
                ),
              ),
            ),
            if (index != days.length - 1)
              const SizedBox(width: _rhythmTimelineTickGap),
          ],
        ],
      ),
    );
  }

  double _heightFactorForTick({
    required int index,
    required double scrollOffset,
    required double viewportWidth,
  }) {
    final centerX =
        _rhythmTimelineHorizontalPadding +
        index * _rhythmTimelineStep +
        _rhythmTimelineTickWidth / 2;
    final viewportX = centerX - scrollOffset;
    final distanceToEdge = math.min(viewportX, viewportWidth - viewportX);
    final edgeProgress = (distanceToEdge / _rhythmTimelineEdgeTaperWidth).clamp(
      0.0,
      1.0,
    );
    final eased = Curves.easeOutCubic.transform(edgeProgress);
    return 0.38 + eased * 0.62;
  }
}

class _RhythmTimelineLabel extends StatelessWidget {
  const _RhythmTimelineLabel({
    required this.label,
    required this.isToday,
    required this.highlightToday,
    required this.isActive,
    required this.accent,
    required this.edgeFactor,
  });

  final String label;
  final bool isToday;
  final bool highlightToday;
  final bool isActive;
  final Color accent;
  final double edgeFactor;

  @override
  Widget build(BuildContext context) {
    final style = context.appText.labelSmall?.copyWith(
      color: isToday && highlightToday
          ? accent
          : context.appColors.textTertiary,
      fontWeight: FontWeight.w700,
    );
    final edgeFalloff = Curves.easeInOutCubic.transform(1 - edgeFactor);
    final curvedLabel = Transform.translate(
      offset: Offset(0, -edgeFalloff * _rhythmTimelineLabelEdgeLift),
      child: Transform.scale(
        scale: 0.56 + edgeFactor * 0.44,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          opacity: 0.18 + edgeFactor * 0.82,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: style,
          ),
        ),
      ),
    );
    if (isToday) {
      return OverflowBox(
        minWidth: 0,
        maxWidth: 56,
        alignment: Alignment.center,
        child: curvedLabel,
      );
    }
    return curvedLabel;
  }
}

String _rhythmTimelineLabelAt({
  required List<String> labels,
  required int index,
  required int todayIndex,
}) {
  if (index >= labels.length || index > todayIndex) {
    return '';
  }
  final label = labels[index];
  final previousLabel = index == 0 ? '' : labels[index - 1];
  final month = _monthPart(label);
  final previousMonth = _monthPart(previousLabel);
  if (month.isNotEmpty && month != previousMonth) {
    return month;
  }
  if (index == todayIndex) {
    return 'Today';
  }
  if (index == labels.length - 1 || index % 7 == 0) {
    return _dayPart(label);
  }
  return '';
}

String _monthPart(String label) {
  final parts = label.trim().split(RegExp(r'\s+'));
  return parts.length > 1 ? parts.sublist(1).join(' ') : '';
}

String _dayPart(String label) {
  final parts = label.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? '' : parts.first;
}

class _RhythmTimelineTick extends StatelessWidget {
  const _RhythmTimelineTick({
    super.key,
    required this.isActive,
    required this.isFuture,
    required this.isToday,
    required this.color,
    required this.heightFactor,
  });

  final bool isActive;
  final bool isFuture;
  final bool isToday;
  final Color color;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        heightFactor: heightFactor,
        child: SizedBox(
          width: _rhythmTimelineIndicatorWidth,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isToday
                  ? (isActive ? color : context.appScheme.onSurface)
                  : isActive
                  ? color.withValues(alpha: 0.92)
                  : context.appColors.field.withValues(
                      alpha: isFuture ? 0.38 : 0.72,
                    ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _DynamicXAxisLabelRow extends StatelessWidget {
  const _DynamicXAxisLabelRow({required this.labels});

  final List<DynamicChartLabelPoint> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const SizedBox(height: 14);
    }
    final style = context.appText.labelSmall?.copyWith(
      color: context.appColors.textTertiary,
      fontWeight: FontWeight.w700,
    );
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final label in labels)
                Positioned(
                  left: (label.position - (_dynamicXLabelWidth / 2)).clamp(
                    0,
                    math.max(0, constraints.maxWidth - _dynamicXLabelWidth),
                  ),
                  width: _dynamicXLabelWidth,
                  child: Text(
                    label.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TrainingVelocityLineVisual extends StatefulWidget {
  const _TrainingVelocityLineVisual({required this.data, required this.accent});

  final Map<String, Object?> data;
  final Color accent;

  @override
  State<_TrainingVelocityLineVisual> createState() =>
      _TrainingVelocityLineVisualState();
}

class _TrainingVelocityLineVisualState
    extends State<_TrainingVelocityLineVisual> {
  late final ChartSeriesVisibilityController _visibilityController =
      ChartSeriesVisibilityController(series: _legendSeries);

  @override
  Widget build(BuildContext context) {
    final points = _listOfMaps(widget.data['points']);
    final values = points.map((point) => _num(point['value'])).toList();
    if (values.length < 2) {
      return const SizedBox.shrink();
    }
    final labels = points.map((point) => _string(point['label'])).toList();

    final average = _nullableNum(widget.data['average']);
    final summaryItems = _listOfMaps(widget.data['summaryItems']);
    final weeklyLegend = summaryItems.isNotEmpty
        ? _summaryLegendLabel(summaryItems.first)
        : _string(widget.data['seriesLabel']);
    final averageLegend = summaryItems.length > 1
        ? _summaryLegendLabel(summaryItems[1])
        : _string(widget.data['averageLabel']);
    final legendSeries = _legendSeriesFor(
      weeklyLabel: weeklyLegend.isEmpty ? '7d' : weeklyLegend,
      averageLabel: averageLegend.isEmpty ? 'base' : averageLegend,
    );

    return AnimatedBuilder(
      animation: _visibilityController,
      builder: (context, child) {
        return Column(
          children: [
            Expanded(
              child: CustomPaint(
                key: const Key('insight_feed_velocity_plot'),
                painter: _VelocityLinePainter(
                  values: values,
                  average: average,
                  showValues: _visibilityController.isVisible(_primarySeriesId),
                  showAverage: _visibilityController.isVisible(
                    _averageSeriesId,
                  ),
                  color: widget.accent,
                  averageColor: context.appColors.textSecondary,
                  gridColor: Theme.of(context).dividerColor,
                  labelStyle: context.appText.labelSmall!.copyWith(
                    color: context.appColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  pointFillColor: context.appScheme.surface,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 4),
            _DynamicVelocityLabelRow(values: values, labels: labels),
            const SizedBox(height: 8),
            TappableChartLegend(
              series: legendSeries,
              controller: _visibilityController,
              dotSize: 7,
              runSpacing: 6,
              keyPrefix: 'insight_feed_velocity_legend',
            ),
          ],
        );
      },
    );
  }

  List<ChartLegendSeries> get _legendSeries => [
    ChartLegendSeries(id: _primarySeriesId, label: '7d', color: widget.accent),
    ChartLegendSeries(
      id: _averageSeriesId,
      label: 'base',
      color: context.appColors.textSecondary,
    ),
  ];

  List<ChartLegendSeries> _legendSeriesFor({
    required String weeklyLabel,
    required String averageLabel,
  }) {
    return [
      ChartLegendSeries(
        id: _primarySeriesId,
        label: weeklyLabel,
        color: widget.accent,
      ),
      ChartLegendSeries(
        id: _averageSeriesId,
        label: averageLabel,
        color: context.appColors.textSecondary,
      ),
    ];
  }

  String _summaryLegendLabel(Map<String, Object?> item) {
    final value = _string(item['displayValue']).isEmpty
        ? _num(item['value']).toStringAsFixed(1)
        : _string(item['displayValue']);
    return '${_string(item['label'])} $value';
  }
}

class _DynamicVelocityLabelRow extends StatelessWidget {
  const _DynamicVelocityLabelRow({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || labels.length != values.length) {
      return const SizedBox(height: 14);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final plotWidth = math
            .max(
              1,
              constraints.maxWidth -
                  _insightLinePlotLeftPadding -
                  _insightLinePlotRightPadding,
            )
            .toDouble();
        final focusStart = math.max(0, values.length - 5);
        final focusLeft = _insightLinePlotLeftPadding + plotWidth * 0.54;
        final positions = List.generate(values.length, (index) {
          return _velocityXForIndex(
            index: index,
            count: values.length,
            focusStart: focusStart,
            plotLeft: _insightLinePlotLeftPadding,
            plotRight: _insightLinePlotLeftPadding + plotWidth,
            focusLeft: focusLeft,
          );
        });
        final selected = selectDynamicChartLabels(
          candidates: buildExtremaLabelCandidates(
            values: values,
            labels: labels,
            positions: positions,
          ),
          minPixelGap: _dynamicXLabelMinGap,
          maxLabelCount: _maxDynamicLabelCount(plotWidth),
        );
        return _DynamicXAxisLabelRow(labels: selected);
      },
    );
  }
}

class _SparklineBandVisual extends StatefulWidget {
  const _SparklineBandVisual({
    required this.data,
    required this.accent,
    this.smooth = false,
  });

  final Map<String, Object?> data;
  final Color accent;
  final bool smooth;

  @override
  State<_SparklineBandVisual> createState() => _SparklineBandVisualState();
}

class _SparklineBandVisualState extends State<_SparklineBandVisual> {
  late final ChartSeriesVisibilityController _visibilityController =
      ChartSeriesVisibilityController(series: _legendSeries);

  @override
  Widget build(BuildContext context) {
    final points = _listOfMaps(widget.data['points']);
    final values = points.map((point) => _num(point['value'])).toList();
    if (values.length < 2) {
      return const SizedBox.shrink();
    }
    final unit = _string(widget.data['unit']);
    final firstLabel = _string(points.first['label']);
    final lastLabel = _string(points.last['label']);
    final pointLabels = points.map((point) => _string(point['label'])).toList();
    final referenceValues = widget.smooth
        ? _rollingAverageValues(points, values, windowDays: 30)
        : null;
    final baseline = widget.smooth
        ? null
        : _nullableNum(widget.data['baseline']);
    final showReference = referenceValues != null || baseline != null;
    final legendSeries = _legendSeriesFor(
      primaryLabel: widget.smooth ? 'logged weight' : _sparklineUnitLabel(unit),
      includeReference: showReference,
      referenceLabel: widget.smooth ? 'avg / 1m' : 'previous best',
    );

    return AnimatedBuilder(
      animation: _visibilityController,
      builder: (context, child) {
        final isPrimaryVisible = _visibilityController.isVisible(
          _primarySeriesId,
        );
        final isReferenceVisible =
            showReference &&
            _visibilityController.isVisible(_referenceSeriesId);

        return Column(
          children: [
            Expanded(
              child: CustomPaint(
                key: const Key('insight_feed_sparkline_plot'),
                painter: _SparklinePainter(
                  values: values,
                  baseline: baseline,
                  referenceValues: referenceValues,
                  showPrimary: isPrimaryVisible,
                  showReference: isReferenceVisible,
                  color: widget.accent,
                  gridColor: widget.smooth
                      ? context.appColors.textSecondary
                      : Theme.of(context).dividerColor,
                  fillColor: widget.accent.withValues(
                    alpha: widget.smooth ? 0.12 : 0.16,
                  ),
                  labelStyle: context.appText.labelSmall!.copyWith(
                    color: context.appColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  smooth: widget.smooth,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            if (firstLabel.isNotEmpty || lastLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              if (widget.smooth)
                _DynamicLinearLabelRow(values: values, labels: pointLabels)
              else
                Row(
                  children: [
                    Text(
                      firstLabel,
                      style: context.appText.labelSmall?.copyWith(
                        color: context.appColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      lastLabel,
                      style: context.appText.labelSmall?.copyWith(
                        color: context.appColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 8),
            TappableChartLegend(
              series: legendSeries,
              controller: _visibilityController,
              keyPrefix: 'insight_feed_sparkline_legend',
            ),
          ],
        );
      },
    );
  }

  List<ChartLegendSeries> get _legendSeries => [
    ChartLegendSeries(
      id: _primarySeriesId,
      label: widget.smooth ? 'logged weight' : 'trend',
      color: widget.accent,
    ),
    ChartLegendSeries(
      id: _referenceSeriesId,
      label: widget.smooth ? 'avg / 1m' : 'previous best',
      color: context.appColors.textTertiary,
    ),
  ];

  List<ChartLegendSeries> _legendSeriesFor({
    required String primaryLabel,
    required bool includeReference,
    required String referenceLabel,
  }) {
    return [
      ChartLegendSeries(
        id: _primarySeriesId,
        label: primaryLabel,
        color: widget.accent,
      ),
      if (includeReference)
        ChartLegendSeries(
          id: _referenceSeriesId,
          label: referenceLabel,
          color: context.appColors.textTertiary,
        ),
    ];
  }

  String _sparklineUnitLabel(String unit) {
    return switch (unit) {
      'volume' => 'volume',
      '' => 'trend',
      _ => unit,
    };
  }

  List<double>? _rollingAverageValues(
    List<Map<String, Object?>> points,
    List<double> values, {
    required int windowDays,
  }) {
    final dates = <DateTime>[];

    for (var index = 0; index < points.length; index++) {
      final rawDate = points[index]['date'];
      if (rawDate is! String) {
        return null;
      }
      final parsed = DateTime.tryParse(rawDate);
      if (parsed == null) {
        return null;
      }
      final local = parsed.toLocal();
      dates.add(DateTime(local.year, local.month, local.day));
    }

    return List.generate(values.length, (index) {
      final windowStart = dates[index].subtract(Duration(days: windowDays - 1));
      var sum = 0.0;
      var count = 0;
      for (var candidate = 0; candidate <= index; candidate++) {
        if (!dates[candidate].isBefore(windowStart) &&
            !dates[candidate].isAfter(dates[index])) {
          sum += values[candidate];
          count++;
        }
      }
      return count == 0 ? values[index] : sum / count;
    }, growable: false);
  }
}

class _DynamicLinearLabelRow extends StatelessWidget {
  const _DynamicLinearLabelRow({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || labels.length != values.length) {
      return const SizedBox(height: 14);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final plotWidth = math
            .max(
              1,
              constraints.maxWidth -
                  _insightLinePlotLeftPadding -
                  _insightLinePlotRightPadding,
            )
            .toDouble();
        final positions = List.generate(values.length, (index) {
          return values.length == 1
              ? _insightLinePlotLeftPadding
              : _insightLinePlotLeftPadding +
                    (plotWidth * index / (values.length - 1));
        });
        final selected = selectDynamicChartLabels(
          candidates: buildExtremaLabelCandidates(
            values: values,
            labels: labels,
            positions: positions,
          ),
          minPixelGap: _dynamicXLabelMinGap,
          maxLabelCount: _maxDynamicLabelCount(plotWidth),
        );
        return _DynamicXAxisLabelRow(labels: selected);
      },
    );
  }
}

class _PercentileDotVisual extends StatelessWidget {
  const _PercentileDotVisual({required this.data, required this.accent});

  final Map<String, Object?> data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final percentile = _num(data['percentile']).clamp(0, 100).toDouble();
    final colors = context.appColors;
    final textTheme = context.appText;
    return LayoutBuilder(
      builder: (context, constraints) {
        final usableWidth = math.max(1.0, constraints.maxWidth - 24);
        return Column(
          children: [
            Text(
              'set count percentile',
              style: textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, plotConstraints) {
                  final plotHeight = plotConstraints.maxHeight;
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: plotHeight / 2 - 4,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.field,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Positioned(
                        left: usableWidth * (percentile / 100),
                        top: plotHeight / 2 - 12,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.28),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Text('Low', style: textTheme.labelSmall),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Text('Top', style: textTheme.labelSmall),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RadarVisual extends StatefulWidget {
  const _RadarVisual({required this.data, required this.accent});

  final Map<String, Object?> data;
  final Color accent;

  @override
  State<_RadarVisual> createState() => _RadarVisualState();
}

class _RadarVisualState extends State<_RadarVisual> {
  late final ChartSeriesVisibilityController _visibilityController =
      ChartSeriesVisibilityController(series: _legendSeries);

  @override
  Widget build(BuildContext context) {
    final points = _listOfMaps(widget.data['points']);
    if (points.length < 3) {
      return const SizedBox.shrink();
    }
    final textTheme = context.appText;
    final colors = context.appColors;
    final averageLabel = _string(widget.data['plannedLabel']).isEmpty
        ? 'recent average'
        : _string(widget.data['plannedLabel']);
    final latestLabel = _string(widget.data['actualLabel']).isEmpty
        ? 'Last workout'
        : _string(widget.data['actualLabel']);
    final averageColor = colors.textSecondary.withValues(alpha: 0.92);
    final legendSeries = [
      ChartLegendSeries(
        id: _latestSeriesId,
        label: latestLabel,
        color: widget.accent,
      ),
      ChartLegendSeries(
        id: _averageSeriesId,
        label: averageLabel,
        color: averageColor,
      ),
    ];

    return AnimatedBuilder(
      animation: _visibilityController,
      builder: (context, child) {
        return Column(
          children: [
            Expanded(
              child: _buildRadarChart(
                context: context,
                points: points,
                averageColor: averageColor,
                textTheme: textTheme,
                colors: colors,
              ),
            ),
            const SizedBox(height: 14),
            TappableChartLegend(
              series: legendSeries,
              controller: _visibilityController,
              spacing: 16,
              runSpacing: 6,
              dotSize: 9,
              keyPrefix: 'insight_feed_radar_legend',
            ),
          ],
        );
      },
    );
  }

  List<ChartLegendSeries> get _legendSeries => [
    ChartLegendSeries(
      id: _latestSeriesId,
      label: 'Last workout',
      color: widget.accent,
    ),
    ChartLegendSeries(
      id: _averageSeriesId,
      label: 'recent average',
      color: context.appColors.textSecondary.withValues(alpha: 0.92),
    ),
  ];

  Widget _buildRadarChart({
    required BuildContext context,
    required List<Map<String, Object?>> points,
    required Color averageColor,
    required TextTheme textTheme,
    required dynamic colors,
  }) {
    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        tickCount: 4,
        ticksTextStyle: textTheme.labelSmall?.copyWith(
          color: colors.transparent,
          fontSize: 1,
        ),
        radarBackgroundColor: colors.field.withValues(alpha: 0.18),
        radarBorderData: BorderSide(color: Theme.of(context).dividerColor),
        gridBorderData: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.75),
          width: 0.8,
        ),
        tickBorderData: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
          width: 0.8,
        ),
        titlePositionPercentageOffset: 0.17,
        titleTextStyle: textTheme.labelSmall?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        getTitle: (index, angle) {
          final readableAngle = angle > 90 && angle < 270 ? angle + 180 : angle;
          return RadarChartTitle(
            text: _shortRadarLabel(_string(points[index]['label'])),
            angle: readableAngle,
          );
        },
        dataSets: _buildRadarDataSets(
          points: points,
          averageColor: averageColor,
        ),
      ),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  List<RadarDataSet> _buildRadarDataSets({
    required List<Map<String, Object?>> points,
    required Color averageColor,
  }) {
    final averageVisible = _visibilityController.isVisible(_averageSeriesId);
    final latestVisible = _visibilityController.isVisible(_latestSeriesId);

    return [
      RadarDataSet(
        dataEntries: points
            .map((point) => RadarEntry(value: _num(point['planned'])))
            .toList(growable: false),
        borderColor: averageVisible
            ? averageColor
            : averageColor.withValues(alpha: 0),
        fillColor: averageVisible
            ? averageColor.withValues(alpha: 0.04)
            : averageColor.withValues(alpha: 0),
        borderWidth: 2.2,
        entryRadius: averageVisible ? 2.8 : 0,
      ),
      RadarDataSet(
        dataEntries: points
            .map((point) => RadarEntry(value: _num(point['actual'])))
            .toList(growable: false),
        borderColor: latestVisible
            ? widget.accent
            : widget.accent.withValues(alpha: 0),
        fillColor: latestVisible
            ? widget.accent.withValues(alpha: 0.17)
            : widget.accent.withValues(alpha: 0),
        borderWidth: 2.2,
        entryRadius: latestVisible ? 3 : 0,
      ),
    ];
  }
}

class _BalanceFingerprintVisual extends StatefulWidget {
  const _BalanceFingerprintVisual({required this.data, required this.accent});

  final Map<String, Object?> data;
  final Color accent;

  @override
  State<_BalanceFingerprintVisual> createState() =>
      _BalanceFingerprintVisualState();
}

class _BalanceFingerprintVisualState extends State<_BalanceFingerprintVisual> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final segments = _listOfMaps(
      widget.data['segments'],
    ).where((segment) => _num(segment['percent']) > 0).toList(growable: false);
    if (segments.length < 3) {
      return const SizedBox.shrink();
    }
    if (_selectedIndex != null && _selectedIndex! >= segments.length) {
      _selectedIndex = 0;
    }

    final textTheme = context.appText;
    final colors = context.appColors;
    final score = _num(widget.data['balanceScore']).round().clamp(0, 100);
    final selected = _selectedIndex == null ? null : segments[_selectedIndex!];
    final selectedColor = selected == null
        ? colors.textTertiary
        : _balanceSegmentColor(context, _string(selected['axisId']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BalanceScoreLine(score: score),
        const SizedBox(height: 12),
        Expanded(
          child: _BalanceFingerprintBar(
            segments: segments,
            selectedIndex: _selectedIndex,
            onSegmentSelected: (index) {
              setState(() {
                _selectedIndex = _selectedIndex == index ? null : index;
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Row(
            key: ValueKey(
              selected == null ? 'none' : _string(selected['axisId']),
            ),
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _selectedSegmentText(selected),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _selectedSegmentText(Map<String, Object?>? segment) {
    if (segment == null) {
      return 'Tap a segment to inspect its long-term share';
    }
    final label = _string(segment['label']);
    final percent = (_num(segment['percent']) * 100).round();
    return '$label accounts for $percent% of long-term work';
  }
}

class _BalanceScoreLine extends StatelessWidget {
  const _BalanceScoreLine({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final value = score.clamp(0, 100);
    final activeZone = _balanceZoneFor(value);

    return SizedBox(
      key: const Key('insight_feed_balance_score_line'),
      height: 44,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const markerWidth = 3.0;
          const markerHeight = 22.0;
          const plotLeft = 0.0;
          const zoneHeight = 12.0;
          const zoneTop = 8.0;
          final plotRight = math.max(plotLeft + 1, constraints.maxWidth);
          final plotWidth = plotRight - plotLeft;
          final markerX = plotLeft + plotWidth * (value / 100);
          final markerColor = colors.textPrimary;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              _BalanceScoreZones(
                plotLeft: plotLeft,
                plotWidth: plotWidth,
                zoneTop: zoneTop,
                zoneHeight: zoneHeight,
                activeZone: activeZone,
              ),
              _BalanceScoreMarker(
                markerColor: markerColor,
                markerHeight: markerHeight,
                markerWidth: markerWidth,
                markerX: markerX,
                zoneHeight: zoneHeight,
                zoneTop: zoneTop,
                maxWidth: constraints.maxWidth,
              ),
              const _BalanceScoreEndpoints(),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceScoreZones extends StatelessWidget {
  const _BalanceScoreZones({
    required this.plotLeft,
    required this.plotWidth,
    required this.zoneTop,
    required this.zoneHeight,
    required this.activeZone,
  });

  final double plotLeft;
  final double plotWidth;
  final double zoneTop;
  final double zoneHeight;
  final _BalanceZone activeZone;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Stack(
      children: [
        for (final zone in _BalanceZone.values)
          Positioned(
            left: plotLeft + plotWidth * (zone.start / 100),
            top: zoneTop,
            width: plotWidth * ((zone.end - zone.start) / 100),
            child: Container(
              key: Key('insight_feed_balance_zone_${zone.name}'),
              height: zoneHeight,
              margin: EdgeInsets.only(
                left: zone == _BalanceZone.low ? 0 : 1.5,
                right: zone == _BalanceZone.high ? 0 : 1.5,
              ),
              decoration: BoxDecoration(
                color: zone == activeZone
                    ? _balanceZoneColor(context, zone).withValues(alpha: 0.92)
                    : colors.field.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

class _BalanceScoreMarker extends StatelessWidget {
  const _BalanceScoreMarker({
    required this.markerColor,
    required this.markerHeight,
    required this.markerWidth,
    required this.markerX,
    required this.zoneHeight,
    required this.zoneTop,
    required this.maxWidth,
  });

  final Color markerColor;
  final double markerHeight;
  final double markerWidth;
  final double markerX;
  final double zoneHeight;
  final double zoneTop;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: (markerX - markerWidth / 2)
          .clamp(0.0, math.max(0.0, maxWidth - markerWidth))
          .toDouble(),
      top: zoneTop + (zoneHeight / 2) - (markerHeight / 2),
      child: Container(
        key: const Key('insight_feed_balance_score_marker'),
        width: markerWidth,
        height: markerHeight,
        decoration: BoxDecoration(
          color: markerColor,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _BalanceScoreEndpoints extends StatelessWidget {
  const _BalanceScoreEndpoints();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;
    return Stack(
      children: [
        Positioned(
          left: 0,
          bottom: 0,
          child: Text(
            '0',
            style: textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Text(
            '100',
            style: textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

enum _BalanceZone {
  low(0, 40),
  medium(40, 70),
  high(70, 100);

  const _BalanceZone(this.start, this.end);

  final double start;
  final double end;
}

_BalanceZone _balanceZoneFor(int score) {
  if (score >= 70) {
    return _BalanceZone.high;
  }
  if (score >= 40) {
    return _BalanceZone.medium;
  }
  return _BalanceZone.low;
}

Color _balanceZoneColor(BuildContext context, _BalanceZone zone) {
  return switch (zone) {
    _BalanceZone.low => context.appColors.balanceZoneLow,
    _BalanceZone.medium => context.appColors.balanceZoneMedium,
    _BalanceZone.high => context.appColors.balanceZoneHigh,
  };
}

class _BalanceFingerprintBar extends StatelessWidget {
  const _BalanceFingerprintBar({
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentSelected,
  });

  final List<Map<String, Object?>> segments;
  final int? selectedIndex;
  final ValueChanged<int> onSegmentSelected;
  static const BorderRadius _barBorderRadius = BorderRadius.all(
    Radius.circular(14),
  );

  @override
  Widget build(BuildContext context) {
    final widths = _displayPercentages(
      segments.map((segment) => _num(segment['percent'])).toList(),
    );
    final textStyle = context.appText.labelSmall?.copyWith(
      color: context.appScheme.onPrimary,
      fontWeight: FontWeight.w800,
      shadows: [
        Shadow(
          color: context.appColors.shadow.withValues(alpha: 0.6),
          blurRadius: 3,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(1.0, constraints.maxWidth);
        return ClipRRect(
          borderRadius: _barBorderRadius,
          child: Row(
            key: const Key('insight_feed_balance_fingerprint_bar'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < segments.length; index++)
                _BalanceFingerprintSegment(
                  segment: segments[index],
                  width: width * widths[index],
                  borderRadius: _segmentBorderRadius(index, segments.length),
                  isSelected: selectedIndex == index,
                  isDimmed: selectedIndex != null && selectedIndex != index,
                  textStyle: textStyle,
                  onTap: () => onSegmentSelected(index),
                ),
            ],
          ),
        );
      },
    );
  }

  List<double> _displayPercentages(List<double> values) {
    const minVisiblePercent = 0.035;
    final adjusted = values
        .map((value) => value > 0 ? math.max(value, minVisiblePercent) : 0.0)
        .toList(growable: false);
    final total = adjusted.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return List.filled(values.length, 1 / values.length, growable: false);
    }
    return adjusted.map((value) => value / total).toList(growable: false);
  }

  BorderRadius _segmentBorderRadius(int index, int segmentCount) {
    if (segmentCount <= 1) {
      return _barBorderRadius;
    }
    if (index == 0) {
      return const BorderRadius.horizontal(left: Radius.circular(14));
    }
    if (index == segmentCount - 1) {
      return const BorderRadius.horizontal(right: Radius.circular(14));
    }
    return BorderRadius.zero;
  }
}

class _BalanceFingerprintSegment extends StatelessWidget {
  const _BalanceFingerprintSegment({
    required this.segment,
    required this.width,
    required this.borderRadius,
    required this.isSelected,
    required this.isDimmed,
    required this.textStyle,
    required this.onTap,
  });

  final Map<String, Object?> segment;
  final double width;
  final BorderRadius borderRadius;
  final bool isSelected;
  final bool isDimmed;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final axisId = _string(segment['axisId']);
    final baseColor = _balanceSegmentColor(context, axisId);
    final displayColor = isDimmed
        ? Color.alphaBlend(
            context.appColors.field.withValues(alpha: 0.62),
            baseColor,
          ).withValues(alpha: 0.46)
        : baseColor;

    return SizedBox(
      key: Key('insight_feed_balance_segment_$axisId'),
      width: width,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: displayColor,
            borderRadius: borderRadius,
            border: Border.all(
              color: isSelected
                  ? context.appScheme.onSurface.withValues(alpha: 0.82)
                  : context.appColors.transparent,
              width: isSelected ? 2 : 0,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: _buildLabel(),
        ),
      ),
    );
  }

  Widget? _buildLabel() {
    if (isDimmed) {
      return null;
    }

    final mode = _labelModeForWidth(width);
    if (mode == _BalanceSegmentLabelMode.hidden) {
      return null;
    }

    final baseLabel = _string(segment['label']);
    final label = switch (mode) {
      _BalanceSegmentLabelMode.horizontal => _shortBalanceLabel(baseLabel),
      _BalanceSegmentLabelMode.vertical => _shortBalanceLabel(baseLabel),
      _BalanceSegmentLabelMode.verticalAbbreviated => _abbreviatedBalanceLabel(
        baseLabel,
      ),
      _BalanceSegmentLabelMode.hidden => '',
    };

    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, maxLines: 1, style: textStyle),
      ),
    );

    return Center(
      child: mode == _BalanceSegmentLabelMode.horizontal
          ? child
          : RotatedBox(quarterTurns: 3, child: child),
    );
  }
}

enum _BalanceSegmentLabelMode {
  hidden,
  verticalAbbreviated,
  vertical,
  horizontal,
}

_BalanceSegmentLabelMode _labelModeForWidth(double width) {
  if (width >= 52) {
    return _BalanceSegmentLabelMode.horizontal;
  }
  if (width >= 28) {
    return _BalanceSegmentLabelMode.vertical;
  }
  if (width >= 18) {
    return _BalanceSegmentLabelMode.verticalAbbreviated;
  }
  return _BalanceSegmentLabelMode.hidden;
}

Color _balanceSegmentColor(BuildContext context, String axisId) {
  final normalized = axisId.toLowerCase();
  return switch (normalized) {
    'chest' => context.appColors.balanceSegmentChest,
    'back' => context.appColors.balanceSegmentBack,
    'shoulders' => context.appColors.balanceSegmentShoulders,
    'arms' => context.appColors.balanceSegmentArms,
    'core' => context.appColors.balanceSegmentCore,
    'glutes' => context.appColors.balanceSegmentGlutes,
    'legs' => context.appColors.balanceSegmentLegs,
    'other' => context.appColors.textTertiary,
    _ => context.appScheme.primary,
  };
}

String _shortBalanceLabel(String label) {
  return switch (label) {
    'Shoulders' => 'Delts',
    _ => label,
  };
}

String _abbreviatedBalanceLabel(String label) {
  return switch (label) {
    'Chest' => 'Ch',
    'Back' => 'Bk',
    'Shoulders' => 'Delts',
    'Arms' => 'Arms',
    'Core' => 'Core',
    'Glutes' => 'Glut',
    'Legs' => 'Legs',
    'Other' => 'Oth',
    _ => label,
  };
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.baseline,
    required this.referenceValues,
    required this.showPrimary,
    required this.showReference,
    required this.color,
    required this.gridColor,
    required this.fillColor,
    required this.labelStyle,
    required this.smooth,
  });

  final List<double> values;
  final double? baseline;
  final List<double>? referenceValues;
  final bool showPrimary;
  final bool showReference;
  final Color color;
  final Color gridColor;
  final Color fillColor;
  final TextStyle labelStyle;
  final bool smooth;

  @override
  void paint(Canvas canvas, Size size) {
    final allValues = [...values, ...?referenceValues, ?baseline];
    if (allValues.isEmpty) {
      return;
    }
    final minValue = allValues.reduce(math.min).toDouble();
    final maxValue = allValues.reduce(math.max).toDouble();
    final span = math.max(maxValue - minValue, 1).toDouble();
    final plot = smooth
        ? Rect.fromLTWH(
            _insightLinePlotLeftPadding,
            6,
            math.max(
              1,
              size.width -
                  _insightLinePlotLeftPadding -
                  _insightLinePlotRightPadding,
            ),
            math.max(1, size.height - 14),
          )
        : Offset.zero & size;

    if (smooth) {
      final gridPaint = Paint()
        ..color = gridColor.withValues(alpha: 0.55)
        ..strokeWidth = 1.2;
      final midValue = minValue + (span / 2);
      for (final tickValue in [maxValue, midValue, minValue]) {
        final y = _yForValue(tickValue, plot, minValue, span);
        canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
        _paintAxisLabel(
          canvas,
          label: _shortBodyWeightLabel(tickValue, span),
          offset: Offset(0, y - 7),
          style: labelStyle,
        );
      }
    }

    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? plot.left
          : plot.left + plot.width * index / (values.length - 1);
      final y = _yForValue(values[index], plot, minValue, span);
      points.add(Offset(x, y));
    }

    if (showReference &&
        smooth &&
        referenceValues != null &&
        referenceValues!.length == values.length) {
      final referencePoints = <Offset>[];
      for (var index = 0; index < referenceValues!.length; index++) {
        final x = referenceValues!.length == 1
            ? plot.left
            : plot.left + plot.width * index / (referenceValues!.length - 1);
        final y = _yForValue(referenceValues![index], plot, minValue, span);
        referencePoints.add(Offset(x, y));
      }
      final paint = Paint()
        ..color = gridColor.withValues(alpha: 0.95)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      _drawDashedPolyline(canvas, referencePoints, paint);
    } else if (showReference && baseline != null) {
      final y = _yForValue(baseline!, plot, minValue, span);
      final paint = Paint()
        ..color = gridColor.withValues(alpha: smooth ? 0.95 : 0.7)
        ..strokeWidth = smooth ? 2.4 : 1.2;
      if (smooth) {
        _drawDashedLine(
          canvas,
          Offset(plot.left, y),
          Offset(plot.right, y),
          paint,
        );
      } else {
        canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), paint);
      }
    }

    if (showPrimary) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var index = 1; index < points.length; index++) {
        if (smooth) {
          final previous = points[index - 1];
          final current = points[index];
          final controlX = (previous.dx + current.dx) / 2;
          path.cubicTo(
            controlX,
            previous.dy,
            controlX,
            current.dy,
            current.dx,
            current.dy,
          );
        } else {
          path.lineTo(points[index].dx, points[index].dy);
        }
      }

      final fillPath = Path.from(path)
        ..lineTo(plot.right, plot.bottom)
        ..lineTo(plot.left, plot.bottom)
        ..close();
      canvas.drawPath(fillPath, Paint()..color = fillColor);
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = smooth ? 3.2 : 2.4,
      );
    }
  }

  double _yForValue(double value, Rect plot, double minValue, double span) {
    return plot.bottom - ((value - minValue) / span * plot.height);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashGap = 4.0;
    final delta = end - start;
    final totalLength = delta.distance;
    if (totalLength <= 0) {
      return;
    }
    final direction = delta / totalLength;
    var drawn = 0.0;
    while (drawn < totalLength) {
      final next = math.min(drawn + dashWidth, totalLength);
      canvas.drawLine(
        start + direction * drawn,
        start + direction * next,
        paint,
      );
      drawn += dashWidth + dashGap;
    }
  }

  void _drawDashedPolyline(Canvas canvas, List<Offset> points, Paint paint) {
    for (var index = 1; index < points.length; index++) {
      _drawDashedLine(canvas, points[index - 1], points[index], paint);
    }
  }

  String _shortBodyWeightLabel(double value, double span) {
    if (span >= 10) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  void _paintAxisLabel(
    Canvas canvas, {
    required String label,
    required Offset offset,
    required TextStyle style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 30);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.baseline != baseline ||
        oldDelegate.referenceValues != referenceValues ||
        oldDelegate.showPrimary != showPrimary ||
        oldDelegate.showReference != showReference ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.smooth != smooth;
  }
}

class _VelocityLinePainter extends CustomPainter {
  _VelocityLinePainter({
    required this.values,
    required this.average,
    required this.showValues,
    required this.showAverage,
    required this.color,
    required this.averageColor,
    required this.gridColor,
    required this.labelStyle,
    required this.pointFillColor,
  });

  final List<double> values;
  final double? average;
  final bool showValues;
  final bool showAverage;
  final Color color;
  final Color averageColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final Color pointFillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final allValues = [...values, ?average];
    if (allValues.isEmpty) {
      return;
    }
    const topPadding = 6.0;
    const bottomPadding = 8.0;
    final plot = Rect.fromLTWH(
      _insightLinePlotLeftPadding,
      topPadding,
      math.max(
        1,
        size.width - _insightLinePlotLeftPadding - _insightLinePlotRightPadding,
      ),
      math.max(1, size.height - topPadding - bottomPadding),
    );
    const minValue = 0.0;
    final maxValue = math.max(allValues.reduce(math.max), 1.0);
    final span = math.max(maxValue - minValue, 1.0);
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (final tickValue in [maxValue, maxValue / 2, minValue]) {
      final y = _yForValue(tickValue, plot, minValue, span);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _paintAxisLabel(
        canvas,
        label: _shortWeeklyLabel(tickValue),
        offset: Offset(0, y - 7),
        style: labelStyle,
      );
    }

    final focusStart = math.max(0, values.length - 5);
    final focusLeft = plot.left + plot.width * 0.54;
    final focusDividerPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.42)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(focusLeft, plot.top),
      Offset(focusLeft, plot.bottom),
      focusDividerPaint,
    );

    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = _xForIndex(
        index: index,
        count: values.length,
        focusStart: focusStart,
        plot: plot,
        focusLeft: focusLeft,
      );
      final y = _yForValue(values[index], plot, minValue, span);
      points.add(Offset(x, y));
    }

    if (showValues && showAverage && average != null && points.length > 1) {
      final baselineY = _yForValue(average!, plot, minValue, span);
      final fillStart = _baselineIntersectionFromRight(
        points: points,
        baselineY: baselineY,
      );
      final bandPath = Path()
        ..moveTo(fillStart.dx, baselineY)
        ..lineTo(fillStart.dx, fillStart.dy);

      for (final point in points.where((point) => point.dx > fillStart.dx)) {
        bandPath.lineTo(point.dx, point.dy);
      }
      bandPath
        ..lineTo(points.last.dx, baselineY)
        ..close();
      canvas.drawPath(bandPath, Paint()..color = color.withValues(alpha: 0.24));
    }

    if (showAverage && average != null) {
      final averageY = _yForValue(average!, plot, minValue, span);
      final averagePaint = Paint()
        ..color = averageColor.withValues(alpha: 0.95)
        ..strokeWidth = 2.4;
      _drawDashedLine(
        canvas,
        Offset(plot.left, averageY),
        Offset(plot.right, averageY),
        averagePaint,
      );
      _paintAxisLabel(
        canvas,
        label: 'base',
        offset: Offset(plot.right - 36, averageY - 18),
        style: labelStyle.copyWith(
          color: averageColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    if (showValues) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var index = 1; index < points.length; index++) {
        final previous = points[index - 1];
        final current = points[index];
        final controlX = (previous.dx + current.dx) / 2;
        path.cubicTo(
          controlX,
          previous.dy,
          controlX,
          current.dy,
          current.dx,
          current.dy,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 3.2,
      );

      final pointPaint = Paint()..color = color;
      final pointFillPaint = Paint()..color = pointFillColor;
      for (var index = 0; index < points.length; index++) {
        final point = points[index];
        final isLatest = index == points.length - 1;
        final outerRadius = isLatest ? 6.2 : 3.8;
        final innerRadius = isLatest ? 2.6 : 1.8;
        if (isLatest) {
          canvas.drawCircle(
            point,
            10,
            Paint()..color = color.withValues(alpha: 0.14),
          );
        }
        canvas.drawCircle(point, outerRadius, pointPaint);
        canvas.drawCircle(point, innerRadius, pointFillPaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashGap = 4.0;
    final totalLength = end.dx - start.dx;
    var currentX = start.dx;
    while (currentX < start.dx + totalLength) {
      final nextX = math.min(currentX + dashWidth, start.dx + totalLength);
      canvas.drawLine(Offset(currentX, start.dy), Offset(nextX, end.dy), paint);
      currentX += dashWidth + dashGap;
    }
  }

  double _yForValue(double value, Rect plot, double minValue, double span) {
    return plot.bottom - ((value - minValue) / span * plot.height);
  }

  Offset _baselineIntersectionFromRight({
    required List<Offset> points,
    required double baselineY,
  }) {
    for (var index = points.length - 1; index > 0; index--) {
      final current = points[index];
      final previous = points[index - 1];
      final currentDelta = current.dy - baselineY;
      final previousDelta = previous.dy - baselineY;

      if (currentDelta == 0) {
        return current;
      }
      if (currentDelta.sign != previousDelta.sign) {
        final denominator = previousDelta - currentDelta;
        final progress = denominator == 0 ? 0.0 : previousDelta / denominator;
        final x = previous.dx + (current.dx - previous.dx) * progress;
        return Offset(x, baselineY);
      }
    }
    return points.first;
  }

  double _xForIndex({
    required int index,
    required int count,
    required int focusStart,
    required Rect plot,
    required double focusLeft,
  }) {
    return _velocityXForIndex(
      index: index,
      count: count,
      focusStart: focusStart,
      plotLeft: plot.left,
      plotRight: plot.right,
      focusLeft: focusLeft,
    );
  }

  void _paintAxisLabel(
    Canvas canvas, {
    required String label,
    required Offset offset,
    required TextStyle style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 32);
    painter.paint(canvas, offset);
  }

  String _shortWeeklyLabel(double value) {
    final rounded = value.roundToDouble();
    final number = (value - rounded).abs() < 0.05
        ? rounded.toInt().toString()
        : value.toStringAsFixed(1);
    return '$number/wk';
  }

  @override
  bool shouldRepaint(covariant _VelocityLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.average != average ||
        oldDelegate.showValues != showValues ||
        oldDelegate.showAverage != showAverage ||
        oldDelegate.color != color ||
        oldDelegate.averageColor != averageColor ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.pointFillColor != pointFillColor;
  }
}

int _maxDynamicLabelCount(double plotWidth) {
  return math.max(2, (plotWidth / _dynamicXLabelMinGap).floor() + 1);
}

double _velocityXForIndex({
  required int index,
  required int count,
  required int focusStart,
  required double plotLeft,
  required double plotRight,
  required double focusLeft,
}) {
  if (count <= 1) {
    return plotLeft;
  }
  if (index < focusStart) {
    final historySlots = math.max(1, focusStart);
    return plotLeft + (focusLeft - plotLeft) * index / historySlots;
  }
  final focusSlots = math.max(1, count - 1 - focusStart);
  return focusLeft +
      (plotRight - focusLeft) * (index - focusStart) / focusSlots;
}

List<Map<String, Object?>> _listOfMaps(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map>()
      .map((entry) => entry.cast<String, Object?>())
      .toList(growable: false);
}

List<WorkoutAchievement> _achievementsFromVisualData(
  Map<String, Object?> data,
) {
  return _listOfMaps(data['achievements'])
      .map((map) => WorkoutAchievement.fromMap(Map<String, dynamic>.from(map)))
      .toList(growable: false);
}

List<bool> _boolList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.map((entry) => entry == true).toList(growable: false);
}

List<String> _dayLabels(Object? value, {required int fallbackCount}) {
  if (value is List) {
    return value.map((entry) => _string(entry)).toList(growable: false);
  }
  return List.filled(fallbackCount, '', growable: false);
}

double _num(Object? value) {
  return value is num ? value.toDouble() : 0;
}

double? _nullableNum(Object? value) {
  return value is num ? value.toDouble() : null;
}

String _string(Object? value) {
  return value is String ? value : '';
}

String _signedPercentLabel(String label) {
  if (label.isEmpty || label.startsWith('-') || label.startsWith('+')) {
    return label;
  }
  return label == '0%' ? label : '+$label';
}

int _estimatedLineCount(
  String text, {
  required int charactersPerLine,
  required int maxLines,
}) {
  if (text.isEmpty) {
    return 1;
  }
  final normalized = text.trim();
  final estimated = (normalized.length / charactersPerLine).ceil();
  return estimated.clamp(1, maxLines);
}

String _shortRadarLabel(String label) {
  return label == 'Shoulders' ? 'Delts' : label;
}

BoxDecoration _insightCardDecoration(BuildContext context) {
  final scheme = context.appScheme;
  return BoxDecoration(
    color: scheme.surface,
    borderRadius: AppTheme.workoutCardBorderRadius,
  );
}

class _InsightFeedFallbackCard extends StatelessWidget {
  const _InsightFeedFallbackCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(16),
      decoration: _insightCardDecoration(context),
      child: Row(
        children: [
          Icon(CupertinoIcons.chart_bar_alt_fill, color: colors.textTertiary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Keep logging workouts to unlock fresh trends and shoutouts.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// policy: allow-public-api launcher tile that opens the advanced insights route.
class AdvancedInsightsLauncher extends StatelessWidget {
  const AdvancedInsightsLauncher({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Material(
        color: colors.transparent,
        borderRadius: AppTheme.workoutCardBorderRadius,
        child: InkWell(
          key: const Key('advanced_insights_launcher'),
          borderRadius: AppTheme.workoutCardBorderRadius,
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.field,
              borderRadius: AppTheme.workoutCardBorderRadius,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Advanced Insights',
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: colors.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
