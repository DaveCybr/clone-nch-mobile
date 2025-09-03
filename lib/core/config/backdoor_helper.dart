import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

class BackdoorHelper {
  static const String _customBaseUrlKey = 'custom_base_url';
  static const String _defaultBaseUrl = 'https://be.nurulchotib.com';

  // Callback untuk refresh services ketika URL berubah
  static List<Function()> _refreshCallbacks = [];

  // Register callback untuk refresh services
  static void registerRefreshCallback(Function() callback) {
    _refreshCallbacks.add(callback);
    print(
      '🔗 Registered refresh callback. Total callbacks: ${_refreshCallbacks.length}',
    );
  }

  // Unregister callback
  static void unregisterRefreshCallback(Function() callback) {
    _refreshCallbacks.remove(callback);
    print(
      '🔗 Unregistered refresh callback. Total callbacks: ${_refreshCallbacks.length}',
    );
  }

  // Clear all callbacks
  static void clearAllCallbacks() {
    _refreshCallbacks.clear();
    print('🔗 All refresh callbacks cleared');
  }

  // Panggil semua refresh callbacks
  static void _notifyUrlChanged() {
    print('🔄 Notifying ${_refreshCallbacks.length} services of URL change...');

    for (int i = 0; i < _refreshCallbacks.length; i++) {
      try {
        _refreshCallbacks[i]();
        print('✅ Successfully notified service ${i + 1}');
      } catch (e) {
        print('❌ Error calling refresh callback ${i + 1}: $e');
      }
    }

    print('🔄 URL change notification complete');
  }

  // Cek apakah ada custom base URL yang tersimpan
  static Future<void> initializeBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customBaseUrl = prefs.getString(_customBaseUrlKey);

      if (customBaseUrl != null && customBaseUrl.isNotEmpty) {
        // Validasi URL sebelum menggunakan
        if (_isValidUrl(customBaseUrl)) {
          AppConfig.url = customBaseUrl;
          AppConfig.baseUrl = '$customBaseUrl/api';
          print('🔧 Using custom base URL: $customBaseUrl');
        } else {
          print('⚠️  Invalid custom URL found: $customBaseUrl, using default');
          await _setDefaultUrl();
        }
      } else {
        // Jika tidak ada, gunakan default
        await _setDefaultUrl();
      }
    } catch (e) {
      print('❌ Error initializing base URL: $e');
      print('🔧 Falling back to default URL');
      await _setDefaultUrl();
    }
  }

  // Helper method untuk set default URL
  static Future<void> _setDefaultUrl() async {
    try {
      AppConfig.url = _defaultBaseUrl;
      AppConfig.baseUrl = '$_defaultBaseUrl/api';
      print('🔧 Using default base URL: $_defaultBaseUrl');
    } catch (e) {
      print('❌ Critical error setting default URL: $e');
    }
  }

  // Validasi URL
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  // Simpan custom base URL
  static Future<bool> setCustomBaseUrl(String newBaseUrl) async {
    try {
      // Validasi URL terlebih dahulu
      if (!_isValidUrl(newBaseUrl)) {
        print('❌ Invalid URL format: $newBaseUrl');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customBaseUrlKey, newBaseUrl);

      // Update AppConfig
      AppConfig.url = newBaseUrl;
      AppConfig.baseUrl = '$newBaseUrl/api';

      print('🔧 Custom base URL saved: $newBaseUrl');
      print('🔧 AppConfig.url updated to: ${AppConfig.url}');
      print('🔧 AppConfig.baseUrl updated to: ${AppConfig.baseUrl}');

      // Notify all services to refresh their instances
      _notifyUrlChanged();

      return true;
    } catch (e) {
      print('❌ Error saving custom base URL: $e');
      return false;
    }
  }

  // Reset ke default base URL
  static Future<bool> resetToDefaultBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customBaseUrlKey);

      // Update AppConfig
      AppConfig.url = _defaultBaseUrl;
      AppConfig.baseUrl = '$_defaultBaseUrl/api';

      print('🔧 Reset to default base URL: $_defaultBaseUrl');
      print('🔧 AppConfig.url updated to: ${AppConfig.url}');
      print('🔧 AppConfig.baseUrl updated to: ${AppConfig.baseUrl}');

      // Notify all services to refresh their instances
      _notifyUrlChanged();

      return true;
    } catch (e) {
      print('❌ Error resetting to default base URL: $e');
      return false;
    }
  }

  // Get current base URL
  static String getCurrentBaseUrl() {
    return AppConfig.url;
  }

  // Get default base URL
  static String getDefaultBaseUrl() {
    return _defaultBaseUrl;
  }

  // Cek apakah sedang menggunakan custom URL
  static Future<bool> isUsingCustomUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_customBaseUrlKey) != null;
    } catch (e) {
      print('❌ Error checking custom URL status: $e');
      return false;
    }
  }

  // Get custom URL dari storage
  static Future<String?> getCustomBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_customBaseUrlKey);
    } catch (e) {
      print('❌ Error getting custom base URL: $e');
      return null;
    }
  }

  // Method untuk debug - cek URL saat ini
  static void debugCurrentUrl() {
    try {
      print('=== DEBUG URL INFO ===');
      print('AppConfig.url: ${AppConfig.url}');
      print('AppConfig.baseUrl: ${AppConfig.baseUrl}');
      print('Default URL: $_defaultBaseUrl');
      print('======================');
    } catch (e) {
      print('❌ Error debugging current URL: $e');
    }
  }

  // Force refresh URL dari SharedPreferences
  static Future<bool> forceRefreshUrl() async {
    try {
      await initializeBaseUrl();
      debugCurrentUrl();
      return true;
    } catch (e) {
      print('❌ Error force refreshing URL: $e');
      return false;
    }
  }

  // Method untuk debug lengkap dengan SharedPreferences
  static Future<void> debugFullStatus() async {
    try {
      print('=== FULL URL DEBUG STATUS ===');
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString(_customBaseUrlKey);

      print('SharedPreferences custom URL: $customUrl');
      print('AppConfig.url: ${AppConfig.url}');
      print('AppConfig.baseUrl: ${AppConfig.baseUrl}');
      print('Default URL: $_defaultBaseUrl');
      print('Is using custom URL: ${customUrl != null}');
      print(
        'URL is valid: ${customUrl != null ? _isValidUrl(customUrl) : 'N/A'}',
      );
      print('=============================');
    } catch (e) {
      print('❌ Error debugging full status: $e');
    }
  }

  // Method untuk memaksa update URL tanpa restart
  static Future<bool> forceUpdateUrl(String newUrl) async {
    try {
      print('🔄 Force updating URL to: $newUrl');

      // Validasi URL terlebih dahulu
      if (!_isValidUrl(newUrl)) {
        print('❌ Invalid URL format: $newUrl');
        return false;
      }

      // Simpan ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customBaseUrlKey, newUrl);

      // Update AppConfig langsung
      AppConfig.url = newUrl;
      AppConfig.baseUrl = '$newUrl/api';

      print('✅ URL force updated:');
      print('   AppConfig.url: ${AppConfig.url}');
      print('   AppConfig.baseUrl: ${AppConfig.baseUrl}');

      // Notify all services to refresh their instances
      _notifyUrlChanged();

      // Debug status
      await debugFullStatus();

      return true;
    } catch (e) {
      print('❌ Error force updating URL: $e');
      return false;
    }
  }
}
