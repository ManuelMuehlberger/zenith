import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                CupertinoIcons.flame_fill,
                size: 60,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Welcome to\nWorkout Logger',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Your privacy-respecting, fully offline\nfitness companion',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Material(
        color: Colors.transparent,
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
                    color: CupertinoColors.activeBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: CupertinoColors.activeBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: Colors.grey[600],
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
