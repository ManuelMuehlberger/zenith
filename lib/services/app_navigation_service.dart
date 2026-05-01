import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class AppNavigationService extends ChangeNotifier {
  static final AppNavigationService _instance =
      AppNavigationService._internal();
  static final Logger _logger = Logger('AppNavigationService');

  factory AppNavigationService() => _instance;
  AppNavigationService._internal();

  static AppNavigationService get instance => _instance;

  int _currentTabIndex = 0;

  int get currentTabIndex => _currentTabIndex;

  void goToTab(int tabIndex) {
    if (_currentTabIndex == tabIndex) {
      _logger.finer('Ignoring tab change to current index $tabIndex');
      return;
    }

    final previousTabIndex = _currentTabIndex;
    _currentTabIndex = tabIndex;
    _logger.info('Changing tab from $previousTabIndex to $tabIndex');
    notifyListeners();
  }

  void goToHomeTab() {
    goToTab(0);
  }

  @visibleForTesting
  void resetForTesting() {
    _logger.fine('Resetting navigation state for testing');
    _currentTabIndex = 0;
    notifyListeners();
  }
}
