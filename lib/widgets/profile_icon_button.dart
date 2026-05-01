import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';

class ProfileIconButton extends StatelessWidget {
  const ProfileIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
      },
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: context.appScheme.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.person_fill,
          color: context.appScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}
