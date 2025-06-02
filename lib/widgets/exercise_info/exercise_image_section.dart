import 'package:flutter/material.dart';
import '../../models/exercise.dart';

class ExerciseImageSection extends StatefulWidget {
  final Exercise exercise;

  const ExerciseImageSection({
    super.key,
    required this.exercise,
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
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'image' ? Icons.image : Icons.play_circle_outline,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            type == 'image' ? 'Animation Coming Soon' : 'No Animation Available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.exercise.image.isNotEmpty;
    final hasAnimation = widget.exercise.animation.isNotEmpty;

    if (!hasImage && !hasAnimation) {
      return _buildImagePlaceholder('image');
    }

    final pages = <Widget>[];

    if (hasImage) {
      pages.add(
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage(widget.exercise.image),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else {
      pages.add(_buildImagePlaceholder('image'));
    }

    if (hasAnimation) {
      pages.add(
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage(widget.exercise.animation),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.play_circle_filled,
              size: 64,
              color: Colors.white70,
            ),
          ),
        ),
      );
    } else {
      pages.add(_buildImagePlaceholder('animation'));
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: pages,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _currentPage == 0 ? Colors.blue : Colors.grey[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Image',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _currentPage == 0 ? Colors.white : Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _currentPage == 1 ? Colors.blue : Colors.grey[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Animation',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _currentPage == 1 ? Colors.white : Colors.grey[400],
                    ),
              ),
            ),
          ],
        ),
        if (pages.length > 1) ...[
          const SizedBox(height: 8),
          Text(
            'Swipe left/right to switch between image and animation',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
