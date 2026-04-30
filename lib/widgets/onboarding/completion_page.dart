import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CompletionPage extends StatelessWidget {
  final String name;
  final bool isLoading;
  final VoidCallback onComplete;

  const CompletionPage({
    super.key,
    required this.name,
    required this.isLoading,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colors.success,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(Icons.check, size: 60, color: colorScheme.onPrimary),
          ),

          const SizedBox(height: 32),

          Text(
            'Welcome, $name!',
            textAlign: TextAlign.center,
            style: textTheme.displaySmall,
          ),

          const SizedBox(height: 16),

          Text(
            'You\'re all set to start your fitness journey with a privacy-respecting, fully offline workout logger.',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textTertiary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: colors.success, size: 20),
                    const SizedBox(width: 8),
                    Text('Privacy First', style: textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'All your data stays on your device. No cloud, no tracking, no ads.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: isLoading ? null : onComplete,
              child: isLoading
                  ? CupertinoActivityIndicator(color: colorScheme.onPrimary)
                  : Text(
                      'Start Logging Workouts',
                      style: textTheme.titleMedium,
                    ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
