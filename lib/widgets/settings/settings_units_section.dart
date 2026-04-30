import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_data.dart';
import '../../theme/app_theme.dart';

class SettingsUnitsSection extends StatelessWidget {
  final UserData? userProfile;
  final Function(Units) onUnitsChanged;

  const SettingsUnitsSection({
    super.key,
    required this.userProfile,
    required this.onUnitsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appScheme;
    final textTheme = context.appText;
    final colors = context.appColors;

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
              child: Text('Units', style: textTheme.titleLarge),
            ),
            ListTile(
              leading: Icon(
                CupertinoIcons.gauge,
                color: colors.textSecondary,
                size: 24,
              ),
              title: Text('Weight Units', style: textTheme.titleSmall),
              trailing: Container(
                decoration: BoxDecoration(
                  color: colors.field,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CupertinoSlidingSegmentedControl<Units>(
                  backgroundColor: colors.field,
                  thumbColor: colorScheme.primary,
                  groupValue: userProfile?.units ?? Units.metric,
                  children: {
                    Units.metric: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        Units.metric.weightUnit,
                        style: textTheme.labelMedium,
                      ),
                    ),
                    Units.imperial: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        Units.imperial.weightUnit,
                        style: textTheme.labelMedium,
                      ),
                    ),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      onUnitsChanged(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
