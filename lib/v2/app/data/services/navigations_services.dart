// lib/v2/app/data/services/navigation_service.dart

import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import 'dart:developer' as developer;

class NavigationService extends GetxService {
  static NavigationService get to => Get.find();

  // Track navigation history untuk debugging
  final List<String> _navigationHistory = [];
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);

  // ===== CORE NAVIGATION METHODS =====

  /// Navigate ke route baru (push)
  /// Use this untuk navigasi normal
  Future<void> toNamed(
    String route, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) async {
    _log('→ Navigating to: $route');
    _navigationHistory.add(route);

    await Get.toNamed(route, arguments: arguments, parameters: parameters);
  }

  /// Replace current route (tidak bisa back)
  /// Use this untuk redirect setelah action
  Future<void> offNamed(
    String route, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) async {
    _log('⟳ Replacing route to: $route');
    _navigationHistory.add(route);

    await Get.offNamed(route, arguments: arguments, parameters: parameters);
  }

  /// Clear all routes dan navigate ke route baru
  /// Use this HANYA untuk login/logout flow
  Future<void> offAllNamed(
    String route, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) async {
    _log('🔄 Clearing all routes, navigating to: $route');
    _navigationHistory.clear();
    _navigationHistory.add(route);

    await Get.offAllNamed(route, arguments: arguments, parameters: parameters);
  }

  /// Go back
  void back<T>({T? result}) {
    if (Get.key.currentState?.canPop() ?? false) {
      _log('← Going back');
      Get.back<T>(result: result);
    } else {
      _log('⚠️ Cannot go back, stack empty');
    }
  }

  /// Check if can go back
  bool canGoBack() {
    return Get.key.currentState?.canPop() ?? false;
  }

  // ===== ROLE-BASED NAVIGATION =====

  /// Navigate to dashboard based on user role
  Future<void> toRoleDashboard(String role) async {
    final route = Routes.getDefaultRouteByRole(role);
    _log('🏠 Navigating to role dashboard: $route (role: $role)');
    await offAllNamed(route);
  }

  /// Navigate to login and clear all routes
  Future<void> toLogin() async {
    _log('🔐 Navigating to login');
    await offAllNamed(Routes.LOGIN);
  }

  /// Navigate from splash after auth check
  Future<void> fromSplash(String targetRoute) async {
    _log('🚀 From splash to: $targetRoute');
    await offAllNamed(targetRoute);
  }

  // ===== BOTTOM NAV NAVIGATION =====

  /// Navigate within bottom nav (for tabs)
  /// This ensures proper bottom nav state management
  Future<void> toBottomNavTab(String route) async {
    if (!Routes.hasBottomNav(route)) {
      _log('⚠️ Route $route is not a bottom nav route');
      return;
    }

    _log('📱 Bottom nav tab: $route');

    // Remove intermediate routes, keep only root
    if (_navigationHistory.isNotEmpty) {
      final firstRoute = _navigationHistory.first;
      _navigationHistory.clear();
      _navigationHistory.add(firstRoute);
    }

    _navigationHistory.add(route);
    await Get.offAllNamed(route);
  }

  // ===== FULLSCREEN NAVIGATION =====

  /// Navigate to fullscreen page (outside bottom nav)
  Future<T?> toFullscreen<T>(
    String route, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) async {
    _log('🖥️ Fullscreen: $route');
    return await Get.toNamed<T>(
      route,
      arguments: arguments,
      parameters: parameters,
    );
  }

  // ===== UTILITIES =====

  /// Get current route
  String? get currentRoute => Get.currentRoute;

  /// Check if currently at route
  bool isAt(String route) => Get.currentRoute == route;

  /// Clear navigation history (for debugging)
  void clearHistory() {
    _navigationHistory.clear();
    _log('🗑️ Navigation history cleared');
  }

  /// Print navigation state (for debugging)
  void printState() {
    _log('');
    _log('╔════════════════════════════════════╗');
    _log('║     NAVIGATION STATE               ║');
    _log('╠════════════════════════════════════╣');
    _log('║ Current Route: ${Get.currentRoute ?? "null"}');
    _log('║ Can Go Back: ${canGoBack()}');
    _log('║ History (${_navigationHistory.length} items):');
    for (var i = 0; i < _navigationHistory.length; i++) {
      final isLast = i == _navigationHistory.length - 1;
      _log('║   ${isLast ? "→" : " "} ${_navigationHistory[i]}');
    }
    _log('╚════════════════════════════════════╝');
    _log('');
  }

  void _log(String message) {
    developer.log(message, name: 'NavigationService');
  }
}
