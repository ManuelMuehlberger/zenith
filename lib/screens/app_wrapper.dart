import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../services/user_service.dart';
import '../main.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoading = true;
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final isComplete = await UserService.instance.isOnboardingComplete();
      if (mounted) {
        setState(() {
          _showOnboarding = !isComplete;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _showOnboarding = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blue,
          ),
        ),
      );
    }

    return _showOnboarding 
        ? const OnboardingScreen()
        : const MainScreen();
  }
}
