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
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index < current
                      ? colorScheme.primary
                      : context.appColors.textTertiary,
                  borderRadius: BorderRadius.circular(4),
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

class OnboardingNavigationButtons extends StatelessWidget {
  final bool canContinue;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const OnboardingNavigationButtons({
    super.key,
    required this.canContinue,
    required this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: canContinue ? onNext : null,
            child: const Text('Continue'),
          ),
        ),
        if (onBack != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(onPressed: onBack, child: const Text('Back')),
          ),
        ],
      ],
    );
  }
}
