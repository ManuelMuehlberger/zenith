import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_list_widget.dart';
import 'exercise_info_screen.dart';

class ExerciseBrowserScreen extends StatelessWidget {
  const ExerciseBrowserScreen({super.key});

  void _showExerciseInfo(BuildContext context, Exercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseInfoScreen(exercise: exercise),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double screenHeaderHeight = topPadding + kToolbarHeight;
    final theme = Theme.of(context);
    final textTheme = context.appText;
    final colorScheme = context.appScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ExerciseListWidget(
            onExerciseSelected: (exercise) =>
                _showExerciseInfo(context, exercise),
            additionalTopPadding: screenHeaderHeight,
          ),

          // Custom "Exercise Statistics" header overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeaderHeight,
            child: ColoredBox(
              color: theme.scaffoldBackgroundColor,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: colorScheme.onSurface,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Back',
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Exercise Statistics',
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 56), // Balance the IconButton
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
