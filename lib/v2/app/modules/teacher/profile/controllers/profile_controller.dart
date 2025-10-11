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

  // Observables
  final isLoading = false.obs;
  final isSaving = false.obs;
  final user = Rxn<UserModel>();

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }

  /// Load user profile data
  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;

      // Get current user from auth controller
      user.value = _authController.user.value;

      if (user.value != null) {
        _populateForm();

        // Try to get fresh data from API
        try {
          final profileData = await _apiService.getTeacherProfile();
          user.value = UserModel.fromJson(profileData['user']);
          _populateForm();
        } catch (e) {
          developer.log('Failed to fetch fresh profile data: $e');
          // Continue with cached data
        }
      }
    } catch (e) {
      developer.log('Error loading profile: $e');
      _showErrorSnackbar('Error', 'Gagal memuat profil: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Populate form with user data
  void _populateForm() {
    final currentUser = user.value;
    if (currentUser != null) {
      nameController.text = currentUser.name;
      emailController.text = currentUser.email;
      phoneController.text = currentUser.phoneNumber ?? '';

      // Get address from employee data if available
      if (currentUser.employee?.alamatJalan != null) {
        final address = [
          currentUser.employee?.alamatJalan,
          'RT ${currentUser.employee?.rt}',
          'RW ${currentUser.employee?.rw}',
          currentUser.employee?.desaKelurahan,
          currentUser.employee?.kecamatan,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        addressController.text = address;
      }
    }
  }

  /// Update profile
  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isSaving.value = true;

      final updateData = {
        'name': nameController.text.trim(),
        'phone_number': phoneController.text.trim(),
        // Add other fields as needed
      };

      await _apiService.updateTeacherProfile(updateData);

      // Update local user data
      if (user.value != null) {
        user.value = user.value!.copyWith(
          name: nameController.text.trim(),
          phoneNumber: phoneController.text.trim(),
        );

        // Update auth controller user
        _authController.user.value = user.value;

        // Save to storage
        await _storageService.saveUser(user.value!);
      }

      _showSuccessSnackbar('بَارَكَ اللهُ فِيكَ', 'Profil berhasil diperbarui');

      // Refresh profile data
      await loadUserProfile();
    } catch (e) {
      developer.log('Error updating profile: $e');
      _showErrorSnackbar('Error', 'Gagal memperbarui profil: $e');
    } finally {
      isSaving.value = false;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      _showErrorSnackbar('Error', 'Konfirmasi password tidak cocok');
      return;
    }

    try {
      isSaving.value = true;

      await _apiService.dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
      );

      _showSuccessSnackbar('تبارك الله', 'Password berhasil diubah');

      Get.back(); // Close change password dialog
    } catch (e) {
      developer.log('Error changing password: $e');
      _showErrorSnackbar('Error', 'Gagal mengubah password: $e');
    } finally {
      isSaving.value = false;
    }
  }

  /// Show change password dialog
  void showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ubah Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Current Password
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Saat Ini',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator:
                      (value) =>
                          value?.isEmpty == true
                              ? 'Password saat ini wajib diisi'
                              : null,
                ),

                const SizedBox(height: 16),

                // New Password
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Baru',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'Password baru wajib diisi';
                    }
                    if (value!.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi Password',
                    prefixIcon: Icon(Icons.lock),
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

                const SizedBox(height: 24),

                // Buttons
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
                    const SizedBox(width: 8),
                    Obx(
                      () => ElevatedButton(
                        onPressed:
                            isSaving.value
                                ? null
                                : () {
                                  if (formKey.currentState!.validate()) {
                                    changePassword(
                                      currentPassword:
                                          currentPasswordController.text,
                                      newPassword: newPasswordController.text,
                                      confirmPassword:
                                          confirmPasswordController.text,
                                    );
                                  }
                                },
                        child:
                            isSaving.value
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
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
    );
  }

  /// Logout
  void logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text(
          'هل أنت متأكد من تسجيل الخروج؟\nApakah Anda yakin ingin keluar?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              _authController.logout();
            },
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }
}
