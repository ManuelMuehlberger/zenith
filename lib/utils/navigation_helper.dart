import 'package:flutter/material.dart';
import '../services/app_navigation_service.dart';

class NavigationHelper {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static void goToHomeTab() {
    AppNavigationService.instance.goToHomeTab();
  }

  static void goToTab(int tabIndex) {
    AppNavigationService.instance.goToTab(tabIndex);
  }
}
