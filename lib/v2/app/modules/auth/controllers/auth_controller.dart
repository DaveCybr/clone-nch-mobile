import 'dart:developer' as developer show log;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  // Observables
  final isLoading = false.obs;
  final user = Rxn<UserModel>();
  final isLoggedIn = false.obs;
  final rememberMe = false.obs;

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _loadRememberMe();
    // Don't auto-check auth here, let SplashView handle it
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Check if user is already logged in (called from SplashView)
  Future<bool> checkAuthStatus() async {
    try {
      isLoading.value = true;

      if (_storageService.hasValidToken) {
        final savedUser = _storageService.getUser();
        if (savedUser != null) {
          user.value = savedUser;
          isLoggedIn.value = true;

          // Try to get fresh user data to validate token
          try {
            final freshUser = await _apiService.getCurrentUser();
            user.value = freshUser;
            await _storageService.saveUser(freshUser);

            developer.log('Auto-login successful for user: ${freshUser.name}');
            return true;
          } catch (e) {
            developer.log('Token validation failed: $e');
            // Token might be expired, clear storage
            await _clearAuthData();
            return false;
          }
        }
      }

      developer.log('No valid auth data found');
      return false;
    } catch (e) {
      developer.log('Auth check failed: $e');
      await _clearAuthData();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load remember me preference
  void _loadRememberMe() {
    rememberMe.value = _storageService.getRememberMe();
  }

  /// Login function
  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      final response = await _apiService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("Raw response body: $response");

      developer.log('Login response success: ${response.success}');
      developer.log('Login response message: ${response.message}');
      developer.log('Login response has token: ${response.token != null}');
      developer.log('Login response has user: ${response.user != null}');

      if (response.success && response.token != null && response.user != null) {
        // Save authentication data
        await _storageService.saveToken(response.token!);
        await _storageService.saveUser(response.user!);
        await _storageService.saveLastLogin();

        if (rememberMe.value) {
          await _storageService.setRememberMe(true);
        }

        // Update observables
        user.value = response.user;
        isLoggedIn.value = true;

        // Show success message with Islamic greeting
        _showIslamicWelcomeMessage();

        // Redirect based on role
        redirectBasedOnRole();

        // Clear form
        _clearForm();
      } else {
        final errorMessage =
            response.message.isNotEmpty ? response.message : 'Login gagal';
        developer.log('Login failed: $errorMessage');
        _showErrorSnackbar('Login Gagal', errorMessage);
      }
    } catch (e, response) {
      print("Raw response body: $response");
      developer.log('Login error: $e');
      final errorMessage =
          e.toString().isNotEmpty
              ? e.toString()
              : 'Terjadi kesalahan tidak terduga';
      _showErrorSnackbar('خطأ في تسجيل الدخول', errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout function
  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Call logout API
      await _apiService.logout();

      // Clear all local data
      await _clearAuthData();

      _showSuccessSnackbar(
        'وداعاً',
        'جزاك الله خيراً - Semoga Allah membalas kebaikan Anda',
      );

      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      developer.log('Logout error: $e');
      // Even if API fails, clear local data
      await _clearAuthData();
      Get.offAllNamed(Routes.LOGIN);
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear all authentication data
  Future<void> _clearAuthData() async {
    await _storageService.clearAll();
    user.value = null;
    isLoggedIn.value = false;
  }

  /// Toggle remember me
  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
    _storageService.setRememberMe(rememberMe.value);
  }

  /// Redirect user based on role (made public for SplashView)
  void redirectBasedOnRole() {
    final currentUser = user.value;
    if (currentUser == null) {
      Get.offAllNamed(Routes.LOGIN);
      return;
    }

    developer.log('=== REDIRECT DEBUG ===');
    developer.log('User: ${currentUser.name}');
    developer.log('Email: ${currentUser.email}');
    developer.log('Is Teacher: ${currentUser.isTeacher}');
    developer.log('Is Parent: ${currentUser.isParent}');
    developer.log('Is Student: ${currentUser.isStudent}');
    developer.log('Current Role: ${currentUser.currentRole}');
    developer.log('Roles: ${currentUser.roleNames}');
    developer.log('Has Employee: ${currentUser.employee != null}');
    developer.log('Has Student Data: ${currentUser.student != null}');
    developer.log('=====================');

    // Priority: Teacher > Student > Parent

    // 1. Jika user punya role teacher, arahkan ke teacher dashboard
    if (currentUser.isTeacher) {
      developer.log('✅ Redirecting to TEACHER dashboard');
      Get.offAllNamed('${Routes.MAIN}');
    }
    // 2. Jika user punya student data (santri yang login sendiri)
    else if (currentUser.student != null || currentUser.isStudent) {
      developer.log('✅ Redirecting to STUDENT dashboard');
      Get.offAllNamed('${Routes.STUDENT}');
    }
    // 3. Jika user adalah parent
    else if (currentUser.isParent) {
      developer.log('✅ Redirecting to PARENT dashboard');
      Get.offAllNamed('${Routes.PARENT}');
    }
    // 4. Jika tidak ada role yang dikenali
    else {
      developer.log('❌ Unknown role, redirecting to login');
      _showErrorSnackbar(
        'Error',
        'Role tidak dikenali. Hubungi administrator.',
      );
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  /// Show Islamic welcome message
  void _showIslamicWelcomeMessage() {
    final hour = DateTime.now().hour;
    String greeting = '';

    if (hour < 5) {
      greeting = 'لَيْلَة سَعِيدَة'; // Good night
    } else if (hour < 11) {
      greeting = 'صَبَاح الْخَيْر'; // Good morning
    } else if (hour < 15) {
      greeting = 'ظُهْر سَعِيد'; // Good afternoon
    } else if (hour < 19) {
      greeting = 'عَصْر سَعِيد'; // Good evening
    } else {
      greeting = 'مَسَاء الْخَيْر'; // Good evening
    }

    final userName = user.value?.name ?? 'User';
    _showSuccessSnackbar(
      'أَهْلاً وَسَهْلاً',
      '$greeting، $userName\nبَارَكَ اللهُ فِيكَ - Semoga Allah memberkahi Anda',
    );
  }

  /// Clear form
  void _clearForm() {
    emailController.clear();
    passwordController.clear();
  }

  /// Show success snackbar
  void _showSuccessSnackbar(String title, String message) {
    final validTitle = title.isEmpty ? 'Success' : title;
    final validMessage =
        message.isEmpty ? 'Operation completed successfully' : message;

    Get.snackbar(
      validTitle,
      validMessage,
      backgroundColor: AppColors.primaryGreen,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show error snackbar
  void _showErrorSnackbar(String title, String message) {
    final validTitle = title.isEmpty ? 'Error' : title;
    final validMessage = message.isEmpty ? 'An error occurred' : message;

    Get.snackbar(
      validTitle,
      validMessage,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }

  /// Get current user from server
  Future<void> getCurrentUser() async {
    try {
      final freshUser = await _apiService.getCurrentUser();
      user.value = freshUser;
      await _storageService.saveUser(freshUser);
      isLoggedIn.value = true;
    } catch (e) {
      developer.log('Failed to get current user: $e');
      rethrow; // Rethrow to let caller handle it
    }
  }

  /// Check if session is still valid
  Future<bool> isSessionValid() async {
    try {
      if (!_storageService.hasValidToken) return false;

      // Try to get current user to validate token
      await getCurrentUser();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Auto-login with saved credentials (optional feature)
  Future<bool> tryAutoLogin() async {
    try {
      if (!rememberMe.value) return false;

      // Check if we have valid token and user data
      return await checkAuthStatus();
    } catch (e) {
      developer.log('Auto-login failed: $e');
      return false;
    }
  }
}
