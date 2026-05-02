import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../main_dock_spacer.dart';
import '../timeline/skeleton_timeline_row.dart';

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

class HomeScreenLoadingMoreSliver extends StatelessWidget {
  const HomeScreenLoadingMoreSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => SkeletonTimelineRow(index: index),
          childCount: 3,
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
