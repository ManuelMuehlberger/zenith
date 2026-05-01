import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../screens/timeline_screen.dart';
import '../../theme/app_theme.dart';

class SettingsTimelineSection extends StatelessWidget {
  const SettingsTimelineSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              CupertinoPageRoute(builder: (context) => const TimelineScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.rocket_fill,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Timeline', style: textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'View development roadmap',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: colors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
