import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:io';
import 'app_config.dart';

class BackdoorHelper {
  static const String _customBaseUrlKey = 'custom_base_url';
  static const String _defaultBaseUrl = 'https://be.nurulchotib.com';

  // Enhanced callback management with weak references
  static final List<void Function()> _refreshCallbacks = [];
  static final Connectivity _connectivity = Connectivity();

  // Disposal management
  static bool _disposed = false;

  // Timeout for network operations
  static const Duration _networkTimeout = Duration(seconds: 10);

  /// Register callback untuk refresh services ketika URL berubah
  static void registerRefreshCallback(void Function() callback) {
    if (_disposed || callback == false) return;

    if (!_refreshCallbacks.contains(callback)) {
      _refreshCallbacks.add(callback);
      debugPrint(
        '🔗 Registered refresh callback. Total: ${_refreshCallbacks.length}',
      );
    }
  }

  /// Unregister callback dengan safe removal
  static void unregisterRefreshCallback(void Function() callback) {
    if (_disposed || callback == false) return;

    _refreshCallbacks.remove(callback);
    debugPrint(
      '🔗 Unregistered refresh callback. Total: ${_refreshCallbacks.length}',
    );
  }

  /// Clear all callbacks - useful for testing or complete reset
  static void clearAllCallbacks() {
    _refreshCallbacks.clear();
    debugPrint('🔗 All refresh callbacks cleared');
  }

  /// Safely notify all registered callbacks
  static void _notifyUrlChanged() {
    if (_disposed) return;

    debugPrint(
      '🔄 Notifying ${_refreshCallbacks.length} services of URL change...',
    );

    final callbacksCopy = List<void Function()>.from(_refreshCallbacks);

    for (int i = 0; i < callbacksCopy.length; i++) {
      try {
        callbacksCopy[i]();
        debugPrint('✅ Successfully notified service ${i + 1}');
      } catch (e) {
        debugPrint('❌ Error calling refresh callback ${i + 1}: $e');
        // Remove problematic callback
        _refreshCallbacks.remove(callbacksCopy[i]);
      }
    }

    debugPrint('🔄 URL change notification complete');
  }

  /// Enhanced URL validation with connectivity check
  static Future<bool> _isValidUrlWithConnectivity(String url) async {
    if (!_isValidUrlFormat(url)) return false;

    try {
      // Check basic connectivity first
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('⚠️ No internet connection for URL validation');
        return _isValidUrlFormat(url); // Return format validation only
      }

      // Try to reach the URL with timeout
      final client = HttpClient();
      client.connectionTimeout = _networkTimeout;

      try {
        final uri = Uri.parse(url);
        final request = await client.getUrl(uri).timeout(_networkTimeout);
        final response = await request.close().timeout(_networkTimeout);

        final isReachable =
            response.statusCode >= 200 && response.statusCode < 500;
        debugPrint(
          isReachable
              ? '✅ URL is reachable'
              : '⚠️ URL returned status ${response.statusCode}',
        );

        return isReachable;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('⚠️ URL connectivity check failed: $e');
      // Return format validation as fallback
      return _isValidUrlFormat(url);
    }
  }

  /// Basic URL format validation
  static bool _isValidUrlFormat(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority &&
          uri.host.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Invalid URL format: $e');
      return false;
    }
  }

  /// Enhanced initialization with better error recovery
  static Future<void> initializeBaseUrl() async {
    if (_disposed) return;

    try {
      debugPrint('🔧 Initializing base URL...');

      final prefs = await SharedPreferences.getInstance();
      final customBaseUrl = prefs.getString(_customBaseUrlKey);

      if (customBaseUrl != null && customBaseUrl.isNotEmpty) {
        debugPrint('🔍 Found custom URL: $customBaseUrl');

        // Validate URL format first
        if (_isValidUrlFormat(customBaseUrl)) {
          await _applyUrl(customBaseUrl);
          debugPrint('🔧 Using validated custom base URL: $customBaseUrl');
        } else {
          debugPrint('❌ Invalid custom URL format, reverting to default');
          await _revertToDefault(prefs);
        }
      } else {
        debugPrint('ℹ️ No custom URL found, using default');
        await _setDefaultUrl();
      }
    } catch (e) {
      debugPrint('❌ Critical error initializing base URL: $e');
      await _handleInitializationError(e);
    }
  }

  /// Apply URL with validation
  static Future<void> _applyUrl(String url) async {
    AppConfig.url = url;
    AppConfig.baseUrl = '$url/api';
  }

  /// Revert to default when custom URL is invalid
  static Future<void> _revertToDefault(SharedPreferences prefs) async {
    await prefs.remove(_customBaseUrlKey);
    await _setDefaultUrl();
  }

  /// Set default URL safely
  static Future<void> _setDefaultUrl() async {
    try {
      await _applyUrl(_defaultBaseUrl);
      debugPrint('🔧 Default base URL applied: $_defaultBaseUrl');
    } catch (e) {
      debugPrint('❌ Critical error setting default URL: $e');
      throw Exception('Failed to set default URL: $e');
    }
  }

  /// Handle initialization errors with fallback
  static Future<void> _handleInitializationError(dynamic error) async {
    debugPrint('🚨 Handling initialization error: $error');

    try {
      // Last resort: set default URL directly
      AppConfig.url = _defaultBaseUrl;
      AppConfig.baseUrl = '$_defaultBaseUrl/api';
      debugPrint('🔧 Emergency fallback to default URL applied');
    } catch (e) {
      debugPrint('💥 Complete failure in URL initialization: $e');
      rethrow;
    }
  }

  /// Enhanced custom URL setting with comprehensive validation
  static Future<bool> setCustomBaseUrl(String newBaseUrl) async {
    if (_disposed) return false;

    if (newBaseUrl.isEmpty) {
      debugPrint('❌ Cannot set empty URL');
      return false;
    }

    try {
      debugPrint('🔧 Attempting to set custom URL: $newBaseUrl');

      // Validate URL format
      if (!_isValidUrlFormat(newBaseUrl)) {
        debugPrint('❌ Invalid URL format: $newBaseUrl');
        return false;
      }

      // Test connectivity to URL (with timeout)
      final isReachable = await _isValidUrlWithConnectivity(newBaseUrl).timeout(
        _networkTimeout,
        onTimeout: () {
          debugPrint(
            '⏰ URL validation timeout, proceeding with format validation',
          );
          return _isValidUrlFormat(newBaseUrl);
        },
      );

      if (!isReachable) {
        debugPrint('❌ URL is not reachable: $newBaseUrl');
        // Still allow setting if format is valid (for offline scenarios)
        if (!_isValidUrlFormat(newBaseUrl)) {
          return false;
        }
        debugPrint('⚠️ Proceeding with unreachable but valid URL');
      }

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customBaseUrlKey, newBaseUrl);

      // Update AppConfig
      await _applyUrl(newBaseUrl);

      debugPrint('✅ Custom base URL set successfully');
      debugPrint('   AppConfig.url: ${AppConfig.url}');
      debugPrint('   AppConfig.baseUrl: ${AppConfig.baseUrl}');

      // Notify all registered services
      _notifyUrlChanged();

      return true;
    } catch (e) {
      debugPrint('❌ Error setting custom base URL: $e');
      return false;
    }
  }

  /// Enhanced reset with better error handling
  static Future<bool> resetToDefaultBaseUrl() async {
    if (_disposed) return false;

    try {
      debugPrint('🔄 Resetting to default base URL...');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customBaseUrlKey);

      await _setDefaultUrl();

      debugPrint('✅ Successfully reset to default URL');
      debugPrint('   AppConfig.url: ${AppConfig.url}');
      debugPrint('   AppConfig.baseUrl: ${AppConfig.baseUrl}');

      _notifyUrlChanged();

      return true;
    } catch (e) {
      debugPrint('❌ Error resetting to default base URL: $e');
      return false;
    }
  }

  /// Get current base URL safely
  static String? getCurrentBaseUrl() {
    return AppConfig.url;
  }

  /// Get default base URL
  static String getDefaultBaseUrl() {
    return _defaultBaseUrl;
  }

  /// Check if using custom URL with error handling
  static Future<bool> isUsingCustomUrl() async {
    if (_disposed) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString(_customBaseUrlKey);
      return customUrl != null && customUrl.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking custom URL status: $e');
      return false;
    }
  }

  /// Get custom URL from storage safely
  static Future<String?> getCustomBaseUrl() async {
    if (_disposed) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_customBaseUrlKey);
    } catch (e) {
      debugPrint('❌ Error getting custom base URL: $e');
      return null;
    }
  }

  /// Debug current URL configuration
  static void debugCurrentUrl() {
    if (_disposed) return;

    try {
      debugPrint('=== DEBUG URL INFO ===');
      debugPrint('AppConfig.url: ${AppConfig.url}');
      debugPrint('AppConfig.baseUrl: ${AppConfig.baseUrl}');
      debugPrint('Default URL: $_defaultBaseUrl');
      debugPrint('Callbacks registered: ${_refreshCallbacks.length}');
      debugPrint('======================');
    } catch (e) {
      debugPrint('❌ Error debugging current URL: $e');
    }
  }

  /// Force refresh URL configuration
  static Future<bool> forceRefreshUrl() async {
    if (_disposed) return false;

    try {
      debugPrint('🔄 Force refreshing URL configuration...');

      await initializeBaseUrl();
      debugCurrentUrl();

      debugPrint('✅ URL configuration refreshed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error force refreshing URL: $e');
      return false;
    }
  }

  /// Enhanced full debug status with connectivity info
  static Future<void> debugFullStatus() async {
    if (_disposed) return;

    try {
      debugPrint('=== FULL URL DEBUG STATUS ===');

      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString(_customBaseUrlKey);
      final connectivityResult = await _connectivity.checkConnectivity();

      debugPrint('SharedPreferences custom URL: $customUrl');
      debugPrint('AppConfig.url: ${AppConfig.url}');
      debugPrint('AppConfig.baseUrl: ${AppConfig.baseUrl}');
      debugPrint('Default URL: $_defaultBaseUrl');
      debugPrint('Is using custom URL: ${customUrl != null}');
      debugPrint(
        'URL format valid: ${customUrl != null ? _isValidUrlFormat(customUrl) : 'N/A'}',
      );
      debugPrint('Connectivity: $connectivityResult');
      debugPrint('Callbacks registered: ${_refreshCallbacks.length}');
      debugPrint('Service disposed: $_disposed');
      debugPrint('=============================');
    } catch (e) {
      debugPrint('❌ Error debugging full status: $e');
    }
  }

  /// Enhanced force update with better validation
  static Future<bool> forceUpdateUrl(String newUrl) async {
    if (_disposed) return false;

    debugPrint('🔄 Force updating URL to: $newUrl');

    if (newUrl.isEmpty) {
      debugPrint('❌ Cannot force update to empty URL');
      return false;
    }

    try {
      // Validate format
      if (!_isValidUrlFormat(newUrl)) {
        debugPrint('❌ Invalid URL format for force update: $newUrl');
        return false;
      }

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customBaseUrlKey, newUrl);

      // Update AppConfig immediately
      await _applyUrl(newUrl);

      debugPrint('✅ URL force updated successfully:');
      debugPrint('   AppConfig.url: ${AppConfig.url}');
      debugPrint('   AppConfig.baseUrl: ${AppConfig.baseUrl}');

      // Notify services
      _notifyUrlChanged();

      // Debug verification
      await debugFullStatus();

      return true;
    } catch (e) {
      debugPrint('❌ Error force updating URL: $e');
      return false;
    }
  }

  /// Test URL connectivity
  static Future<bool> testUrlConnectivity(String url) async {
    if (_disposed || url.isEmpty) return false;

    debugPrint('🔍 Testing connectivity to: $url');

    try {
      return await _isValidUrlWithConnectivity(url);
    } catch (e) {
      debugPrint('❌ Error testing URL connectivity: $e');
      return false;
    }
  }

  /// Dispose resources
  static void dispose() {
    debugPrint('🗑️ Disposing BackdoorHelper');
    _disposed = true;
    clearAllCallbacks();
  }

  /// Check if disposed
  static bool get isDisposed => _disposed;
}
