import 'package:flutter/material.dart';
import 'award_stack.dart';

class AwardBalloons extends StatefulWidget {
  final List<Award> awards;

  const AwardBalloons({super.key, required this.awards});

  @override
  State<AwardBalloons> createState() => _AwardBalloonsState();
}

class _AwardBalloonsState extends State<AwardBalloons> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.awards.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topRight,
        child: _isExpanded ? _buildExpanded() : _buildCollapsed(),
      ),
    );
  }

  Widget _buildCollapsed() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.awards.map((a) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: _AwardIcon(award: a, size: 20),
      )).toList(),
    );
  }

  Widget _buildExpanded() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: widget.awards.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              a.title,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            _AwardIcon(award: a, size: 28),
          ],
        ),
      )).toList(),
    );
  }
}

class _AwardIcon extends StatelessWidget {
  final Award award;
  final double size;

  const _AwardIcon({required this.award, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2C2C2E),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Center(
        child: Icon(award.icon, color: award.color, size: size * 0.6),
      ),
    );
  }
}
