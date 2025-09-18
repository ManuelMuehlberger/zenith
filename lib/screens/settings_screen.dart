import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import '../services/database_service.dart';
import '../services/user_service.dart';
import '../services/workout_service.dart';
import '../services/workout_template_service.dart';
import '../models/user_data.dart';
import '../widgets/settings/settings_timeline_section.dart';
import '../widgets/settings/settings_profile_section.dart';
import '../widgets/settings/settings_units_section.dart';
import '../widgets/settings/settings_data_section.dart';
import '../constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserData? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = UserService.instance.currentProfile;
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load profile: ${e.toString()}');
    }
  }

  Future<void> _updateUnits(Units newUnits) async {
    if (_userProfile == null) return;

    try {
      final updatedProfile = _userProfile!.copyWith(units: newUnits);
      await UserService.instance.saveUserProfile(updatedProfile);
      setState(() {
        _userProfile = updatedProfile;
      });

      if (mounted) {
        _showCupertinoToast('Units updated');
      }
    } catch (e) {
      if (mounted) {
         _showErrorDialog('Failed to update units: ${e.toString()}');
      }
    }
  }

  void _showCupertinoToast(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom + 80,
        left: MediaQuery.of(context).size.width * 0.15,
        right: MediaQuery.of(context).size.width * 0.15,
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  decoration: TextDecoration.none,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
  
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    final TextEditingController confirmController = TextEditingController();
    String confirmationText = '';
    const String requiredText = 'DELETE MY DATA';

    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return CupertinoAlertDialog(
              title: const Text('Clear All Data'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This will permanently delete all your workout data and profile. This action cannot be undone.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please type "$requiredText" below to confirm:',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: confirmController,
                    placeholder: requiredText,
                    autocorrect: false,
                    style: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
                    onChanged: (value) {
                      setStateDialog(() {
                        confirmationText = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: confirmationText == requiredText
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: Text(
                    'Delete All',
                    style: TextStyle(
                      color: confirmationText == requiredText
                          ? CupertinoColors.destructiveRed
                          : CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    confirmController.dispose();

    if (confirmed == true) {
      await DatabaseService.instance.clearAllData();
      await UserService.instance.clearUserData();
      await WorkoutService.instance.clearUserWorkouts();
      await WorkoutTemplateService.instance.clearUserTemplatesAndFolders();
      if (mounted) {
        _showCupertinoToast('All data cleared');
        await Future.delayed(const Duration(seconds: 1));
        exit(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + kToolbarHeight;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildMainContent(headerHeight),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: AppConstants.GLASS_BLUR_SIGMA, sigmaY: AppConstants.GLASS_BLUR_SIGMA),
                child: Container(
                  height: headerHeight,
                  color: AppConstants.HEADER_BG_COLOR_MEDIUM,
                  child: SafeArea(
                    bottom: false,
                    child: _buildHeaderContent(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent() {
    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(CupertinoIcons.back, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(double headerHeight) {
    if (_isLoading) {
      return Column(
        children: [
          SizedBox(height: headerHeight),
          const Expanded(
            child: Center(
              child: CupertinoActivityIndicator(radius: 15),
            ),
          ),
        ],
      );
    }

    if (_userProfile == null) {
      return Column(
        children: [
          SizedBox(height: headerHeight),
          const Expanded(
            child: Center(
              child: Text(
                'No profile found',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: headerHeight),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SettingsTimelineSection(),
                const SizedBox(height: 16),
                SettingsProfileSection(
                  userProfile: _userProfile,
                  onProfileUpdated: _loadUserProfile,
                ),
                const SizedBox(height: 16),
                SettingsUnitsSection(
                  userProfile: _userProfile,
                  onUnitsChanged: _updateUnits,
                ),
                const SizedBox(height: 16),
                const SettingsDataSection(),
                const SizedBox(height: 16),
                _buildAboutSection(),
                const SizedBox(height: 16),
                _buildDataManagementSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      color: Colors.grey[900],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
              child: Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.trash_fill, color: Colors.red, size: 22),
              title: const Text(
                'Clear All Data',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text(
                'Permanently delete all data and profile',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: Icon(
                CupertinoIcons.chevron_right,
                color: Colors.grey[400],
                size: 16,
              ),
              onTap: _clearAllData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(CupertinoIcons.lock_shield_fill, color: Colors.green, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy First',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        'All data stays on your device\nNo cloud, no tracking, no ads',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(CupertinoIcons.info_circle_fill, color: Colors.blue, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout Tracker',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        'Version 1.0.0\nTrack your fitness journey',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(CupertinoIcons.flame_fill, color: Colors.grey[400], size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercise Database',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        '312 exercises available',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
