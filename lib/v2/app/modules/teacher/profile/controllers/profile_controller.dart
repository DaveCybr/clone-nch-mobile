// lib/v2/app/modules/teacher/profile/controllers/profile_controller.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/storage_service.dart';
import '../../../auth/controllers/auth_controller.dart';

class ProfileController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  final AuthController _authController = Get.find<AuthController>();

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

      // Get current user from auth controller
      currentUser.value = _authController.user.value;

      if (currentUser.value != null) {
        // Try to get fresh data from API
        try {
          final profileData = await _apiService.getTeacherProfile();

          // 🔍 DEBUG: Log full response
          developer.log('=== TEACHER PROFILE API RESPONSE ===');
          developer.log('Full Response: $profileData');

          if (profileData['data'] != null) {
            developer.log('📦 Data found in "data" key');
            currentUser.value = UserModel.fromJson(profileData['data']);
          } else if (profileData['user'] != null) {
            developer.log('📦 Data found in "user" key');
            currentUser.value = UserModel.fromJson(profileData['user']);
          } else {
            developer.log('📦 Using direct response');
            currentUser.value = UserModel.fromJson(profileData);
          }

          // 🔍 DEBUG: Log parsed user data
          developer.log('=== PARSED USER DATA ===');
          developer.log('Name: ${currentUser.value?.name}');
          developer.log('Email: ${currentUser.value?.email}');
          developer.log('Phone: ${currentUser.value?.phoneNumber}');
          developer.log('NIP: ${currentUser.value?.nip}');
          developer.log('Employee: ${currentUser.value?.employee}');

          // Try to get NIP from employee if not in user
          if (currentUser.value?.nip == null || currentUser.value?.nip == '-') {
            developer.log('⚠️ NIP not found in user, checking employee...');
            final employee = currentUser.value?.employee;
            if (employee != null) {
              developer.log('Employee NIP: ${employee.nip}');
            }
          }

          _authController.user.value = currentUser.value;
          await _storageService.saveUser(currentUser.value!);
        } catch (e, stackTrace) {
          developer.log('❌ Failed to fetch fresh profile data: $e');
          developer.log('Stack trace: $stackTrace');
          // Continue with cached data
        }
      }

      developer.log(
        'User Profile: ${currentUser.value?.name} - ${currentUser.value?.email}',
      );
    } catch (e) {
      developer.log('Error loading profile: $e');
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Gagal memuat profil: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh profile
  Future<void> refreshProfile() async {
    await loadProfile();
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      Get.snackbar(
        'Error',
        'Konfirmasi password tidak cocok',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      await _apiService.dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
      );

      Get.back(); // Close dialog
      Get.snackbar(
        'تبارك الله',
        'Password berhasil diubah',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      developer.log('Error changing password: $e');
      Get.snackbar(
        'Error',
        'Gagal mengubah password: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Show change password dialog
  void showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    final showCurrentPassword = false.obs;
    final showNewPassword = false.obs;
    final showConfirmPassword = false.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ubah Password',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        currentPasswordController.dispose();
                        newPasswordController.dispose();
                        confirmPasswordController.dispose();
                        Get.back();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Obx(
                  () => TextFormField(
                    controller: currentPasswordController,
                    obscureText: !showCurrentPassword.value,
                    decoration: InputDecoration(
                      labelText: 'Password Saat Ini',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showCurrentPassword.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () =>
                                showCurrentPassword.value =
                                    !showCurrentPassword.value,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator:
                        (value) =>
                            value?.isEmpty == true
                                ? 'Password saat ini wajib diisi'
                                : null,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => TextFormField(
                    controller: newPasswordController,
                    obscureText: !showNewPassword.value,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showNewPassword.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () =>
                                showNewPassword.value = !showNewPassword.value,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty == true)
                        return 'Password baru wajib diisi';
                      if (value!.length < 6)
                        return 'Password minimal 6 karakter';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !showConfirmPassword.value,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showConfirmPassword.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () =>
                                showConfirmPassword.value =
                                    !showConfirmPassword.value,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty == true) {
                        return 'Konfirmasi password wajib diisi';
                      }
                      if (value != newPasswordController.text) {
                        return 'Konfirmasi password tidak cocok';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        currentPasswordController.dispose();
                        newPasswordController.dispose();
                        confirmPasswordController.dispose();
                        Get.back();
                      },
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    Obx(
                      () => ElevatedButton(
                        onPressed:
                            isLoading.value
                                ? null
                                : () {
                                  if (dialogFormKey.currentState!.validate()) {
                                    changePassword(
                                      currentPassword:
                                          currentPasswordController.text,
                                      newPassword: newPasswordController.text,
                                      confirmPassword:
                                          confirmPasswordController.text,
                                    );
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            isLoading.value
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  /// Logout
  Future<void> logout() async {
    try {
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text(
            'هل أنت متأكد من تسجيل الخروج؟\nApakah Anda yakin ingin keluar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('خروج', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await _apiService.logout();
      await _storageService.clearAll();

      Get.back(); // Close loading
      _authController.logout();
    } catch (e) {
      Get.back(); // Close loading if still open
      developer.log('Logout error: $e');

      // Force logout even if API fails
      await _storageService.clearAll();
      _authController.logout();
    }
  }

  /// Get user display name
  String get displayName => currentUser.value?.name ?? 'Guru';

  /// Get user email
  String get displayEmail => currentUser.value?.email ?? '';

  /// Get user role
  String get displayRole {
    final role = currentUser.value?.roleDisplay;
    return role ?? 'Guru';
  }

  /// Get NIP - Check both user.nip and employee.nip
  String get displayNIP {
    try {
      // Try user.nip first
      if (currentUser.value?.nip != null &&
          currentUser.value!.nip!.isNotEmpty &&
          currentUser.value!.nip != '-') {
        return currentUser.value!.nip!;
      }

      // Fallback to employee.nip
      final employee = currentUser.value?.employee;
      if (employee?.nip != null && employee!.nip!.isNotEmpty) {
        return employee.nip!;
      }

      return '-';
    } catch (e) {
      developer.log('Error getting NIP: $e');
      return '-';
    }
  }

  /// Get phone number
  String get displayPhone {
    try {
      final phone = currentUser.value?.phoneNumber;
      if (phone != null && phone.isNotEmpty) {
        return phone;
      }
      return '-';
    } catch (e) {
      developer.log('Error getting phone: $e');
      return '-';
    }
  }

  /// Get Address from employee data
  String get displayAddress {
    try {
      final employee = currentUser.value?.employee;
      if (employee == null) return '-';

      List<String> addressParts = [];

      if (employee.alamatJalan != null && employee.alamatJalan!.isNotEmpty) {
        addressParts.add(employee.alamatJalan!);
      }
      if (employee.rt != null && employee.rt!.isNotEmpty) {
        addressParts.add('RT ${employee.rt}');
      }
      if (employee.rw != null && employee.rw!.isNotEmpty) {
        addressParts.add('RW ${employee.rw}');
      }
      if (employee.desaKelurahan != null &&
          employee.desaKelurahan!.isNotEmpty) {
        addressParts.add(employee.desaKelurahan!);
      }
      if (employee.kecamatan != null && employee.kecamatan!.isNotEmpty) {
        addressParts.add(employee.kecamatan!);
      }

      return addressParts.isNotEmpty ? addressParts.join(', ') : '-';
    } catch (e) {
      developer.log('Error building address: $e');
      return '-';
    }
  }

  /// Navigate to about
  void goToAbout() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.school, color: Colors.green[700]),
            const SizedBox(width: 12),
            const Text('My NCH'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Aplikasi Guru',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('Versi: 1.0.0'),
            Text('Build: 2025.01.01'),
            SizedBox(height: 12),
            Text(
              'جزاك الله خيرا',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Amiri',
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Semoga aplikasi ini bermanfaat',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
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
