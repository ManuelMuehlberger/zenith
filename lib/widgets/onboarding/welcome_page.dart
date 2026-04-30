import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onRestoreBackup;
  final VoidCallback onNewUser;

  const WelcomePage({
    super.key,
    required this.onRestoreBackup,
    required this.onNewUser,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                CupertinoIcons.flame_fill,
                size: 60,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Welcome to\nWorkout Logger',
              textAlign: TextAlign.center,
              style: textTheme.displaySmall,
            ),
            const SizedBox(height: 16),

            Text(
              'Your privacy-respecting, fully offline\nfitness companion',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textTertiary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 40),

            // Options
            _buildOptionCard(
              context: context,
              icon: CupertinoIcons.cloud_download_fill,
              title: 'Restore from Backup',
              subtitle: 'I have a backup file to restore',
              onTap: onRestoreBackup,
            ),

            const SizedBox(height: 16),

            _buildOptionCard(
              context: context,
              icon: CupertinoIcons.person_add_solid,
              title: 'I\'m New Here',
              subtitle: 'Set up my profile',
              onTap: onNewUser,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Material(
        color: AppThemeColors.clear,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
