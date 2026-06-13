import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../app_bottom_sheet.dart';
import 'achievement_model_view.dart';
import 'award_stack.dart';

// policy: allow-public-api compact award list widget.
class AwardBalloons extends StatelessWidget {
  final List<Award> awards;

  const AwardBalloons({super.key, required this.awards});

  @override
  Widget build(BuildContext context) {
    if (awards.isEmpty) return const SizedBox.shrink();

    final visible = awards.take(3).toList(growable: false);
    final thumbnailSize = awards.length == 1 ? 32.0 : 28.0;
    final horizontalOffset = awards.length == 1 ? 0.0 : 18.0;
    final width = thumbnailSize + (visible.length - 1) * horizontalOffset;

    return Tooltip(
      message: awards.length == 1
          ? awards.first.title
          : '${awards.length} awards',
      child: Semantics(
        button: true,
        label: awards.length == 1
            ? 'View ${awards.first.title} award'
            : 'View ${awards.length} awards',
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => showAwardDetailSheet(context, awards),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: SizedBox(
              width: width,
              height: thumbnailSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < visible.length; i++)
                    Positioned(
                      left: i * horizontalOffset,
                      child: _AwardThumbnail(
                        award: visible[i],
                        size: thumbnailSize,
                      ),
                    ),
                  if (awards.length > visible.length)
                    Positioned(
                      right: -7,
                      bottom: -5,
                      child: _AwardCountBadge(
                        count: awards.length - visible.length,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showAwardDetailSheet(BuildContext context, List<Award> awards) {
  return showAppBottomSheet<void>(
    context: context,
    builder: (context) => AwardDetailSheet(awards: awards),
  );
}

class _AwardThumbnail extends StatelessWidget {
  final Award award;
  final double size;

  const _AwardThumbnail({required this.award, required this.size});

  @override
  Widget build(BuildContext context) {
    final thumbnailAsset = award.compactThumbnailAsset ?? award.thumbnailAsset;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: thumbnailAsset == null
            ? _AwardFallbackIcon(award: award, size: size)
            : Image.asset(
                thumbnailAsset,
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _AwardFallbackIcon(award: award, size: size);
                },
              ),
      ),
    );
  }
}

class _AwardFallbackIcon extends StatelessWidget {
  final Award award;
  final double size;

  const _AwardFallbackIcon({required this.award, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = award.color ?? context.appScheme.primary;

    return Icon(award.icon, color: color, size: size * 0.56);
  }
}

class _AwardCountBadge extends StatelessWidget {
  final int count;

  const _AwardCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.surface, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '+$count',
              style: context.appText.labelSmall?.copyWith(
                color: scheme.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AwardDetailSheet extends StatefulWidget {
  final List<Award> awards;

  const AwardDetailSheet({super.key, required this.awards});

  @override
  State<AwardDetailSheet> createState() => _AwardDetailSheetState();
}

class _AwardDetailSheetState extends State<AwardDetailSheet> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;
    final selected = widget.awards[_currentIndex];

    return AppBottomSheet(
      maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBottomSheetHandle(),
            const SizedBox(height: 22),
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.awards.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final award = widget.awards[index];
                  return AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: index == _currentIndex ? 1 : 0.86,
                    child: Center(
                      child: AchievementModelView(
                        award: award,
                        size: 220,
                        interactive: true,
                        startRotating: false,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.awards.length > 1) ...[
              const SizedBox(height: 12),
              _AwardPageIndicator(
                count: widget.awards.length,
                currentIndex: _currentIndex,
              ),
            ],
            const SizedBox(height: 18),
            Text(
              selected.title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if ((selected.reason ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                selected.reason!.trim(),
                key: const Key('award_reason_text'),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (selected.metrics.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _visibleMetricChips(selected.metrics)
                    .map((metric) => _AwardMetricChip(metric: metric))
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

List<_AwardMetric> _visibleMetricChips(Map<String, Object?> metrics) {
  const labels = <String, String>{
    'totalSets': 'Sets',
    'completedSets': 'Done',
    'durationMinutes': 'Min',
    'totalWeight': 'Volume',
    'comparisonWorkoutCount': 'Compared',
    'totalSetsPercentileLast90Days': 'Percentile',
  };

  final result = <_AwardMetric>[];
  for (final entry in labels.entries) {
    final value = metrics[entry.key];
    if (value == null) {
      continue;
    }
    result.add(_AwardMetric(entry.value, _formatMetricValue(value)));
  }
  return result.take(4).toList(growable: false);
}

String _formatMetricValue(Object value) {
  if (value is double) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
  return value.toString();
}

class _AwardMetric {
  const _AwardMetric(this.label, this.value);

  final String label;
  final String value;
}

class _AwardMetricChip extends StatelessWidget {
  const _AwardMetricChip({required this.metric});

  final _AwardMetric metric;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.field,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '${metric.label}: ${metric.value}',
          style: context.appText.labelSmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AwardPageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _AwardPageIndicator({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;
    final colors = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == currentIndex ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == currentIndex
                  ? scheme.primary
                  : colors.textTertiary.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
