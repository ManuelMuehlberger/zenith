import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/app_constants.dart';

class SkeletonTimelineRow extends StatelessWidget {
  final int index;
  final double trackWidth;
  final double nodeRadius;

  const SkeletonTimelineRow({
    super.key,
    required this.index,
    this.trackWidth = 46,
    this.nodeRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: trackWidth,
              child: CustomPaint(
                painter: _SkeletonTrackPainter(
                  baseColor: AppConstants.ACCENT_COLOR.withOpacity(0.3),
                  nodeRadius: nodeRadius,
                  nodeCenterY: 18,
                ),
              ),
            ),
            Expanded(
              child: Shimmer.fromColors(
                baseColor: const Color(0xFF1C1C1E),
                highlightColor: const Color(0xFF2C2C2E),
                child: Container(
                  height: 80, // Approximate height of a workout card
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonTrackPainter extends CustomPainter {
  final Color baseColor;
  final double nodeRadius;
  final double nodeCenterY;

  _SkeletonTrackPainter({
    required this.baseColor,
    required this.nodeRadius,
    required this.nodeCenterY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final linePaint = Paint()
      ..color = baseColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Straight line for skeleton
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), linePaint);

    // Draw a simple node
    final nodeCenter = Offset(centerX, nodeCenterY);
    final fill = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(nodeCenter, nodeRadius, fill);
  }

  @override
  bool shouldRepaint(covariant _SkeletonTrackPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.nodeRadius != nodeRadius ||
        oldDelegate.nodeCenterY != nodeCenterY;
  }
}
