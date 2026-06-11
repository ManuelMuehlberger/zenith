import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/insight_feed.dart';
import '../../services/insights/insight_feed_service.dart';
import '../../theme/app_theme.dart';

// policy: allow-public-api top-of-screen section that renders the daily insights feed.
class InsightsFeedSection extends StatefulWidget {
  const InsightsFeedSection({super.key, this.service});

  final InsightFeedService? service;

  @override
  State<InsightsFeedSection> createState() => _InsightsFeedSectionState();
}

class _InsightsFeedSectionState extends State<InsightsFeedSection> {
  late Future<List<InsightFeedCard>> _cardsFuture;

  InsightFeedService get _service =>
      widget.service ?? InsightFeedService.instance;

  @override
  void initState() {
    super.initState();
    _cardsFuture = _service.getCards();
  }

  @override
  void didUpdateWidget(covariant InsightsFeedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.service != oldWidget.service) {
      _cardsFuture = _service.getCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return FutureBuilder<List<InsightFeedCard>>(
      future: _cardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CupertinoActivityIndicator(radius: 14)),
          );
        }

        final cards = snapshot.data ?? const <InsightFeedCard>[];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              if (cards.isEmpty)
                const _InsightFeedFallbackCard()
              else
                for (final card in cards) ...[
                  InsightFeedCardWidget(card: card),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    );
  }
}

// policy: allow-public-api shared feed card renderer for insights feed entries.
class InsightFeedCardWidget extends StatelessWidget {
  const InsightFeedCardWidget({super.key, required this.card});

  final InsightFeedCard card;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final accent = _accentColor(context, card.accent);

    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
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
                    const SizedBox(width: 10),
                    Text(
                      card.metric,
                      style: textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
      'return' => CupertinoIcons.arrow_turn_up_left,
      _ => CupertinoIcons.sparkles,
    };
  }
}

class _InsightFeedFallbackCard extends StatelessWidget {
  const _InsightFeedFallbackCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
            ),
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
