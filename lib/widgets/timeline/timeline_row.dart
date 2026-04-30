import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum TimelineLineStyle { straight, curved }

/// A generic timeline row that renders a left "track" (line + node)
/// and a content [child] (typically a card).
class TimelineRow extends StatelessWidget {
  final Widget child;
  final DateTime timestamp;
  final int index;
  final double trackWidth;
  final EdgeInsetsGeometry padding;

  /// The style of the timeline line (straight or curved).
  final TimelineLineStyle style;

  /// If true, the track is rendered in a dimmer color.
  final bool isNested;

  /// The widget to render as the node on the track.
  /// If null, a default node is rendered based on style.
  final Widget? node;

  /// The color of the node border.
  final Color? nodeColor;

  /// The radius of the node (used for gap calculation and positioning).
  final double nodeRadius;

  /// If true, the line is not drawn (useful for the very last item).
  final bool isLast;

  /// If true, the line fades out at the bottom.
  final bool fadeLine;

  /// If true, the bottom segment of the line supports the "Phantom Thread" animation.
  final bool isExpandable;

  /// The state of the expansion (used for animation).
  final bool isExpanded;

  /// If true, the line is rendered as a dotted line.
  final bool isDotted;

  /// Delay in milliseconds before starting the line color animation.
  final int animationDelay;

  /// If true, animates the line color from dim to white.
  final bool animateLineColor;

  const TimelineRow({
    super.key,
    required this.child,
    required this.timestamp,
    required this.index,
    this.trackWidth = 46,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
    this.style = TimelineLineStyle.straight,
    this.isNested = false,
    this.node,
    this.nodeColor,
    this.nodeRadius = 14.0,
    this.isLast = false,
    this.fadeLine = false,
    this.isExpandable = false,
    this.isExpanded = false,
    this.isDotted = false,
    this.animationDelay = 0,
    this.animateLineColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final dimTrackColor = colorScheme.onSurface.withValues(alpha: 0.3);
    final highlightTrackColor = colorScheme.onSurface;

    // Node aligns with the top edge of the card content.
    // We add some top padding so the node doesn't sit flush with the row top.
    const double nodeTopOffset = 19.5;

    return Padding(
      padding: padding,
      child: Stack(
        children: [
          // The Track (Line + Node)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: trackWidth,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // The Line
                Positioned.fill(
                  child: animateLineColor
                      ? _DelayedLineAnimator(
                          delay: animationDelay,
                          beginColor: dimTrackColor,
                          endColor: highlightTrackColor,
                          builder: (context, color) {
                            return CustomPaint(
                              painter: _TimelineTrackPainter(
                                style: style,
                                isNested: isNested,
                                isLast: isLast,
                                fadeLine: fadeLine,
                                gapStart: nodeTopOffset - nodeRadius,
                                gapEnd: nodeTopOffset + nodeRadius,
                                expansionProgress: 1.0,
                                isExpandable: false,
                                isDotted: isDotted,
                                dimTrackColor: dimTrackColor,
                                highlightTrackColor: highlightTrackColor,
                                lineColor: color,
                              ),
                            );
                          },
                        )
                      : isExpandable
                      ? TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: isExpanded ? 1.0 : 0.0,
                            end: isExpanded ? 1.0 : 0.0,
                          ),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return CustomPaint(
                              painter: _TimelineTrackPainter(
                                style: style,
                                isNested: isNested,
                                isLast: isLast,
                                fadeLine: fadeLine,
                                gapStart: nodeTopOffset - nodeRadius,
                                gapEnd: nodeTopOffset + nodeRadius,
                                expansionProgress: value,
                                isExpandable: true,
                                isDotted: isDotted,
                                dimTrackColor: dimTrackColor,
                                highlightTrackColor: highlightTrackColor,
                              ),
                            );
                          },
                        )
                      : CustomPaint(
                          painter: _TimelineTrackPainter(
                            style: style,
                            isNested: isNested,
                            isLast: isLast,
                            fadeLine: fadeLine,
                            gapStart: nodeTopOffset - nodeRadius,
                            gapEnd: nodeTopOffset + nodeRadius,
                            expansionProgress: 1.0,
                            isExpandable: false,
                            isDotted: isDotted,
                            dimTrackColor: dimTrackColor,
                            highlightTrackColor: highlightTrackColor,
                          ),
                        ),
                ),
                // The Node
                // We position the center of the node at nodeTopOffset.
                Positioned(
                  top: nodeTopOffset - nodeRadius,
                  child: node ?? _buildDefaultNode(context),
                ),
              ],
            ),
          ),
          // The Content
          Padding(
            padding: EdgeInsets.only(left: trackWidth),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultNode(BuildContext context) {
    final colorScheme = context.appScheme;
    final colors = context.appColors;

    // Fallback if no node widget is provided
    // We'll use a simple dot that matches the new design language
    return Container(
      width: 28, // Radius 14px * 2
      height: 28,
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        shape: BoxShape.circle,
        border: Border.all(color: nodeColor ?? colorScheme.primary, width: 3),
      ),
      child: Center(
        child: Container(
          width: 2,
          height: 2,
          decoration: BoxDecoration(
            color: colorScheme.onSurface,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _DelayedLineAnimator extends StatefulWidget {
  final int delay;
  final Color beginColor;
  final Color endColor;
  final Widget Function(BuildContext, Color) builder;

  const _DelayedLineAnimator({
    required this.delay,
    required this.beginColor,
    required this.endColor,
    required this.builder,
  });

  @override
  State<_DelayedLineAnimator> createState() => _DelayedLineAnimatorState();
}

class _DelayedLineAnimatorState extends State<_DelayedLineAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _colorAnimation = ColorTween(
      begin: widget.beginColor,
      end: widget.endColor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return widget.builder(context, _colorAnimation.value!);
      },
    );
  }
}

class _TimelineTrackPainter extends CustomPainter {
  final TimelineLineStyle style;
  final bool isNested;
  final bool isLast;
  final bool fadeLine;
  final double gapStart;
  final double gapEnd;
  final double expansionProgress;
  final bool isExpandable;
  final bool isDotted;
  final Color dimTrackColor;
  final Color highlightTrackColor;
  final Color? lineColor;

  _TimelineTrackPainter({
    required this.style,
    required this.isNested,
    required this.isLast,
    required this.fadeLine,
    required this.gapStart,
    required this.gapEnd,
    required this.expansionProgress,
    required this.isExpandable,
    required this.dimTrackColor,
    required this.highlightTrackColor,
    this.isDotted = false,
    this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Styling based on requirements
    // Track Color: Flat White (or very light grey) with opacity: 0.3
    // Track Weight: 4px
    final Color effectiveColor = lineColor ?? dimTrackColor;

    final paint = Paint()
      ..color = effectiveColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (fadeLine) {
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [effectiveColor, effectiveColor.withValues(alpha: 0)],
        stops: const [0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    // 1. Draw The Line

    if (style == TimelineLineStyle.straight) {
      // If gapStart >= gapEnd, it means nodeRadius is 0 (or negative), so we should draw a continuous line.
      // This fixes the "highlighted dot" issue where two rounded caps overlap.
      if (gapStart >= gapEnd) {
        if (isDotted) {
          final dottedPaint = Paint()
            ..color = effectiveColor
            ..style = PaintingStyle.fill;

          double y = 0;
          final endY = isLast
              ? size.height
              : size.height; // Draw full height for dotted if not last
          while (y < endY) {
            canvas.drawCircle(Offset(centerX, y), 2.0, dottedPaint);
            y += 6.0;
          }
        } else {
          if (!isLast) {
            canvas.drawLine(
              Offset(centerX, 0),
              Offset(centerX, size.height),
              paint,
            );
          } else {
            canvas.drawLine(
              Offset(centerX, 0),
              Offset(centerX, size.height),
              paint,
            ); // Draw full height for solid if last
          }
        }
        return;
      }

      // Draw top segment
      if (isExpandable || isDotted) {
        // Case A: Minimized (Closed) - Dotted Line
        // Fade out dots as we expand (if expandable)
        // If just dotted, opacity is constant (based on effectiveColor)

        final double dotsOpacity;
        if (isExpandable) {
          dotsOpacity = (1.0 - expansionProgress).clamp(0.0, 1.0) * 0.3;
        } else {
          dotsOpacity = 0.3; // Use default opacity for static dotted lines
        }

        if (dotsOpacity > 0.01) {
          final dottedPaint = Paint()
            ..color = isExpandable
                ? highlightTrackColor.withValues(alpha: dotsOpacity)
                : effectiveColor
            ..style = PaintingStyle.fill;

          double y = 0;
          while (y < gapStart) {
            canvas.drawCircle(
              Offset(centerX, y),
              2.0,
              dottedPaint,
            ); // Radius 2.0 = Diameter 4.0
            y += 6.0; // Vertical spacing 6px
          }
        }

        // Case B: Maximized (Open) - Gradient Line Overlay
        // Animation: Fade In Gradient (Dim -> White)
        if (expansionProgress > 0) {
          // Interpolate colors from Transparent to Target
          final topColor = Color.lerp(
            dimTrackColor.withValues(alpha: 0),
            dimTrackColor,
            expansionProgress,
          )!;
          final bottomColor = Color.lerp(
            highlightTrackColor.withValues(alpha: 0),
            highlightTrackColor,
            expansionProgress,
          )!;

          final gradientPaint = Paint()
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, bottomColor],
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

          canvas.drawLine(
            Offset(centerX, 0),
            Offset(centerX, gapStart),
            gradientPaint,
          );
        }
      } else {
        canvas.drawLine(Offset(centerX, 0), Offset(centerX, gapStart), paint);
      }

      // Draw bottom segment
      if ((isExpandable || isDotted) && !isLast) {
        // Case A: Minimized (Closed) - Dotted Line
        // Fade out dots as we expand

        final double dotsOpacity;
        if (isExpandable) {
          dotsOpacity = (1.0 - expansionProgress).clamp(0.0, 1.0) * 0.3;
        } else {
          dotsOpacity = 0.3;
        }

        if (dotsOpacity > 0.01) {
          final dottedPaint = Paint()
            ..color = isExpandable
                ? highlightTrackColor.withValues(alpha: dotsOpacity)
                : effectiveColor
            ..style = PaintingStyle.fill;

          double y = gapEnd + 3; // Start slightly below
          while (y < size.height) {
            canvas.drawCircle(
              Offset(centerX, y),
              2.0,
              dottedPaint,
            ); // Radius 2.0 = Diameter 4.0
            y += 6.0; // Vertical spacing 6px
          }
        }

        // Case B: Maximized (Open) - Gradient Line Overlay
        // Animation: Fade In Gradient (Dim -> White)
        if (expansionProgress > 0) {
          // Interpolate colors from Transparent to Target
          final topColor = Color.lerp(
            dimTrackColor.withValues(alpha: 0),
            dimTrackColor,
            expansionProgress,
          )!;
          final bottomColor = Color.lerp(
            highlightTrackColor.withValues(alpha: 0),
            highlightTrackColor,
            expansionProgress,
          )!;

          final gradientPaint = Paint()
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, bottomColor],
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

          canvas.drawLine(
            Offset(centerX, gapEnd),
            Offset(centerX, size.height),
            gradientPaint,
          );
        }
      } else if (!isLast) {
        // Standard solid bottom segment
        canvas.drawLine(
          Offset(centerX, gapEnd),
          Offset(centerX, size.height),
          paint,
        );
      }
    } else {
      // The Swirl - Denoting "Time Compressed"
      final path = Path();
      path.moveTo(centerX, 0);
      path.cubicTo(
        centerX - 8,
        size.height * 0.33, // Control Point 1
        centerX + 8,
        size.height * 0.66, // Control Point 2
        centerX,
        size.height, // End Point
      );

      if (!isLast) {
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineTrackPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.isNested != isNested ||
        oldDelegate.isLast != isLast ||
        oldDelegate.fadeLine != fadeLine ||
        oldDelegate.gapStart != gapStart ||
        oldDelegate.gapEnd != gapEnd ||
        oldDelegate.expansionProgress != expansionProgress ||
        oldDelegate.isExpandable != isExpandable ||
        oldDelegate.isDotted != isDotted ||
        oldDelegate.dimTrackColor != dimTrackColor ||
        oldDelegate.highlightTrackColor != highlightTrackColor ||
        oldDelegate.lineColor != lineColor;
  }
}
