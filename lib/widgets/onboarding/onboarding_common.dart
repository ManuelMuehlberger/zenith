import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onBack;

  const OnboardingProgressIndicator({
    super.key,
    required this.current,
    required this.total,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;

    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: 'Back',
          icon: Icon(
            CupertinoIcons.back,
            color: colorScheme.onSurface,
            size: 24,
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (index) {
              final isComplete = index < current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isComplete ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isComplete
                      ? colorScheme.primary
                      : context.appColors.textTertiary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

// policy: allow-public-api shared onboarding layout reused by multiple onboarding step pages.
class OnboardingStepLayout extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  const OnboardingStepLayout({
    super.key,
    required this.current,
    required this.total,
    required this.onBack,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.appText;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingProgressIndicator(
            current: current,
            total: total,
            onBack: onBack,
          ),
          const SizedBox(height: 32),
          Text(title, style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: child,
            ),
          ),
          const SizedBox(height: 24),
          footer,
        ],
      ),
    );
  }
}

class OnboardingNavigationButtons extends StatelessWidget {
  final bool canContinue;
  final VoidCallback onNext;
  final String label;

  const OnboardingNavigationButtons({
    super.key,
    required this.canContinue,
    required this.onNext,
    this.label = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: canContinue ? onNext : null,
        child: Text(
          label,
          style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary),
        ),
      ),
    );
  }
}
