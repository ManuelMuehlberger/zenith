import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/export_import_service.dart';
import '../models/user_profile.dart';
import '../screens/app_wrapper.dart';
import '../widgets/onboarding/welcome_page.dart';
import '../widgets/onboarding/profile_setup_pages.dart';
import '../widgets/onboarding/completion_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // User data
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;
  int _age = 25;
  String _units = 'metric';
  double _weight = 70.0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            WelcomePage(
              onRestoreBackup: _handleRestoreBackup,
              onNewUser: _nextPage,
            ),
            NamePage(
              nameController: _nameController,
              nameFocusNode: _nameFocusNode,
              onNext: _nextPage,
              onBack: _previousPage,
            ),
            AgePage(
              age: _age,
              onAgeChanged: (value) => setState(() => _age = value),
              onNext: _nextPage,
              onBack: _previousPage,
            ),
            UnitsPage(
              units: _units,
              onUnitsChanged: (value) => setState(() => _units = value),
              onNext: _nextPage,
              onBack: _previousPage,
            ),
            WeightPage(
              weight: _weight,
              units: _units,
              onWeightChanged: (value) => setState(() => _weight = value),
              onNext: _nextPage,
              onBack: _previousPage,
            ),
            CompletionPage(
              name: _nameController.text,
              isLoading: false,
              onComplete: _completeOnboarding,
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleRestoreBackup() async {
    //full-screen loading indicator
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const CupertinoAlertDialog(
          title: Text('Restoring Backup'),
          content: Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: CupertinoActivityIndicator(radius: 15.0),
          ),
        );
      },
    );

    try {
      final success = await ExportImportService.instance.importData();
      
      // Pop the loading dialog
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Load the user profile to ensure it's available in UserService
        await UserService.instance.loadUserProfile(); 
        // UserService's saveUserProfile (called by import) already marks onboarding complete.
        // If a profile exists, isOnboardingComplete will be true.
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AppWrapper()),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        }
      } else {
        // Import was cancelled or failed (e.g., user cancelled file picker)
        if (mounted) {
          _showErrorDialog('Restore Cancelled', 'Backup restore was cancelled or no file was selected.');
        }
      }
    } catch (e) {
      // Pop the loading dialog if it's still there
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        _showErrorDialog('Restore Failed', 'Could not restore from backup: ${e.toString()}. Please ensure the file is a valid backup and try again.');
      }
    }
  }

  Future<void> _completeOnboarding() async {
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const CupertinoAlertDialog(
          title: Text('Setting up your profile...'),
          content: Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: CupertinoActivityIndicator(radius: 15.0),
          ),
        );
      },
    );

    try {
      final profile = UserProfile(
        name: _nameController.text.trim(),
        age: _age,
        units: _units,
        weight: _weight,
        createdAt: DateTime.now(),
      );
      
      await UserService.instance.saveUserProfile(profile);
      
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AppWrapper()),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Pop loading dialog
        _showErrorDialog('Setup Failed', 'Failed to save profile: ${e.toString()}');
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
