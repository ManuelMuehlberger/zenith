import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final Logger _logger = Logger('DatabaseService');

  static DatabaseService get instance => _instance;

  static const String _activeWorkoutKey = 'active_workout';
  static const String _settingsKey = 'app_settings';

  // Active Workout State Management
  Future<void> saveActiveWorkoutState(Map<String, dynamic> workoutState) async {
    _logger.fine('Saving active workout state');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeWorkoutKey, jsonEncode(workoutState));
      _logger.fine('Active workout state saved successfully');
    } catch (e) {
      _logger.severe('Failed to save active workout state: $e');
    }
  }

  Future<Map<String, dynamic>?> getActiveWorkoutState() async {
    _logger.fine('Getting active workout state');
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_activeWorkoutKey);

      if (stateJson != null) {
        _logger.fine('Active workout state found');
        return jsonDecode(stateJson);
      }
      _logger.fine('No active workout state found');
      return null;
    } catch (e) {
      _logger.severe('Failed to get active workout state: $e');
      return null;
    }
  }

  Future<void> clearActiveWorkoutState() async {
    _logger.fine('Clearing active workout state');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeWorkoutKey);
      _logger.fine('Active workout state cleared successfully');
    } catch (e) {
      _logger.severe('Failed to clear active workout state: $e');
    }
  }

  // App Settings Management
  Future<Map<String, dynamic>> getAppSettings() async {
    _logger.fine('Getting app settings');
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        _logger.fine('App settings found');
        return jsonDecode(settingsJson);
      }

      _logger.fine('No app settings found, returning default settings');
      return {
        'units': 'metric', // 'metric' or 'imperial'
        'theme': 'dark',
      };
    } catch (e) {
      _logger.severe(
        'Failed to get app settings, returning default settings: $e',
      );
      return {'units': 'metric', 'theme': 'dark'};
    }
  }

  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    _logger.fine('Saving app settings');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(settings));
      _logger.fine('App settings saved successfully');
    } catch (e) {
      _logger.severe('Failed to save app settings: $e');
    }
  }

  Future<void> clearAllData() async {
    _logger.warning('Clearing all data from SharedPreferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeWorkoutKey);
      await prefs.remove(_settingsKey);
      _logger.info('All data cleared successfully');
    } catch (e) {
      _logger.severe('Failed to clear all data: $e');
    }
  }
}
