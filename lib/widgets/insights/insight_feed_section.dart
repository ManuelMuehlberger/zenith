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

class _InsightFeedStackRailState extends State<_InsightFeedStackRail> {
  var _currentPage = 0;
  var _dragOffset = 0.0;

  @override
  void didUpdateWidget(covariant _InsightFeedStackRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.cards.length) {
      _currentPage = math.max(0, widget.cards.length - 1);
    }
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
                      ? () => setState(() {
                          _dragOffset = 0;
                        })
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
    final velocity = details.primaryVelocity ?? 0;
    final shouldAdvance =
        (_dragOffset < -width * 0.22 || velocity < -450) &&
        _currentPage < widget.cards.length - 1;
    final shouldGoBack =
        (_dragOffset > width * 0.22 || velocity > 450) && _currentPage > 0;

    setState(() {
      if (shouldAdvance) {
        _currentPage++;
      } else if (shouldGoBack) {
        _currentPage--;
      }
      _dragOffset = 0;
    });
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
    return switch (card.size) {
      InsightFeedCardSize.compact => 220,
      InsightFeedCardSize.wide => 264,
      InsightFeedCardSize.featured => 396,
    };
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
      constraints: const BoxConstraints(minHeight: 132),
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
      'weight' => Icons.monitor_weight_outlined,
      _ => CupertinoIcons.sparkles,
    };
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
                                    fontWeight: FontWeight.w800,
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
        card.visualType != InsightFeedVisualType.trainingVelocityLine;

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
          SizedBox(
            height: _visualHeight(),
            child: _InsightFeedVisualContent(card: card, accent: accent),
          ),
        ],
      ),
    );
  }

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
        InsightFeedVisualType.awardPreview => const SizedBox.shrink(),
        InsightFeedVisualType.none => const SizedBox.shrink(),
      },
    );
  }
}

class _BaselineBarsVisual extends StatelessWidget {
  const _BaselineBarsVisual({required this.data, required this.accent});

  final Map<String, Object?> data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final items = _listOfMaps(data['items']);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    if (items.first.containsKey('baseline')) {
      return Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final item in items) ...[
                  Expanded(
                    child: _ComparisonMetricBars(item: item, accent: accent),
                  ),
                  if (item != items.last) const SizedBox(width: 14),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _ChartLegendRow(
            items: [
              _ChartLegendItem(
                color: context.appColors.textTertiary,
                label: 'baseline',
              ),
              _ChartLegendItem(color: accent, label: 'latest'),
            ],
          ),
        ],
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
                  ? accent
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
  const _ComparisonMetricBars({required this.item, required this.accent});

  final Map<String, Object?> item;
  final Color accent;

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
              Expanded(
                child: FractionallySizedBox(
                  heightFactor: baselineHeight,
                  alignment: Alignment.bottomCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.textTertiary.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: FractionallySizedBox(
                  heightFactor: actualHeight,
                  alignment: Alignment.bottomCenter,
                  child: DecoratedBox(
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

class _CalendarStripVisual extends StatelessWidget {
  const _CalendarStripVisual({required this.data, required this.accent});

  final Map<String, Object?> data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final recent = _boolList(data['recentDays']);
    final baseline = _boolList(data['baselineDays']);
    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }
    final recentLabel = 'last ${recent.length} days';
    final baselineLabel = 'previous ${baseline.length}';

    return Column(
      children: [
        Expanded(
          child: _LabeledDayStrip(
            label: baselineLabel,
            days: baseline,
            color: context.appColors.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _LabeledDayStrip(
            label: recentLabel,
            days: recent,
            color: accent,
          ),
        ),
      ],
    );
  }
}

class _LabeledDayStrip extends StatelessWidget {
  const _LabeledDayStrip({
    required this.label,
    required this.days,
    required this.color,
  });

  final String label;
  final List<bool> days;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.appText.labelSmall?.copyWith(
              color: context.appColors.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DayStrip(days: days, color: color),
        ),
      ],
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.days, required this.color});

  final List<bool> days;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < days.length; index++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: days[index]
                    ? color.withValues(alpha: 0.78)
                    : context.appColors.field.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          if (index != days.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _TrainingVelocityLineVisual extends StatelessWidget {
  const _TrainingVelocityLineVisual({required this.data, required this.accent});

  final Map<String, Object?> data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final points = _listOfMaps(data['points']);
    final values = points.map((point) => _num(point['value'])).toList();
    if (values.length < 2) {
      return const SizedBox.shrink();
    }

    final average = _nullableNum(data['average']);
    final summaryItems = _listOfMaps(data['summaryItems']);
    final weeklyLegend = summaryItems.isNotEmpty
        ? _summaryLegendLabel(summaryItems.first)
        : _string(data['seriesLabel']);
    final averageLegend = summaryItems.length > 1
        ? _summaryLegendLabel(summaryItems[1])
        : _string(data['averageLabel']);

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _VelocityLinePainter(
              values: values,
              average: average,
              color: accent,
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
        const SizedBox(height: 8),
        _VelocityLegendRow(
          accent: accent,
          averageColor: context.appColors.textSecondary,
          weeklyLabel: weeklyLegend.isEmpty ? '7d' : weeklyLegend,
          averageLabel: averageLegend.isEmpty ? 'base' : averageLegend,
        ),
      ],
    );
  }

  String _summaryLegendLabel(Map<String, Object?> item) {
    final value = _string(item['displayValue']).isEmpty
        ? _num(item['value']).toStringAsFixed(1)
        : _string(item['displayValue']);
    return '${_string(item['label'])} $value';
  }
}

class _VelocityLegendRow extends StatelessWidget {
  const _VelocityLegendRow({
    required this.accent,
    required this.averageColor,
    required this.weeklyLabel,
    required this.averageLabel,
  });

  final Color accent;
  final Color averageColor;
  final String weeklyLabel;
  final String averageLabel;

  @override
  Widget build(BuildContext context) {
    final style = context.appText.labelSmall?.copyWith(
      color: context.appColors.textSecondary,
      fontWeight: FontWeight.w700,
    );
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        _VelocityLegendItem(color: accent, label: weeklyLabel, style: style),
        _VelocityLegendItem(
          color: averageColor,
          label: averageLabel,
          style: style,
        ),
      ],
    );
  }
}

class _VelocityLegendItem extends StatelessWidget {
  const _VelocityLegendItem({
    required this.color,
    required this.label,
    required this.style,
  });

  final Color color;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
      ],
    );
  }
}

class _SparklineBandVisual extends StatelessWidget {
  const _SparklineBandVisual({
    required this.data,
    required this.accent,
    this.smooth = false,
  });

  final Map<String, Object?> data;
  final Color accent;
  final bool smooth;

  @override
  Widget build(BuildContext context) {
    final points = _listOfMaps(data['points']);
    final values = points.map((point) => _num(point['value'])).toList();
    if (values.length < 2) {
      return const SizedBox.shrink();
    }
    final unit = _string(data['unit']);
    final firstLabel = _string(points.first['label']);
    final lastLabel = _string(points.last['label']);
    final baseline = _nullableNum(data['baseline']);

    return Column(
      children: [
        _ChartLegendRow(
          items: [
            _ChartLegendItem(
              color: accent,
              label: smooth ? 'logged weight' : _sparklineUnitLabel(unit),
            ),
            if (baseline != null)
              _ChartLegendItem(
                color: context.appColors.textTertiary,
                label: smooth ? 'start' : 'previous best',
              ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: CustomPaint(
            painter: _SparklinePainter(
              values: values,
              baseline: baseline,
              color: accent,
              gridColor: Theme.of(context).dividerColor,
              fillColor: accent.withValues(alpha: smooth ? 0.10 : 0.16),
              smooth: smooth,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        if (firstLabel.isNotEmpty || lastLabel.isNotEmpty) ...[
          const SizedBox(height: 4),
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
      ],
    );
  }

  String _sparklineUnitLabel(String unit) {
    return switch (unit) {
      'volume' => 'volume',
      '' => 'trend',
      _ => unit,
    };
  }
}

class _ChartLegendRow extends StatelessWidget {
  const _ChartLegendRow({required this.items});

  final List<_ChartLegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: items,
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.appText.labelSmall?.copyWith(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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

class _RadarVisual extends StatelessWidget {
  const _RadarVisual({required this.data, required this.accent});

  final Map<String, Object?> data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final points = _listOfMaps(data['points']);
    if (points.length < 3) {
      return const SizedBox.shrink();
    }
    final textTheme = context.appText;
    final colors = context.appColors;
    final averageLabel = _string(data['plannedLabel']).isEmpty
        ? 'recent average'
        : _string(data['plannedLabel']);
    final latestLabel = _string(data['actualLabel']).isEmpty
        ? 'Last workout'
        : _string(data['actualLabel']);
    final averageColor = colors.textSecondary.withValues(alpha: 0.92);
    return Column(
      children: [
        Expanded(
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 4,
              ticksTextStyle: textTheme.labelSmall?.copyWith(
                color: colors.transparent,
                fontSize: 1,
              ),
              radarBackgroundColor: colors.field.withValues(alpha: 0.18),
              radarBorderData: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
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
                final readableAngle = angle > 90 && angle < 270
                    ? angle + 180
                    : angle;
                return RadarChartTitle(
                  text: _shortRadarLabel(_string(points[index]['label'])),
                  angle: readableAngle,
                );
              },
              dataSets: [
                RadarDataSet(
                  dataEntries: points
                      .map((point) => RadarEntry(value: _num(point['planned'])))
                      .toList(growable: false),
                  borderColor: averageColor,
                  fillColor: averageColor.withValues(alpha: 0.04),
                  borderWidth: 2.2,
                  entryRadius: 2.8,
                ),
                RadarDataSet(
                  dataEntries: points
                      .map((point) => RadarEntry(value: _num(point['actual'])))
                      .toList(growable: false),
                  borderColor: accent,
                  fillColor: accent.withValues(alpha: 0.17),
                  borderWidth: 2.2,
                  entryRadius: 3,
                ),
              ],
            ),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _RadarLegendItem(
              key: const Key('insight_feed_radar_legend_latest'),
              color: accent,
              label: latestLabel,
            ),
            _RadarLegendItem(
              key: const Key('insight_feed_radar_legend_average'),
              color: averageColor,
              label: averageLabel,
            ),
          ],
        ),
      ],
    );
  }
}

class _RadarLegendItem extends StatelessWidget {
  const _RadarLegendItem({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.appText.labelSmall?.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.baseline,
    required this.color,
    required this.gridColor,
    required this.fillColor,
    required this.smooth,
  });

  final List<double> values;
  final double? baseline;
  final Color color;
  final Color gridColor;
  final Color fillColor;
  final bool smooth;

  @override
  void paint(Canvas canvas, Size size) {
    final allValues = [...values, ?baseline];
    final minValue = allValues.reduce(math.min);
    final maxValue = allValues.reduce(math.max);
    final span = math.max(maxValue - minValue, 1);
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? 0.0
          : size.width * index / (values.length - 1);
      final y = size.height - ((values[index] - minValue) / span * size.height);
      points.add(Offset(x, y));
    }

    if (baseline != null) {
      final y = size.height - ((baseline! - minValue) / span * size.height);
      final paint = Paint()
        ..color = gridColor.withValues(alpha: 0.7)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

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
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.baseline != baseline ||
        oldDelegate.color != color ||
        oldDelegate.smooth != smooth;
  }
}

class _VelocityLinePainter extends CustomPainter {
  _VelocityLinePainter({
    required this.values,
    required this.average,
    required this.color,
    required this.averageColor,
    required this.gridColor,
    required this.labelStyle,
    required this.pointFillColor,
  });

  final List<double> values;
  final double? average;
  final Color color;
  final Color averageColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final Color pointFillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final allValues = [...values, ?average];
    const leftPadding = 34.0;
    const rightPadding = 4.0;
    const topPadding = 6.0;
    const bottomPadding = 8.0;
    final plot = Rect.fromLTWH(
      leftPadding,
      topPadding,
      math.max(1, size.width - leftPadding - rightPadding),
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

    if (average != null && points.length > 1) {
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

    if (average != null) {
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
    if (count <= 1) {
      return plot.left;
    }
    if (index < focusStart) {
      final historySlots = math.max(1, focusStart);
      return plot.left + (focusLeft - plot.left) * index / historySlots;
    }
    final focusSlots = math.max(1, count - 1 - focusStart);
    return focusLeft +
        (plot.right - focusLeft) * (index - focusStart) / focusSlots;
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
        oldDelegate.color != color ||
        oldDelegate.averageColor != averageColor ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.pointFillColor != pointFillColor;
  }
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
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Material(
        color: scheme.surface,
        borderRadius: AppTheme.workoutCardBorderRadius,
        child: InkWell(
          borderRadius: AppTheme.workoutCardBorderRadius,
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: _insightCardDecoration(context),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.slider_horizontal_3,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Advanced Insights',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: colors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
