import 'package:flutter/material.dart';

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
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
                  color: index < current ? Colors.blue : Colors.grey[700],
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
          child: ElevatedButton(
            onPressed: canContinue ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (onBack != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: onBack,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
