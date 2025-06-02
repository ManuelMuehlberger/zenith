import 'package:flutter/material.dart';

class NavigationHelper {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static Function()? _switchToHomeTab;
  static Function(int)? _switchToTab;
  
  static void registerHomeTabSwitcher(Function() switcher) {
    _switchToHomeTab = switcher;
  }
  
  static void goToHomeTab() {
    if (_switchToHomeTab != null) {
      _switchToHomeTab?.call();
    } else {
    }
  }

  static void registerTabSwitcher(Function(int) switcher) {
    _switchToTab = switcher;
  }

  static void goToTab(int tabIndex) {
    if (_switchToTab != null) {
      _switchToTab?.call(tabIndex);
    } else {
    }
  }

  static void unregisterSwitchers() {
    _switchToHomeTab = null;
    _switchToTab = null;
  }
}
