import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

class ArchiveTriggerFooter extends StatefulWidget {
  final VoidCallback onTrigger;
  final bool isVisible;

  const ArchiveTriggerFooter({
    super.key,
    required this.onTrigger,
    this.isVisible = true,
  });

  @override
  State<ArchiveTriggerFooter> createState() => ArchiveTriggerFooterState();
}

class ArchiveTriggerFooterState extends State<ArchiveTriggerFooter> {
  double _pullDistance = 0.0;
  bool _isTriggered = false;

  void updateScroll(double overscroll) {
    if (!widget.isVisible || _isTriggered) return;

    // Clamp overscroll to 0-120 range for calculation
    final distance = overscroll.clamp(0.0, 120.0);

    if ((distance - _pullDistance).abs() > 0.1) {
      setState(() {
        _pullDistance = distance;
      });
    }
  }

  void trigger() {
    if (_isTriggered) return;
    setState(() {
      _isTriggered = true;
      _pullDistance = 0;
    });
    widget.onTrigger();
  }

  void reset() {
    setState(() {
      _isTriggered = false;
      _pullDistance = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    if (!widget.isVisible) return const SizedBox.shrink();

    // Calculate spread based on pull distance (0.0 to 2.0)
    // We allow it to go past 1.0 to show "through the threshold"
    final double progress = (_pullDistance / 100.0).clamp(0.0, 2.0);

    // Base spacing is 4px, max spacing is 48px (MUCH more dramatic)
    final double dotSpacing = 4.0 + (progress * 48.0);

    // Scale dots: Grow from 1.0 to 2.5 (much more pronounced)
    final double scale = 1.0 + (progress * 1.5);

    // Opacity increases as we pull (makes it more visible)
    final double opacityBoost = 0.2 + (progress * 0.4);

    // Track color matching TimelineRow
    const double trackOpacity = 0.3;
    final trackColor = colorScheme.onSurface;

    final bool isThresholdReached = progress >= 1.0;
    final Color activeColor = isThresholdReached
        ? colorScheme.primary
        : trackColor;

    // When triggered, we want to "reduce the fadeout" (make it solid) and expand.
    // We can animate these properties.
    // Since _isTriggered is set synchronously, we might want an implicit animation here?
    // But the parent removes this widget shortly after trigger?
    // In HomeScreen: _revealArchive removes the footer.
    // So we might not see the animation if it's removed immediately.
    // However, _revealArchive uses AnimatedInsert to remove it.
    // So it will fade out/shrink.
    // If we want it to "expand down", maybe we should keep it for a moment?
    // But the user said "timeline should visibly expand down... old months should fly in".
    // If we remove the footer, the space is filled by new items.

    // Let's assume the visual change happens just before removal or during the transition.
    // If we change the gradient to be more solid, it will look like it connects to the new content.

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        trigger();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: _isTriggered ? 300 : 200, // Expand down on trigger
        padding: const EdgeInsets.only(top: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline column
            SizedBox(
              width: 46, // Matches timeline width
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // The Line
                  // Fades from 30% to 0% opacity normally.
                  // When triggered, fades from 30% to 30% (solid) to connect with incoming content?
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 4, // Matches TimelineRow strokeWidth
                    height: _isTriggered ? 300 : 150, // Grow the line
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          trackColor.withValues(alpha: trackOpacity),
                          trackColor.withValues(
                            alpha: _isTriggered ? trackOpacity : 0.0,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // The Dots
                  // Positioned at the end of the fade
                  // If triggered, maybe hide dots? Or move them down?
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    top: _isTriggered ? 300 : 150, // Move dots down
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isTriggered
                          ? 0.0
                          : 1.0, // Fade out dots on trigger
                      child: Column(
                        children: [
                          _buildDot(
                            activeColor,
                            trackOpacity,
                            scale,
                            opacityBoost,
                          ),
                          SizedBox(height: dotSpacing),
                          _buildDot(
                            activeColor,
                            trackOpacity,
                            scale,
                            opacityBoost,
                          ),
                          SizedBox(height: dotSpacing),
                          _buildDot(
                            activeColor,
                            trackOpacity,
                            scale,
                            opacityBoost,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text hint that appears as you pull
            if (!_isTriggered)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 150, left: 12),
                  child: Opacity(
                    opacity: (progress - 0.2).clamp(0.0, 1.0),
                    child: Text(
                      isThresholdReached
                          ? "Release to view history"
                          : "Pull to view history",
                      style: textTheme.labelMedium?.copyWith(
                        color: isThresholdReached
                            ? colorScheme.onSurface
                            : colors.textSecondary,
                        fontWeight: isThresholdReached
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(
    Color color,
    double opacity,
    double scale,
    double opacityBoost,
  ) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: color.withValues(
            alpha: (opacity + opacityBoost).clamp(0.0, 1.0),
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
