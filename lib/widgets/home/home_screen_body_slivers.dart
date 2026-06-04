import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../main_dock_spacer.dart';

// policy: no-test-needed composition is covered by Home screen widget tests.
class HomeScreenLoadingSliver extends StatelessWidget {
  const HomeScreenLoadingSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: CircularProgressIndicator(color: context.appScheme.primary),
        ),
      ),
    );
  }
}

class HomeScreenEmptyStateSliver extends StatelessWidget {
  const HomeScreenEmptyStateSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 64,
                color: context.appColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No workouts yet',
                style: context.appText.titleMedium?.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start by creating a workout in the Builder tab',
                style: context.appText.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreenBottomSpacerSliver extends StatelessWidget {
  const HomeScreenBottomSpacerSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainDockSpacerSliver();
  }
}
