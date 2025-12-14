import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../screens/settings_screen.dart';
import '../constants/app_constants.dart';

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
          color: AppConstants.ACCENT_COLOR.withAlpha((255 * 0.2).round()),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          CupertinoIcons.person_fill,
          color: AppConstants.ACCENT_COLOR,
          size: 20,
        ),
      ),
    );
  }
}