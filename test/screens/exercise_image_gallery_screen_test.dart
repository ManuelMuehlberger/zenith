import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/screens/exercise_image_gallery_screen.dart';
import 'package:zenith/theme/app_theme.dart';

void main() {
  testWidgets('gallery empty state keeps readable light text in light mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ExerciseImageGalleryScreen(
          imagePaths: [],
          editable: false,
          title: 'Gallery',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final titleText = tester.widget<Text>(find.text('Gallery'));
    final emptyText = tester.widget<Text>(find.text('No pictures available'));

    expect(titleText.style?.color, Colors.white);
    expect(emptyText.style?.color, Colors.white);
  });
}
