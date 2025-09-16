import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/user_data.dart';
import 'dao/user_dao.dart';
import 'dao/weight_entry_dao.dart';

class UserService with ChangeNotifier {
  static final UserService _instance = UserService._internal();
  final Logger _logger = Logger('UserService');

  factory UserService({UserDao? userDao, WeightEntryDao? weightEntryDao}) {
    _instance._userDao = userDao ?? UserDao();
    _instance._weightEntryDao = weightEntryDao ?? WeightEntryDao();
    return _instance;
  }
  UserService._internal() {
    _userDao = UserDao();
    _weightEntryDao = WeightEntryDao();
  }
  
  static UserService get instance => _instance;

  // Inject DAOs
  late UserDao _userDao;
  late WeightEntryDao _weightEntryDao;

  UserData? _currentProfile;

  UserData? get currentProfile => _currentProfile;
  bool get hasProfile => _currentProfile != null;

  Future<void> loadUserProfile() async {
    _logger.info('Loading user profile');
    try {
      final users = await _userDao.getAll();
      if (users.isNotEmpty) {
        _currentProfile = users.first;
        _logger.fine('Found user profile with id: ${_currentProfile!.id}');
        
        final weightEntries = await _weightEntryDao.getWeightEntriesByUserId(_currentProfile!.id);
        _currentProfile = _currentProfile!.copyWith(weightHistory: weightEntries);
        _logger.fine('Loaded ${weightEntries.length} weight entries for user');
        
        notifyListeners();
        _logger.info('User profile loaded successfully');
      } else {
        _logger.info('No user profile found');
        _currentProfile = null;
        notifyListeners();
      }
    } catch (e) {
      _logger.severe('Failed to load user profile: $e');
      _currentProfile = null;
      notifyListeners();
    }
  }

  Future<void> saveUserProfile(UserData profile) async {
    _logger.info('Saving user profile for id: ${profile.id}');
    if (profile.name.trim().isEmpty) {
      _logger.warning('User name is empty');
      throw ArgumentError('User name cannot be empty');
    }
    
    try {
      final existingUser = await _userDao.getUserDataById(profile.id);
      
      if (existingUser != null) {
        _logger.fine('Updating existing user profile');
        await _userDao.updateUserData(profile);
      } else {
        _logger.fine('Creating new user profile');
        await _userDao.insert(profile);
      }
      
      _logger.fine('Saving weight history');
      for (final weightEntry in profile.weightHistory) {
        try {
          await _weightEntryDao.addWeightEntryForUser(profile.id, weightEntry);
        } catch (e) {
          _logger.finer('Weight entry already exists, updating: ${weightEntry.id}');
          await _weightEntryDao.updateWeightEntry(profile.id, weightEntry);
        }
      }
      
      _currentProfile = profile;
      notifyListeners();
      _logger.info('User profile saved successfully');
    } catch (e) {
      _logger.severe('Failed to save user profile: $e');
      throw Exception('Failed to save user profile: $e');
    }
  }

  Future<bool> isOnboardingComplete() async {
    _logger.fine('Checking if onboarding is complete');
    try {
      final users = await _userDao.getAll();
      final bool isComplete = users.isNotEmpty;
      _logger.fine('Onboarding complete: $isComplete');
      return isComplete;
    } catch (e) {
      _logger.severe('Failed to check onboarding status: $e');
      return false;
    }
  }

  Future<void> updateProfile(UserData profile) async {
    await saveUserProfile(profile);
  }

  Future<void> clearUserData() async {
    _logger.warning('Clearing all user data');
    try {
      final users = await _userDao.getAll();
      for (final user in users) {
        _logger.fine('Deleting user: ${user.id}');
        await _userDao.delete(user.id);
      }
      
      _currentProfile = null;
      notifyListeners();
      _logger.info('All user data cleared successfully');
    } catch (e) {
      _logger.severe('Failed to clear user data: $e');
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
