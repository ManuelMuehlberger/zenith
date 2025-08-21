import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';

class UserService with ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();
  
  static UserService get instance => _instance;

  static const String _userProfileKey = 'user_profile';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  UserData? _currentProfile;

  UserData? get currentProfile => _currentProfile;
  bool get hasProfile => _currentProfile != null;

  Future<void> loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      
      if (profileJson != null) {
        final profileMap = jsonDecode(profileJson);
        _currentProfile = UserData.fromMap(profileMap);
      }
    } catch (e) {
      _currentProfile = null;
    }
  }

  Future<void> saveUserProfile(UserData profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userProfileKey, jsonEncode(profile.toMap()));
      await prefs.setBool(_onboardingCompleteKey, true);
      _currentProfile = profile;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompleteKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateProfile(UserData profile) async {
    await saveUserProfile(profile);
  }

  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      await prefs.remove(_onboardingCompleteKey);
      _currentProfile = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to clear user data: $e');
    }
  }

  String getGreeting() {
    if (_currentProfile == null) return 'Welcome';
    
    final hour = DateTime.now().hour;
    String timeGreeting;
    
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }
    
    return '$timeGreeting, ${_currentProfile!.name}';
  }

  String formatWeight(double weight) {
    if (_currentProfile == null) return weight.toString();

    final unit = _currentProfile!.weightUnit;
    return '${weight.toStringAsFixed(1)} $unit';
  }

}
