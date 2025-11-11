// UPDATE: lib/v2/app/data/services/storage_service.dart
// Tambahkan section ini ke existing StorageService Anda

import 'dart:developer' as developer;
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
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _sessionValidKey = 'session_valid';

  // ✅ NEW: Schedule done status keys
  static const String _scheduleDonePrefix = 'schedule_done_';

  static const String _keyReadAnnouncements = 'read_announcements';

  @override
  Future<void> onInit() async {
    super.onInit();
    _box = GetStorage();
    await _box.initStorage;

    // Check if session is still valid on app start
    _validateSession();

    // ✅ NEW: Cleanup old schedule done status (older than 7 days)
    _cleanupOldScheduleStatus();
  }

  // ===== TOKEN MANAGEMENT ===== (existing code...)

  Future<void> saveToken(String token, {Duration? expiresIn}) async {
    await _box.write(_tokenKey, token);
    final expiry = DateTime.now().add(expiresIn ?? const Duration(hours: 24));
    await _box.write(_tokenExpiryKey, expiry.toIso8601String());
    await _box.write(_sessionValidKey, true);
  }

  String? getToken() {
    if (!isTokenValid()) {
      return null;
    }
    return _box.read(_tokenKey);
  }

  bool get hasValidToken {
    final token = _box.read(_tokenKey);
    return token != null && isTokenValid();
  }

  bool isTokenValid() {
    final token = _box.read(_tokenKey);
    if (token == null) return false;

    final expiryString = _box.read(_tokenExpiryKey);
    if (expiryString == null) {
      return true;
    }

    try {
      final expiry = DateTime.parse(expiryString);
      final isValid = DateTime.now().isBefore(expiry);

      if (!isValid) {
        clearAuthData();
      }

      return isValid;
    } catch (e) {
      clearAuthData();
      return false;
    }
  }

  DateTime? getTokenExpiry() {
    final expiryString = _box.read(_tokenExpiryKey);
    if (expiryString == null) return null;

    try {
      return DateTime.parse(expiryString);
    } catch (e) {
      return null;
    }
  }

  Future<void> removeToken() async {
    await _box.remove(_tokenKey);
    await _box.remove(_tokenExpiryKey);
    await _box.write(_sessionValidKey, false);
  }

  // ===== USER DATA MANAGEMENT ===== (existing code...)

  Future<void> saveUser(UserModel user) async {
    final userData = user.toJson();
    userData['saved_at'] = DateTime.now().toIso8601String();
    await _box.write(_userKey, userData);
  }

  UserModel? getUser() {
    if (!isSessionValid()) {
      return null;
    }

    final userData = _box.read(_userKey);
    if (userData != null) {
      try {
        return UserModel.fromJson(Map<String, dynamic>.from(userData));
      } catch (e) {
        removeUser();
        return null;
      }
    }
    return null;
  }

  Future<void> removeUser() async {
    await _box.remove(_userKey);
  }

  // ===== SESSION MANAGEMENT ===== (existing code...)

  bool isSessionValid() {
    final isValid = _box.read(_sessionValidKey) ?? false;
    final hasToken = hasValidToken;

    return isValid && hasToken;
  }

  void _validateSession() {
    if (!hasValidToken) {
      invalidateSession();
    }
  }

  Future<void> invalidateSession() async {
    await _box.write(_sessionValidKey, false);
  }

  Future<void> refreshSession() async {
    if (hasValidToken) {
      await _box.write(_sessionValidKey, true);
    }
  }

  // ===== REMEMBER ME ===== (existing code...)

  Future<void> setRememberMe(bool remember) async {
    await _box.write(_rememberMeKey, remember);
  }

  bool getRememberMe() {
    return _box.read(_rememberMeKey) ?? false;
  }

  // ===== LAST LOGIN ===== (existing code...)

  Future<void> saveLastLogin() async {
    await _box.write(_lastLoginKey, DateTime.now().toIso8601String());
  }

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

  // ✅✅✅ NEW SECTION: SCHEDULE DONE STATUS MANAGEMENT ✅✅✅

  /// Mark schedule as done (sudah diabsen) dengan timestamp
  Future<void> markScheduleAsDone(String scheduleId, String date) async {
    final key = _getScheduleDoneKey(scheduleId, date);
    final data = {
      'is_done': true,
      'marked_at': DateTime.now().toIso8601String(),
      'schedule_id': scheduleId,
      'date': date,
    };

    await _box.write(key, data);
    developer.log('✅ Schedule marked as done: $key');
  }

  /// Check if schedule is done
  bool isScheduleDone(String scheduleId, String date) {
    final key = _getScheduleDoneKey(scheduleId, date);
    final data = _box.read(key);

    if (data == null) {
      return false;
    }

    // Support old format (just boolean) and new format (map with timestamp)
    if (data is bool) {
      return data;
    }

    if (data is Map) {
      return data['is_done'] == true;
    }

    return false;
  }

  /// Get timestamp when schedule was marked as done
  DateTime? getScheduleMarkedTime(String scheduleId, String date) {
    final key = _getScheduleDoneKey(scheduleId, date);
    final data = _box.read(key);

    if (data is Map && data['marked_at'] != null) {
      try {
        return DateTime.parse(data['marked_at']);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Clear specific schedule done status
  Future<void> clearScheduleDoneStatus(String scheduleId, String date) async {
    final key = _getScheduleDoneKey(scheduleId, date);
    await _box.remove(key);
    developer.log('🗑️ Cleared schedule done status: $key');
  }

  /// Get all schedule done entries
  Map<String, dynamic> getAllScheduleDoneStatus() {
    final allKeys = _box.getKeys();
    final scheduleKeys = allKeys.where(
      (key) => key.toString().startsWith(_scheduleDonePrefix),
    );

    final result = <String, dynamic>{};
    for (var key in scheduleKeys) {
      result[key] = _box.read(key);
    }

    return result;
  }

  /// Clear all schedule done status
  Future<void> clearAllScheduleDoneStatus() async {
    final allKeys = _box.getKeys();
    final scheduleKeys = allKeys.where(
      (key) => key.toString().startsWith(_scheduleDonePrefix),
    );

    for (var key in scheduleKeys) {
      await _box.remove(key);
    }

    developer.log(
      '🗑️ Cleared all schedule done status (${scheduleKeys.length} items)',
    );
  }

  /// Cleanup old schedule done status (older than specified days)
  Future<void> _cleanupOldScheduleStatus({int daysToKeep = 7}) async {
    try {
      final allKeys = _box.getKeys();
      final scheduleKeys = allKeys.where(
        (key) => key.toString().startsWith(_scheduleDonePrefix),
      );

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      int removedCount = 0;

      for (var key in scheduleKeys) {
        final data = _box.read(key);

        // Try to get date from key or data
        DateTime? entryDate;

        if (data is Map && data['marked_at'] != null) {
          try {
            entryDate = DateTime.parse(data['marked_at']);
          } catch (e) {
            // Invalid date format
          }
        }

        // If we can't determine date or it's older than cutoff, remove it
        if (entryDate == null || entryDate.isBefore(cutoffDate)) {
          await _box.remove(key);
          removedCount++;
        }
      }

      if (removedCount > 0) {
        developer.log('🧹 Cleaned up $removedCount old schedule done entries');
      }
    } catch (e) {
      developer.log('⚠️ Error during schedule cleanup: $e');
    }
  }

  /// Helper: Generate storage key for schedule done status
  String _getScheduleDoneKey(String scheduleId, String date) {
    return '$_scheduleDonePrefix${scheduleId}_$date';
  }

  /// Get schedule done statistics
  Map<String, dynamic> getScheduleDoneStats() {
    final allKeys = _box.getKeys();
    final scheduleKeys = allKeys.where(
      (key) => key.toString().startsWith(_scheduleDonePrefix),
    );

    int totalDone = 0;
    int todayDone = 0;
    int thisWeekDone = 0;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final weekStart = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );

    for (var key in scheduleKeys) {
      final data = _box.read(key);
      if (data is Map && data['is_done'] == true) {
        totalDone++;

        final date = data['date'] as String?;
        if (date != null) {
          if (date == today) {
            todayDone++;
          }

          try {
            final scheduleDate = DateTime.parse(date);
            if (scheduleDate.isAfter(weekStart) ||
                scheduleDate.isAtSameMomentAs(weekStart)) {
              thisWeekDone++;
            }
          } catch (e) {
            // Invalid date format
          }
        }
      }
    }

    return {
      'total_done': totalDone,
      'today_done': todayDone,
      'this_week_done': thisWeekDone,
      'total_entries': scheduleKeys.length,
    };
  }

  // ===== UTILITY METHODS ===== (existing code...)

  Future<void> clearAuthData() async {
    await removeToken();
    await removeUser();
    await invalidateSession();
  }

  Future<void> clearAll() async {
    await _box.erase();
  }

  Map<String, dynamic> getStorageStats() {
    final scheduleDoneStats = getScheduleDoneStats();

    return {
      'has_token': _box.read(_tokenKey) != null,
      'token_valid': isTokenValid(),
      'has_user': _box.read(_userKey) != null,
      'session_valid': isSessionValid(),
      'remember_me': getRememberMe(),
      'token_expiry': getTokenExpiry()?.toIso8601String(),
      'last_login': getLastLogin()?.toIso8601String(),

      // ✅ NEW: Schedule done stats
      'schedule_done_stats': scheduleDoneStats,
    };
  }

  bool isSessionExpiringSoon() {
    final expiry = getTokenExpiry();
    if (expiry == null) return false;

    final oneHourFromNow = DateTime.now().add(const Duration(hours: 1));
    return expiry.isBefore(oneHourFromNow);
  }

  Duration? getSessionTimeRemaining() {
    final expiry = getTokenExpiry();
    if (expiry == null) return null;

    final now = DateTime.now();
    if (expiry.isBefore(now)) return Duration.zero;

    return expiry.difference(now);
  }

  /// Mark announcement as read
  Future<void> markAnnouncementAsRead(String announcementId) async {
    try {
      final readList = getReadAnnouncements();
      if (!readList.contains(announcementId)) {
        readList.add(announcementId);
        await _box.write(_keyReadAnnouncements, readList);
        developer.log(
          '✅ StorageService: Marked announcement $announcementId as read',
        );
      }
    } catch (e) {
      developer.log('❌ StorageService: Error marking announcement as read: $e');
    }
  }

  /// Get list of read announcement IDs
  List<String> getReadAnnouncements() {
    try {
      final data = _box.read<List>(_keyReadAnnouncements);
      if (data != null) {
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      developer.log('❌ StorageService: Error getting read announcements: $e');
      return [];
    }
  }

  /// Check if announcement is read
  bool isAnnouncementRead(String announcementId) {
    return getReadAnnouncements().contains(announcementId);
  }

  /// Mark multiple announcements as read
  Future<void> markMultipleAnnouncementsAsRead(
    List<String> announcementIds,
  ) async {
    try {
      final readList = getReadAnnouncements();
      bool hasChanges = false;

      for (var id in announcementIds) {
        if (!readList.contains(id)) {
          readList.add(id);
          hasChanges = true;
        }
      }

      if (hasChanges) {
        await _box.write(_keyReadAnnouncements, readList);
        developer.log(
          '✅ StorageService: Marked ${announcementIds.length} announcements as read',
        );
      }
    } catch (e) {
      developer.log(
        '❌ StorageService: Error marking multiple announcements: $e',
      );
    }
  }

  /// Clear read announcements (untuk testing)
  Future<void> clearReadAnnouncements() async {
    await _box.remove(_keyReadAnnouncements);
    developer.log('🗑️ StorageService: Cleared read announcements');
  }

  /// Get unread count from list of announcement IDs
  int getUnreadCount(List<String> announcementIds) {
    final readList = getReadAnnouncements();
    return announcementIds.where((id) => !readList.contains(id)).length;
  }
}
