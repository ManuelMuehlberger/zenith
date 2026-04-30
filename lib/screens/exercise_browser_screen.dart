import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
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
    final textTheme = context.appText;
    final colorScheme = context.appScheme;
    final colors = context.appColors;
    const backgroundColor = AppThemeColors.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ExerciseListWidget(
            onExerciseSelected: (exercise) =>
                _showExerciseInfo(context, exercise),
            additionalTopPadding: screenHeaderHeight,
          ),

          // Custom glass "Exercise Statistics" header overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeaderHeight,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppConstants.GLASS_BLUR_SIGMA,
                  sigmaY: AppConstants.GLASS_BLUR_SIGMA,
                ),
                child: Container(
                  color: colors.overlayMedium,
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
            ),
          ),
        ],
      ),
    );
  }
}
