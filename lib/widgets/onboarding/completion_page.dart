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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: colors.success,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(Icons.check, size: 52, color: colorScheme.onPrimary),
          ),
          const SizedBox(height: 32),
          Text(
            'You\'re ready, ${name.isEmpty ? 'there' : name}!',
            textAlign: TextAlign.center,
            style: textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Your profile is ready. You can adjust these details anytime from settings.',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
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
                  'Everything you entered stays local to this device unless you choose to export it.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
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
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isLoading ? null : onComplete,
              child: isLoading
                  ? CupertinoActivityIndicator(color: colorScheme.onPrimary)
                  : Text(
                      'Start Logging Workouts',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
