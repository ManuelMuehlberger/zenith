import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

class AppNavigationService extends ChangeNotifier {
  static final AppNavigationService _instance = AppNavigationService._internal();

  factory AppNavigationService() => _instance;
  AppNavigationService._internal();

  static AppNavigationService get instance => _instance;

  int _currentTabIndex = 0;

  int get currentTabIndex => _currentTabIndex;

  void goToTab(int tabIndex) {
    if (_currentTabIndex == tabIndex) {
      return;
    }

    _currentTabIndex = tabIndex;
    notifyListeners();
  }

  void goToHomeTab() {
    goToTab(0);
  }

  @visibleForTesting
  void resetForTesting() {
    _currentTabIndex = 0;
    notifyListeners();
  }
}