import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../theme/app_theme.dart';

class ExerciseImageSection extends StatefulWidget {
  final Exercise exercise;
  final double height;
  final double? width;

  const ExerciseImageSection({
    super.key,
    required this.exercise,
    this.height = 200,
    this.width,
  });

  @override
  State<ExerciseImageSection> createState() => _ExerciseImageSectionState();
}

class _ExerciseImageSectionState extends State<ExerciseImageSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImagePlaceholder(String type) {
    final colors = context.appColors;
    final scheme = context.appScheme;

    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Icon(
          type == 'image' ? Icons.image : Icons.play_circle_outline,
          size: 48,
          color: colors.textTertiary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasImage = widget.exercise.image.isNotEmpty;
    final hasAnimation = widget.exercise.animation.isNotEmpty;

    if (!hasImage && !hasAnimation) {
      return _buildImagePlaceholder('image');
    }

    final pages = <Widget>[];

    if (hasImage) {
      pages.add(
        Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage(widget.exercise.image),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    if (hasAnimation) {
      pages.add(
        Stack(
          children: [
            Container(
              height: widget.height,
              width: widget.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(widget.exercise.animation),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: Icon(
                Icons.play_circle_filled,
                size: 48,
                color: colors.textPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (pages.length == 1) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: pages[0],
      );
    }

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: pages,
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? colors.textPrimary
                        : colors.textPrimary.withValues(alpha: 0.4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
