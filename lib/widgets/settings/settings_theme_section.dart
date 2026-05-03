import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/user_data.dart';
import '../../theme/app_theme.dart';

class SettingsThemeSection extends StatelessWidget {
  const SettingsThemeSection({
    super.key,
    required this.userProfile,
    required this.onThemeChanged,
  });

  final UserData? userProfile;
  final ValueChanged<AppThemePreference> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;
    final themePreference = AppThemePreference.fromStorage(userProfile?.theme);

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text('Appearance', style: textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Icon(
                      CupertinoIcons.sun_max,
                      color: colors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme Mode', style: textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Follow the system appearance or force light or dark mode.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: colors.field,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              CupertinoSlidingSegmentedControl<
                                AppThemePreference
                              >(
                                backgroundColor: colors.field,
                                thumbColor: colorScheme.primary,
                                groupValue: themePreference,
                                children: {
                                  for (final preference
                                      in AppThemePreference.values)
                                    preference: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        preference.label,
                                        style: textTheme.labelMedium,
                                      ),
                                    ),
                                },
                                onValueChanged: (value) {
                                  if (value != null) {
                                    onThemeChanged(value);
                                  }
                                },
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
