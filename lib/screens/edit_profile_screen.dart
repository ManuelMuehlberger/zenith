import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/user_service.dart';
import '../models/user_data.dart';
import '../constants/app_constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  UserData? _userProfile;
  bool _isLoading = true;
  bool _hasChanges = false;

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _weightController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = UserService.instance.currentProfile;
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _nameController.text = profile.name;
          _ageController.text = profile.age.toString();
          if (profile.weightHistory.isNotEmpty) {
            _weightController.text = profile.weightHistory.last.value.toStringAsFixed(1);
          }
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

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveUserProfile() async {
    if (_userProfile == null) return;

    try {
      final currentWeight = double.tryParse(_weightController.text) ?? _userProfile!.weightHistory.last.value;
      final weightHistory = List<WeightEntry>.from(_userProfile!.weightHistory);
      weightHistory.add(WeightEntry(
        timestamp: DateTime.now(),
        value: currentWeight,
      ));
      
      final updatedProfile = UserData(
        name: _nameController.text.trim(),
        birthdate: _calculateBirthdate(int.tryParse(_ageController.text) ?? _userProfile!.age),
        units: _userProfile!.units,
        weightHistory: weightHistory,
        createdAt: _userProfile!.createdAt,
        theme: _userProfile!.theme,

      );

      await UserService.instance.saveUserProfile(updatedProfile);
      setState(() {
        _userProfile = updatedProfile;
        _hasChanges = false;
      });

      if (mounted) {
        _showCupertinoToast('Profile updated');
        Navigator.of(context).pop(true); // Return true to indicate changes were saved
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to update profile: ${e.toString()}');
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: CupertinoColors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              message,
              style: const TextStyle(color: CupertinoColors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
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

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to go back?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Discard'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + kToolbarHeight;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    height: headerHeight,
                    color: Colors.black54,
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
              onPressed: () async {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Icon(CupertinoIcons.back, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_hasChanges)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _saveUserProfile,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
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
          child: SizedBox(height: headerHeight + 16),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildProfileSection(),
                const SizedBox(height: 24),
                _buildUnitsSection(),
                const SizedBox(height: 32),
                if (_hasChanges) _buildSaveButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
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
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            _buildEditableTextField(
              controller: _nameController,
              placeholder: 'Enter your name',
              label: 'Name',
              prefixIcon: CupertinoIcons.person_fill,
            ),
            _buildDivider(),
            _buildEditableTextField(
              controller: _ageController,
              placeholder: 'Enter your age',
              label: 'Age',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: CupertinoIcons.calendar,
            ),
            _buildDivider(),
            _buildEditableTextField(
              controller: _weightController,
              placeholder: 'Enter your weight',
              label: 'Weight (${_userProfile?.weightUnit})',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              prefixIcon: CupertinoIcons.gauge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsSection() {
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
                'Units',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Icon(CupertinoIcons.gauge, color: Colors.grey[400], size: 24),
                title: const Text('Weight Units', style: TextStyle(color: Colors.white, fontSize: 16)),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CupertinoSlidingSegmentedControl<Units>(
                    backgroundColor: Colors.grey[800]!,
                    thumbColor: Colors.blue,
                    groupValue: _userProfile?.units ?? Units.metric,
                    children: {
                      Units.metric: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          Units.metric.weightUnit,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Units.imperial: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          Units.imperial.weightUnit,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    },
                    onValueChanged: (value) {
                      if (value != null) {
                        _updateUnits(value);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUnits(Units newUnits) async {
    if (_userProfile == null) return;

    try {
      final updatedProfile = _userProfile!.copyWith(units: newUnits);
      await UserService.instance.saveUserProfile(updatedProfile);
      setState(() {
        _userProfile = updatedProfile;
        _weightController.text = _userProfile!.weightHistory.last.value.toStringAsFixed(1);
        _hasChanges = true;
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

  Widget _buildEditableTextField({
    required TextEditingController controller,
    required String placeholder,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    IconData? prefixIcon,
  }) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(prefixIcon, color: Colors.grey[400], size: 24),
                  const SizedBox(width: 12),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              placeholderStyle: TextStyle(color: Colors.grey[600]),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              onChanged: (_) => _onFieldChanged(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
        onPressed: _saveUserProfile,
        child: const Text(
          'Save Changes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: Colors.grey[700],
      indent: 16,
      endIndent: 16,
    );
  }
  
  DateTime _calculateBirthdate(int age) {
    final now = DateTime.now();
    return DateTime(now.year - age, now.month, now.day);
  }
}
