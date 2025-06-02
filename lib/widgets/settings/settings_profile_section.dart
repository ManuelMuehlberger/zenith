import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../screens/edit_profile_screen.dart';

class SettingsProfileSection extends StatelessWidget {
  final UserProfile? userProfile;
  final VoidCallback onProfileUpdated;

  const SettingsProfileSection({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  Future<void> _navigateToEditProfile(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
    
    // If changes were made, reload the profile
    if (result == true) {
      onProfileUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[300],
                ),
              ),
            ),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[800],
                      border: Border.all(color: Colors.grey[500]!, width: 1.5),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userProfile?.name ?? 'Not set',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _navigateToEditProfile(context),
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailItem(
              icon: CupertinoIcons.calendar,
              label: 'Age',
              value: userProfile?.age.toString() ?? 'Not set',
            ),
            _buildDivider(),
            _buildDetailItem(
              icon: CupertinoIcons.gauge,
              label: 'Weight',
              value: userProfile != null 
                  ? '${userProfile!.weight.toStringAsFixed(1)} ${userProfile!.units == 'metric' ? 'kg' : 'lbs'}'
                  : 'Not set',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: Colors.grey[700],
      indent: 58,
    );
  }
}
