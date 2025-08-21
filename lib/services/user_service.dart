import 'package:flutter/foundation.dart';
import '../models/user_data.dart';
import 'dao/user_dao.dart';
import 'dao/weight_entry_dao.dart';

class UserService with ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService({UserDao? userDao, WeightEntryDao? weightEntryDao}) {
    _instance._userDao = userDao ?? UserDao();
    _instance._weightEntryDao = weightEntryDao ?? WeightEntryDao();
    return _instance;
  }
  UserService._internal();
  
  static UserService get instance => _instance;

  // Inject DAOs
  late UserDao _userDao;
  late WeightEntryDao _weightEntryDao;

  UserData? _currentProfile;

  UserData? get currentProfile => _currentProfile;
  bool get hasProfile => _currentProfile != null;

  Future<void> loadUserProfile() async {
    try {
      // For now, we'll load the first user profile from the database
      // In a real app, you might have a way to select which user profile to load
      final users = await _userDao.getAll();
      if (users.isNotEmpty) {
        _currentProfile = users.first;
        
        // Load weight history for the user
        if (_currentProfile != null) {
          final weightEntries = await _weightEntryDao.getWeightEntriesByUserId(_currentProfile!.id);
          _currentProfile = _currentProfile!.copyWith(weightHistory: weightEntries);
        }
      }
    } catch (e) {
      _currentProfile = null;
    }
  }

  Future<void> saveUserProfile(UserData profile) async {
    try {
      // Check if user already exists
      final existingUser = await _userDao.getUserDataById(profile.id);
      
      if (existingUser != null) {
        // Update existing user
        await _userDao.updateUserData(profile);
      } else {
        // Create new user
        await _userDao.insert(profile);
      }
      
      // Save weight history entries
      for (final weightEntry in profile.weightHistory) {
        try {
          await _weightEntryDao.addWeightEntryForUser(profile.id, weightEntry);
        } catch (e) {
          // If entry already exists, update it
          await _weightEntryDao.updateWeightEntry(profile.id, weightEntry);
        }
      }
      
      _currentProfile = profile;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  Future<bool> isOnboardingComplete() async {
    try {
      // Check if there's at least one user profile in the database
      final users = await _userDao.getAll();
      return users.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateProfile(UserData profile) async {
    await saveUserProfile(profile);
  }

  Future<void> clearUserData() async {
    try {
      // Delete all user data and weight entries from the database
      final users = await _userDao.getAll();
      for (final user in users) {
        await _userDao.delete(user.id);
      }
      
      // Note: Weight entries will be deleted automatically due to foreign key constraints
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

  // Method for testing to reset the service state
  void resetForTesting() {
    _currentProfile = null;
  }
}
