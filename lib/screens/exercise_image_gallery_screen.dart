import 'package:file_picker/file_picker.dart';

// policy: no-test-needed media gallery screen tested at higher level

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/exercise_media.dart';

// policy: allow-public-api fullscreen image viewer shared by the exercise editor and info screen.
class ExerciseImageGalleryScreen extends StatefulWidget {
  const ExerciseImageGalleryScreen({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
    this.editable = false,
    this.title,
  });

  final List<String> imagePaths;
  final int initialIndex;
  final bool editable;
  final String? title;

  @override
  State<ExerciseImageGalleryScreen> createState() =>
      _ExerciseImageGalleryScreenState();
}

class _ExerciseImageGalleryScreenState
    extends State<ExerciseImageGalleryScreen> {
  late final PageController _pageController;
  late List<String> _imagePaths;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _imagePaths = List<String>.from(widget.imagePaths);
    _currentIndex = _imagePaths.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _imagePaths.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.of(context).pop(widget.editable ? _imagePaths : null);
  }

  Future<void> _addImages() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return;

    final nextPaths = [..._imagePaths];
    for (final file in result.files) {
      final path = file.path;
      if (path != null && !nextPaths.contains(path)) {
        nextPaths.add(path);
      }
    }

    if (nextPaths.length == _imagePaths.length) return;

    setState(() {
      _imagePaths = nextPaths;
      _currentIndex = _imagePaths.length - 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  void _removeCurrentImage() {
    if (_imagePaths.isEmpty) return;
    final next = [..._imagePaths]..removeAt(_currentIndex);
    setState(() {
      _imagePaths = next;
      if (_imagePaths.isEmpty) {
        _currentIndex = 0;
      } else if (_currentIndex >= _imagePaths.length) {
        _currentIndex = _imagePaths.length - 1;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && _imagePaths.isNotEmpty) {
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  Widget _buildEmptyState() {
    final scheme = context.appScheme;
    final primaryText = scheme.onPrimary;
    final secondaryText = primaryText.withValues(alpha: 0.8);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: secondaryText,
            ),
            const SizedBox(height: 12),
            Text(
              widget.editable ? 'No pictures yet' : 'No pictures available',
              style: context.appText.titleMedium?.copyWith(color: primaryText),
            ),
            if (widget.editable) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _addImages,
                icon: const Icon(Icons.add),
                label: const Text('Add pictures'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appScheme;
    final colors = context.appColors;
    final primaryText = scheme.onPrimary;
    final secondaryText = primaryText.withValues(alpha: 0.8);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: scheme.shadow,
        appBar: AppBar(
          backgroundColor: scheme.shadow.withValues(alpha: 0.68),
          surfaceTintColor: colors.transparent,
          foregroundColor: primaryText,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back),
            onPressed: _handleBack,
          ),
          title: Text(
            widget.title ?? 'Gallery',
            style: context.appText.titleLarge?.copyWith(
              color: primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            if (widget.editable)
              IconButton(
                tooltip: 'Add pictures',
                onPressed: _addImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
              ),
            if (widget.editable && _imagePaths.isNotEmpty)
              IconButton(
                tooltip: 'Remove picture',
                onPressed: _removeCurrentImage,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: _imagePaths.isEmpty
            ? _buildEmptyState()
            : Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _imagePaths.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final path = _imagePaths[index];
                      return InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Center(
                          child: Image(
                            image: exerciseImageProviderFor(path),
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.broken_image_outlined,
                              color: secondaryText,
                              size: 40,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.shadow.withValues(alpha: 0.44),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${_imagePaths.length}',
                            style: context.appText.labelMedium?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.w700,
                            ),
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
}
