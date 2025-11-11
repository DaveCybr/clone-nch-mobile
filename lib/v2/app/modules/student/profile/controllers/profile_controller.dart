// lib/v2/app/modules/student/profile/controllers/profile_controller.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/storage_service.dart';
import '../../../auth/controllers/auth_controller.dart';

class StudentProfileController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  final AuthController _authController = Get.find<AuthController>();

  // State
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Data
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final className = ''.obs; // ✅ Store class name separately

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
          final profileData = await _apiService.getCurrentUser();
          currentUser.value = profileData;
          _authController.user.value = profileData;
          await _storageService.saveUser(profileData);

          // 🔥 Load class name if student has kelas_id
          await _loadClassName();

          developer.log('=== USER PROFILE DATA ===');
          developer.log('User: ${profileData.toJson()}');
          developer.log('Student Data: ${profileData.student}');
        } catch (e) {
          developer.log('Failed to fetch fresh profile data: $e');
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

  /// 🔥 Load class name from kelas_id
  Future<void> _loadClassName() async {
    try {
      final student = currentUser.value?.student;
      if (student == null) {
        developer.log('⚠️ Student data is null');
        className.value = '-';
        return;
      }

      String? kelasId;

      // Get kelas_id from student data
      try {
        final json = (student as dynamic).toJson();
        kelasId = json['kelas_id']?.toString();
        developer.log('🔍 Student JSON: $json');
        developer.log('🔍 kelas_id from JSON: $kelasId');
      } catch (e) {
        developer.log('⚠️ Cannot get kelas_id from student: $e');
        className.value = '-';
        return;
      }

      if (kelasId == null || kelasId.isEmpty) {
        developer.log('⚠️ kelas_id is null or empty');
        className.value = '-';
        return;
      }

      developer.log('🔍 Fetching class name for kelas_id: $kelasId');

      // 🔥 Call API to get class data
      final response = await _apiService.dio.get('/kelas/$kelasId');

      developer.log('✅ Class API Response: ${response.data}');

      // Parse response - try multiple possible keys
      Map<String, dynamic>? classData;

      if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;

        // Try different response structures
        if (responseMap['results'] != null) {
          classData = responseMap['results'] as Map<String, dynamic>?;
          developer.log('📦 Found data in "results" key');
        } else if (responseMap['data'] != null) {
          classData = responseMap['data'] as Map<String, dynamic>?;
          developer.log('📦 Found data in "data" key');
        } else {
          classData = responseMap;
          developer.log('📦 Using direct response');
        }
      }

      if (classData != null) {
        className.value =
            classData['name']?.toString() ??
            classData['nama']?.toString() ??
            classData['class_name']?.toString() ??
            classData['code']?.toString() ?? // Fallback to code
            '-';
        developer.log('✅ Class name loaded: ${className.value}');
      } else {
        className.value = '-';
        developer.log('⚠️ Could not parse class data');
      }
    } catch (e) {
      developer.log('❌ Error loading class name: $e');
      className.value = '-';
      // Don't show error to user, just set default value
    }
  }

  /// Refresh profile
  Future<void> refreshProfile() async {
    await loadProfile();
  }

  /// Helper: Get NIS from student model
  String _getStudentNis(dynamic student) {
    try {
      if (student == null) return '-';

      try {
        final json = (student as dynamic).toJson();
        return json['nisn']?.toString() ??
            json['nis']?.toString() ??
            json['student_id']?.toString() ??
            '-';
      } catch (e) {
        developer.log('⚠️ Cannot convert student to JSON: $e');
        return '-';
      }
    } catch (e) {
      developer.log('❌ Error getting NIS: $e');
      return '-';
    }
  }

  /// Helper: Build address from student data
  String _buildAddress(dynamic student) {
    try {
      if (student == null) return '-';

      List<String> addressParts = [];

      try {
        final json = (student as dynamic).toJson();

        // Check all possible address fields
        final addressFields = ['alamat_jalan', 'alamat', 'address', 'jalan'];

        for (var field in addressFields) {
          if (json[field] != null && json[field].toString().isNotEmpty) {
            addressParts.add(json[field].toString());
            break;
          }
        }

        if (json['rt'] != null) addressParts.add('RT ${json['rt']}');
        if (json['rw'] != null) addressParts.add('RW ${json['rw']}');
        if (json['dusun'] != null) addressParts.add(json['dusun'].toString());
        if (json['kelurahan'] != null) {
          addressParts.add(json['kelurahan'].toString());
        }
        if (json['kecamatan'] != null) {
          addressParts.add(json['kecamatan'].toString());
        }
        if (json['kabupaten'] != null) {
          addressParts.add(json['kabupaten'].toString());
        }
      } catch (e) {
        developer.log('Cannot convert to JSON for address: $e');
      }

      return addressParts.isNotEmpty ? addressParts.join(', ') : '-';
    } catch (e) {
      developer.log('❌ Error building address: $e');
      return '-';
    }
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
  String get displayName => currentUser.value?.name ?? 'Santri';

  /// Get user email
  String get displayEmail => currentUser.value?.email ?? '';

  /// Get user role
  String get displayRole {
    final role = currentUser.value?.roleDisplay;
    return role ?? 'Santri';
  }

  /// Get NIS - Fixed to use NISN
  String get displayNIS {
    final student = currentUser.value?.student;
    if (student == null) return '-';
    return _getStudentNis(student);
  }

  /// Get Class - Use className observable
  String get displayClass {
    return className.value.isEmpty ? '-' : className.value;
  }

  /// Get Address
  String get displayAddress {
    final student = currentUser.value?.student;
    if (student == null) return '-';
    return _buildAddress(student);
  }

  /// Get phone number
  String get displayPhone => currentUser.value?.phoneNumber ?? '-';

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
              'Aplikasi Santri',
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
