// lib/core/services/version_check_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nch_mobile/v1/core/config/app_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/logger.dart';

class VersionCheckService {
  static const String _versionCheckKey = 'last_version_check';
  static const String _skipVersionKey = 'skip_version';
  static const Duration _checkInterval = Duration(
    hours: 6,
  ); // Check every 6 hours

  /// Model untuk response version API
  static VersionResponse? _cachedVersionData;

  /// Check if we should perform version check
  static Future<bool> shouldCheckVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_versionCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      return (now - lastCheck) > _checkInterval.inMilliseconds;
    } catch (e) {
      AppLogger.error('Error checking version check timing', error: e);
      return true; // Default to check if error
    }
  }

  /// Update last check timestamp
  static Future<void> updateLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _versionCheckKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      AppLogger.error('Error updating last check time', error: e);
    }
  }

  /// Get current app version
  static Future<String> getCurrentAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      print('Current app version: ${packageInfo.version}');
      return packageInfo.version;
    } catch (e) {
      AppLogger.error('Error getting current app version', error: e);
      return '1.0.0'; // Default version
    }
  }

  static Future getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token =
          prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('bearer_token');

      return token;
    } catch (e) {
      AppLogger.error('Error getting token', error: e);
      return ''; // Default token
    }
  }

  /// Fetch latest version from API
  static Future<VersionResponse?> fetchLatestVersion() async {
    try {
      final url = '${AppConfig.url}/api/mobile-version';
      AppLogger.info('Checking version from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer ${await getToken()}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final versionResponse = VersionResponse.fromJson(jsonData);
        _cachedVersionData = versionResponse;

        AppLogger.info(
          'Version check successful: ${versionResponse.latestVersion}',
        );
        return versionResponse;
      } else {
        print('Response body: ${response.body}');
        AppLogger.error(
          'Version check failed with status: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error('Error fetching latest version', error: e);
      return null;
    }
  }

  /// Compare versions (returns true if update is needed)
  static bool needsUpdate(String currentVersion, String latestVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);
      print('Current=$currentVersion | Latest(from API)=$latestVersion');

      for (int i = 0; i < 3; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }
      return false; // Same version
    } catch (e) {
      AppLogger.error('Error comparing versions', error: e);
      return false;
    }
  }

  /// Parse version string to numbers
  static List<int> _parseVersion(String version) {
    return version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }

  /// Check if user has skipped this version
  static Future<bool> hasSkippedVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skippedVersion = prefs.getString(_skipVersionKey);
      return skippedVersion == version;
    } catch (e) {
      AppLogger.error('Error checking skipped version', error: e);
      return false;
    }
  }

  /// Mark version as skipped
  static Future<void> skipVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_skipVersionKey, version);
      AppLogger.info('Version $version marked as skipped');
    } catch (e) {
      AppLogger.error('Error skipping version', error: e);
    }
  }

  /// Clear skipped version
  static Future<void> clearSkippedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_skipVersionKey);
    } catch (e) {
      AppLogger.error('Error clearing skipped version', error: e);
    }
  }

  /// Open Play Store for update
  static Future<void> openPlayStore() async {
    try {
      // Replace with your actual Play Store URL
      const playStoreUrl =
          'https://play.google.com/store/apps/details?id=com.nurulchotib';

      if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
        await launchUrl(
          Uri.parse(playStoreUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        AppLogger.error('Cannot open Play Store URL');
      }
    } catch (e) {
      AppLogger.error('Error opening Play Store', error: e);
    }
  }

  /// Main method to check and show update dialog
  static Future<void> checkForUpdates(
    BuildContext context, {
    bool forceCheck = false,
  }) async {
    try {
      // Check if we should perform version check
      // if (!forceCheck && !await shouldCheckVersion()) {
      //   AppLogger.info('Version check skipped - too recent');
      //   return;
      // }

      // Update last check time
      await updateLastCheckTime();

      // Get current version and fetch latest
      final currentVersion = await getCurrentAppVersion();
      // print('Current app version: $currentVersion');
      final versionResponse = await fetchLatestVersion();

      if (versionResponse == null || versionResponse.latestVersion.isEmpty) {
        AppLogger.warning('No version data available');
        return;
      }

      // Check if update is needed
      if (!needsUpdate(currentVersion, versionResponse.latestVersion)) {
        AppLogger.info('App is up to date');
        return;
      }

      // Show update dialog
      if (context.mounted) {
        _showUpdateDialog(context, currentVersion, versionResponse);
      }
    } catch (e) {
      AppLogger.error('Error in version check process', error: e);
    }
  }

  /// Show update dialog
  static void _showUpdateDialog(
    BuildContext context,
    String currentVersion,
    VersionResponse versionResponse,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return UpdateDialog(
          currentVersion: currentVersion,
          latestVersion: versionResponse.latestVersion,
          onUpdate: () {
            Navigator.of(context).pop();
            openPlayStore();
          },
          onSkip: () {
            Navigator.of(context).pop();
            skipVersion(versionResponse.latestVersion);
          },
        );
      },
    );
  }
}

/// Model untuk response API version
class VersionResponse {
  final String message;
  final String latestVersion;
  final bool isActive;

  VersionResponse({
    required this.message,
    required this.latestVersion,
    required this.isActive,
  });

  factory VersionResponse.fromJson(Map<String, dynamic> json) {
    try {
      final results = json['results'] as Map<String, dynamic>;
      final data = results['data'] as List<dynamic>;

      if (data.isNotEmpty) {
        final versionData = data.first as Map<String, dynamic>;
        return VersionResponse(
          message: json['message'] ?? '',
          latestVersion: versionData['version'] ?? '1.0.0',
          isActive: (versionData['is_active'] ?? 0) == 1,
        );
      }

      throw Exception('No version data found');
    } catch (e) {
      AppLogger.error('Error parsing version response', error: e);
      throw Exception('Invalid version response format');
    }
  }
}

/// Update Dialog Widget
class UpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final VoidCallback onUpdate;
  final VoidCallback onSkip;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.onUpdate,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F7836).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.system_update,
              color: Color(0xFF0F7836),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Update Tersedia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F7836),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Versi baru aplikasi telah tersedia!',
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
          ),
          const SizedBox(height: 16),

          // Version info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Versi Saat Ini:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Text(
                      currentVersion,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Versi Terbaru:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Text(
                      latestVersion,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F7836),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Silakan update aplikasi untuk mendapatkan fitur terbaru dan perbaikan bug.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
          child: const Text('Nanti Saja'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F7836),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Update Sekarang',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
