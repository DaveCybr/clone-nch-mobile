// lib/v2/app/modules/security/profile/controllers/security_profile_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/modules/auth/controllers/auth_controller.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/storage_service.dart';
import '../../../../data/models/user_model.dart';
import 'dart:developer' as developer;

class SecurityProfileController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  // State
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Data
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  /// Load user profile
  Future<void> loadProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await _apiService.getCurrentUser();
      currentUser.value = user;

      developer.log('User Profile: ${user.name} - ${user.email}');
    } catch (e) {
      developer.log('Error loading profile: $e');
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Gagal memuat profil: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh profile
  Future<void> refreshProfile() async {
    await loadProfile();
  }

  /// Logout
  Future<void> logout(AuthController authController) async {
    try {
      // Show confirmation dialog
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Get.theme.colorScheme.error,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      // If user cancels, return early
      if (confirm != true) return;

      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Call AuthController's logout method
      // This will handle: API call, FCM token deletion, unsubscribe topics, clear storage
      await authController.logout();

      // Close loading dialog (if still open)
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    } catch (e) {
      developer.log('Logout error in SecurityProfileController: $e');

      // Close any open dialogs
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Show error message
      Get.snackbar(
        'Error',
        'Terjadi kesalahan saat logout. Silakan coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  /// Get user display name
  String get displayName => currentUser.value?.name ?? 'Security';

  /// Get user email
  String get displayEmail => currentUser.value?.email ?? '';

  /// Get user role
  String get displayRole {
    final role = currentUser.value?.currentRole;
    if (role != null && role.isNotEmpty) {
      return role[0].toUpperCase() + role.substring(1);
    }
    return 'Security';
  }

  /// Navigate to settings (placeholder)
  void goToSettings() {
    Get.snackbar(
      'Info',
      'Fitur pengaturan akan segera hadir',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Navigate to help (placeholder)
  void goToHelp() {
    Get.dialog(
      AlertDialog(
        title: const Text('Bantuan'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cara Menggunakan Aplikasi Security:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. Scan QR Code'),
              Text('   • Arahkan kamera ke QR code pengunjung'),
              Text('   • Sistem akan menampilkan informasi pengunjung'),
              SizedBox(height: 8),
              Text('2. Check In'),
              Text('   • Pastikan status "Dapat Check In"'),
              Text('   • Tekan tombol "Check In"'),
              SizedBox(height: 8),
              Text('3. Check Out'),
              Text('   • Scan QR code saat pengunjung keluar'),
              Text('   • Atau check out manual dari daftar pengunjung'),
              SizedBox(height: 8),
              Text('4. Monitor'),
              Text('   • Lihat daftar pengunjung aktif'),
              Text('   • Perhatikan pengunjung yang overstay'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  /// Navigate to about (placeholder)
  void goToAbout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Tentang Aplikasi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'JTI NCH Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Versi 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Aplikasi untuk manajemen kunjungan orang tua di Madrasah',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
        ],
      ),
    );
  }
}
