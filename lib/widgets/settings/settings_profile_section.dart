import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/user_data.dart';
import '../../screens/edit_profile_screen.dart';
import '../../theme/app_theme.dart';

class SettingsProfileSection extends StatelessWidget {
  final UserData? userProfile;
  final VoidCallback onProfileUpdated;

  const SettingsProfileSection({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  Future<void> _navigateToEditProfile(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(builder: (context) => const EditProfileScreen()),
    );

    // If changes were made, reload the profile
    if (result == true) {
      onProfileUpdated();
    }
  }

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Profile', style: textTheme.titleLarge),
            ),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.field,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.person_fill,
                      size: 40,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userProfile?.age.toString() ?? 'Not set',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _navigateToEditProfile(context),
                    child: Text('Edit Profile', style: textTheme.labelLarge),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailItem(
              context: context,
              icon: CupertinoIcons.calendar,
              label: 'Age',
              value: userProfile?.age.toString() ?? 'Not set',
            ),
            _buildDivider(context),
            _buildDetailItem(
              context: context,
              icon: CupertinoIcons.person_2,
              label: 'Gender',
              value: userProfile?.gender.displayLabel ?? 'Not set',
            ),
            _buildDivider(context),
            _buildDetailItem(
              context: context,
              icon: CupertinoIcons.gauge,
              label: 'Weight',
              value:
                  userProfile != null && userProfile!.weightHistory.isNotEmpty
                  ? '${userProfile!.weightHistory.last.value.toStringAsFixed(1)} ${userProfile!.weightUnit}'
                  : 'Not set',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final textTheme = context.appText;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: colors.textSecondary, size: 22),
          const SizedBox(width: 12),
          Text(label, style: textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: textTheme.titleSmall),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: Theme.of(context).dividerColor,
      indent: 58,
    );
  }
}
