// lib/v2/app/data/services/version_service.dart

import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionService extends GetxService {
  late Dio _dio;

  // Play Store URL
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.nurulchotib';

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://nch-be-staging.jtinova.com/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  /// Get current app version from device
  Future<String> getCurrentVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      developer.log('📱 Package Version: ${packageInfo.version}');
      return packageInfo.version; // Contoh: "1.0.0"
    } catch (e) {
      developer.log('❌ Error getting current version: $e');
      return '1.0.0'; // Default version
    }
  }

  /// Get current build number from device
  Future<String> getCurrentBuildNumber() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      developer.log('Error getting build number: $e');
      return '1';
    }
  }

  /// Check version from backend
  Future<VersionCheckResult> checkVersion() async {
    try {
      developer.log('🔍 Checking app version...');

      // Get current version
      final currentVersion = await getCurrentVersion();
      developer.log('📱 Current Version: $currentVersion');

      // Call API Laravel
      final response = await _dio.get(
        '/mobile-version',
        queryParameters: {'paginate': false},
      );

      developer.log('✅ Version API Response: ${response.data}');
      developer.log('📊 Response Type: ${response.data.runtimeType}');

      // Parse response - cek struktur data
      dynamic results;

      if (response.data is Map) {
        // Jika response berupa Map, cek key 'results' atau 'data'
        if (response.data.containsKey('results')) {
          results = response.data['results'];
        } else if (response.data.containsKey('data')) {
          results = response.data['data'];
        } else {
          developer.log('⚠️ Unknown response structure: ${response.data.keys}');
          results = [];
        }
      } else if (response.data is List) {
        // Jika response langsung berupa List
        results = response.data;
      } else {
        developer.log('⚠️ Unexpected response type');
        results = [];
      }

      developer.log('📦 Results: $results');

      if (results == null || results.isEmpty) {
        developer.log('⚠️ No version data found');
        return VersionCheckResult(
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          needsUpdate: false,
          forceUpdate: false,
        );
      }

      // Cari versi yang aktif
      // Coba beberapa kemungkinan field name: is_active, status, active
      dynamic activeVersion;

      try {
        // Prioritas 1: Cari yang is_active = true
        activeVersion = results.firstWhere(
          (v) => v['is_active'] == true || v['is_active'] == 1,
          orElse: () => null,
        );
      } catch (e) {
        developer.log('⚠️ No is_active field found');
      }

      if (activeVersion == null) {
        try {
          // Prioritas 2: Cari yang status = "Aktif" atau "active"
          activeVersion = results.firstWhere(
            (v) =>
                v['status']?.toString().toLowerCase() == 'aktif' ||
                v['status']?.toString().toLowerCase() == 'active',
            orElse: () => null,
          );
        } catch (e) {
          developer.log('⚠️ No status field found');
        }
      }

      // Fallback: ambil data pertama
      if (activeVersion == null) {
        developer.log('⚠️ Using first version as fallback');
        activeVersion = results.first;
      }

      developer.log('✅ Active Version Data: $activeVersion');

      final latestVersion =
          activeVersion['version']?.toString() ?? currentVersion;

      // Check for force_update field (jika ada)
      final forceUpdate =
          activeVersion['force_update'] == true ||
          activeVersion['force_update'] == 1 ||
          false;

      developer.log('☁️ Latest Version: $latestVersion');
      developer.log('🔒 Force Update: $forceUpdate');

      // Compare versions
      final needsUpdate = _compareVersions(currentVersion, latestVersion);

      developer.log('🔄 Needs Update: $needsUpdate');

      return VersionCheckResult(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        needsUpdate: needsUpdate,
        forceUpdate: forceUpdate,
        updateMessage:
            needsUpdate
                ? 'إصدار جديد $latestVersion متاح - Versi baru $latestVersion tersedia'
                : null,
      );
    } on DioException catch (e) {
      developer.log('❌ DioException: ${e.type}');
      developer.log('   Message: ${e.message}');
      developer.log('   Response: ${e.response?.data}');
      developer.log('   Status Code: ${e.response?.statusCode}');

      // If API fails, return no update needed
      return VersionCheckResult(
        currentVersion: await getCurrentVersion(),
        latestVersion: await getCurrentVersion(),
        needsUpdate: false,
        forceUpdate: false,
      );
    } catch (e, stackTrace) {
      developer.log('❌ Unexpected error: $e');
      developer.log('   StackTrace: $stackTrace');
      return VersionCheckResult(
        currentVersion: await getCurrentVersion(),
        latestVersion: await getCurrentVersion(),
        needsUpdate: false,
        forceUpdate: false,
      );
    }
  }

  /// Compare two version strings (e.g., "1.0.0" vs "2.0.0")
  bool _compareVersions(String current, String latest) {
    try {
      developer.log('🔍 Comparing versions: $current vs $latest');

      // Remove any non-numeric characters except dots
      String cleanCurrent = current.replaceAll(RegExp(r'[^\d.]'), '');
      String cleanLatest = latest.replaceAll(RegExp(r'[^\d.]'), '');

      developer.log('   Clean current: $cleanCurrent');
      developer.log('   Clean latest: $cleanLatest');

      // Parse versions
      List<int> currentParts =
          cleanCurrent.split('.').map((e) {
            try {
              return int.parse(e);
            } catch (_) {
              return 0;
            }
          }).toList();

      List<int> latestParts =
          cleanLatest.split('.').map((e) {
            try {
              return int.parse(e);
            } catch (_) {
              return 0;
            }
          }).toList();

      // Ensure both have 3 parts
      while (currentParts.length < 3) currentParts.add(0);
      while (latestParts.length < 3) latestParts.add(0);

      developer.log('   Current parts: $currentParts');
      developer.log('   Latest parts: $latestParts');

      // Compare major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) {
          developer.log(
            '✅ Update needed: ${latestParts[i]} > ${currentParts[i]} at position $i',
          );
          return true; // Latest is newer
        } else if (latestParts[i] < currentParts[i]) {
          developer.log('⚠️ Current version is newer at position $i');
          return false; // Current is newer
        }
      }

      developer.log('✅ Versions are equal');
      return false; // Same version
    } catch (e) {
      developer.log('❌ Error comparing versions: $e');
      return false;
    }
  }

  /// Open Play Store
  Future<void> openPlayStore() async {
    try {
      final Uri url = Uri.parse(playStoreUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        developer.log('✅ Opened Play Store');
      } else {
        developer.log('❌ Could not launch Play Store URL');
        Get.snackbar(
          'خطأ - Error',
          'لا يمكن فتح متجر Play - Tidak dapat membuka Play Store',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      developer.log('❌ Error opening Play Store: $e');
      Get.snackbar(
        'خطأ - Error',
        'حدث خطأ - Terjadi kesalahan saat membuka Play Store',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

/// Model for version check result
class VersionCheckResult {
  final String currentVersion;
  final String latestVersion;
  final bool needsUpdate;
  final bool forceUpdate;
  final String? updateMessage;

  VersionCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.needsUpdate,
    required this.forceUpdate,
    this.updateMessage,
  });

  @override
  String toString() {
    return 'VersionCheckResult(current: $currentVersion, latest: $latestVersion, needsUpdate: $needsUpdate, forceUpdate: $forceUpdate)';
  }
}
