// UPDATE: lib/v2/app/data/services/storage_service.dart
// Replace existing with this enhanced version

import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';

class StorageService extends GetxService {
  late GetStorage _box;

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _rememberMeKey = 'remember_me';
  static const String _lastLoginKey = 'last_login';
  static const String _tokenExpiryKey = 'token_expiry'; // NEW
  static const String _sessionValidKey = 'session_valid'; // NEW

  @override
  Future<void> onInit() async {
    super.onInit();
    _box = GetStorage();
    await _box.initStorage;
    
    // Check if session is still valid on app start
    _validateSession();
  }

  // ===== TOKEN MANAGEMENT =====

  /// Save token with optional expiry time
  Future<void> saveToken(String token, {Duration? expiresIn}) async {
    await _box.write(_tokenKey, token);
    
    // Set token expiry (default: 24 hours if not specified)
    final expiry = DateTime.now().add(expiresIn ?? const Duration(hours: 24));
    await _box.write(_tokenExpiryKey, expiry.toIso8601String());
    
    // Mark session as valid
    await _box.write(_sessionValidKey, true);
  }

  /// Get token if it's still valid
  String? getToken() {
    if (!isTokenValid()) {
      return null;
    }
    return _box.read(_tokenKey);
  }

  /// Check if token exists and is still valid
  bool get hasValidToken {
    final token = _box.read(_tokenKey);
    return token != null && isTokenValid();
  }

  /// Check if token is still valid (not expired)
  bool isTokenValid() {
    final token = _box.read(_tokenKey);
    if (token == null) return false;
    
    final expiryString = _box.read(_tokenExpiryKey);
    if (expiryString == null) {
      // If no expiry set, assume token is valid for backward compatibility
      return true;
    }
    
    try {
      final expiry = DateTime.parse(expiryString);
      final isValid = DateTime.now().isBefore(expiry);
      
      if (!isValid) {
        // Token expired, clear it
        clearAuthData();
      }
      
      return isValid;
    } catch (e) {
      // Invalid expiry format, clear token
      clearAuthData();
      return false;
    }
  }

  /// Get token expiry time
  DateTime? getTokenExpiry() {
    final expiryString = _box.read(_tokenExpiryKey);
    if (expiryString == null) return null;
    
    try {
      return DateTime.parse(expiryString);
    } catch (e) {
      return null;
    }
  }

  /// Remove token and related data
  Future<void> removeToken() async {
    await _box.remove(_tokenKey);
    await _box.remove(_tokenExpiryKey);
    await _box.write(_sessionValidKey, false);
  }

  // ===== USER DATA MANAGEMENT =====

  /// Save user data with timestamp
  Future<void> saveUser(UserModel user) async {
    final userData = user.toJson();
    userData['saved_at'] = DateTime.now().toIso8601String();
    await _box.write(_userKey, userData);
  }

  /// Get user data if session is valid
  UserModel? getUser() {
    if (!isSessionValid()) {
      return null;
    }
    
    final userData = _box.read(_userKey);
    if (userData != null) {
      try {
        return UserModel.fromJson(Map<String, dynamic>.from(userData));
      } catch (e) {
        // Invalid user data format, clear it
        removeUser();
        return null;
      }
    }
    return null;
  }

  /// Remove user data
  Future<void> removeUser() async {
    await _box.remove(_userKey);
  }

  // ===== SESSION MANAGEMENT =====

  /// Check if session is valid
  bool isSessionValid() {
    final isValid = _box.read(_sessionValidKey) ?? false;
    final hasToken = hasValidToken;
    
    return isValid && hasToken;
  }

  /// Validate session on app start
  void _validateSession() {
    if (!hasValidToken) {
      invalidateSession();
    }
  }

  /// Invalidate current session
  Future<void> invalidateSession() async {
    await _box.write(_sessionValidKey, false);
  }

  /// Refresh session validity
  Future<void> refreshSession() async {
    if (hasValidToken) {
      await _box.write(_sessionValidKey, true);
    }
  }

  // ===== REMEMBER ME =====

  /// Set remember me preference
  Future<void> setRememberMe(bool remember) async {
    await _box.write(_rememberMeKey, remember);
  }

  /// Get remember me preference
  bool getRememberMe() {
    return _box.read(_rememberMeKey) ?? false;
  }

  // ===== LAST LOGIN =====

  /// Save last login timestamp
  Future<void> saveLastLogin() async {
    await _box.write(_lastLoginKey, DateTime.now().toIso8601String());
  }

  /// Get last login time
  DateTime? getLastLogin() {
    final lastLogin = _box.read(_lastLoginKey);
    if (lastLogin != null) {
      try {
        return DateTime.parse(lastLogin);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ===== UTILITY METHODS =====

  /// Clear only authentication-related data
  Future<void> clearAuthData() async {
    await removeToken();
    await removeUser();
    await invalidateSession();
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _box.erase();
  }

  /// Get storage stats for debugging
  Map<String, dynamic> getStorageStats() {
    return {
      'has_token': _box.read(_tokenKey) != null,
      'token_valid': isTokenValid(),
      'has_user': _box.read(_userKey) != null,
      'session_valid': isSessionValid(),
      'remember_me': getRememberMe(),
      'token_expiry': getTokenExpiry()?.toIso8601String(),
      'last_login': getLastLogin()?.toIso8601String(),
    };
  }

  /// Check if user session is about to expire (within 1 hour)
  bool isSessionExpiringSoon() {
    final expiry = getTokenExpiry();
    if (expiry == null) return false;
    
    final oneHourFromNow = DateTime.now().add(const Duration(hours: 1));
    return expiry.isBefore(oneHourFromNow);
  }

  /// Get remaining session time
  Duration? getSessionTimeRemaining() {
    final expiry = getTokenExpiry();
    if (expiry == null) return null;
    
    final now = DateTime.now();
    if (expiry.isBefore(now)) return Duration.zero;
    
    return expiry.difference(now);
  }
}