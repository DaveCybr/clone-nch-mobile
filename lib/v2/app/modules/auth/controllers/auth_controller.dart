// lib/v2/app/modules/auth/controllers/auth_controller.dart
import 'dart:developer' as developer show log;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/firebase_service.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  FirebaseService get _firebaseService => Get.find<FirebaseService>();

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
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Check if user is already logged in
  Future<bool> checkAuthStatus() async {
    try {
      isLoading.value = true;

      if (_storageService.hasValidToken) {
        final savedUser = _storageService.getUser();
        if (savedUser != null) {
          user.value = savedUser;
          isLoggedIn.value = true;

          try {
            final freshUser = await _apiService.getCurrentUser();
            user.value = freshUser;
            await _storageService.saveUser(freshUser);

            developer.log('Auto-login successful for user: ${freshUser.name}');

            // Setup notifications in background
            _setupNotificationsInBackground(freshUser);

            return true;
          } catch (e) {
            developer.log('Token validation failed: $e');
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

  /// ✅ LOGIN FUNCTION - SIMPLIFIED VERSION
  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      developer.log('');
      developer.log('╔═══════════════════════════════════════════╗');
      developer.log('║        🚀 LOGIN PROCESS STARTED          ║');
      developer.log('╚═══════════════════════════════════════════╝');

      final response = await _apiService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      developer.log('📥 Login response received');
      developer.log('  ✓ Success: ${response.success}');
      developer.log('  ✓ Has token: ${response.token != null}');
      developer.log('  ✓ Has user: ${response.user != null}');

      if (response.success && response.token != null && response.user != null) {
        developer.log('');
        developer.log('╔═══════════════════════════════════════════╗');
        developer.log('║     💾 SAVING AUTHENTICATION DATA        ║');
        developer.log('╚═══════════════════════════════════════════╝');

        // Save authentication data
        await _storageService.saveToken(response.token!);
        await _storageService.saveUser(response.user!);
        await _storageService.saveLastLogin();

        if (rememberMe.value) {
          await _storageService.setRememberMe(true);
        }

        developer.log('✅ Auth data saved successfully');

        // Update observables
        user.value = response.user;
        isLoggedIn.value = true;

        // ✅ CRITICAL: Send FCM token (sync, must complete)
        developer.log('');
        developer.log('╔═══════════════════════════════════════════╗');
        developer.log('║       📱 SENDING FCM TOKEN               ║');
        developer.log('╚═══════════════════════════════════════════╝');

        try {
          await _sendFCMToken();
          developer.log('✅ FCM token sent');
        } catch (e) {
          developer.log('⚠️ FCM token send failed (will retry): $e');
        }

        developer.log('');
        developer.log('╔═══════════════════════════════════════════╗');
        developer.log('║     ✅ LOGIN COMPLETED SUCCESSFULLY      ║');
        developer.log('╚═══════════════════════════════════════════╝');
        developer.log('');

        // Clear form
        _clearForm();

        // Show success message
        _showIslamicWelcomeMessage();

        // Redirect based on role
        redirectBasedOnRole();

        // ✅ CRITICAL FIX: Setup notifications AFTER navigation
        // This ensures the async operation doesn't get interrupted
        developer.log('');
        developer.log('╔═══════════════════════════════════════════╗');
        developer.log('║  🔔 SETTING UP NOTIFICATIONS (ASYNC)     ║');
        developer.log('╚═══════════════════════════════════════════╝');

        // Run in background without blocking
        _setupNotificationsInBackground(response.user!);
      } else {
        final errorMessage =
            response.message.isNotEmpty ? response.message : 'Login gagal';
        developer.log('❌ Login failed: $errorMessage');
        _showErrorSnackbar('Login Gagal', errorMessage);
      }
    } catch (e, stackTrace) {
      developer.log('');
      developer.log('╔═══════════════════════════════════════════╗');
      developer.log('║          ❌ LOGIN ERROR                   ║');
      developer.log('╚═══════════════════════════════════════════╝');
      developer.log('Error: $e');
      developer.log('Stack: $stackTrace');

      final errorMessage =
          e.toString().isNotEmpty
              ? e.toString()
              : 'Terjadi kesalahan tidak terduga';
      _showErrorSnackbar('خطأ في تسجيل الدخول', errorMessage);
    } finally {
      developer.log('🔚 Finally block - setting isLoading to false');
      isLoading.value = false;
      developer.log('✅ isLoading = false');
    }
  }

  /// ✅ NEW: Setup notifications in background (won't block UI)
  void _setupNotificationsInBackground(UserModel currentUser) {
    // Use Future.microtask to ensure this runs AFTER current frame
    Future.microtask(() async {
      developer.log('');
      developer.log('╔═══════════════════════════════════════════╗');
      developer.log('║  🔔 BACKGROUND NOTIFICATION SETUP START  ║');
      developer.log('╠═══════════════════════════════════════════╣');
      developer.log('║ User: ${currentUser.name}');
      developer.log('║ Role: ${currentUser.currentRole}');

      try {
        // Delay to ensure navigation is complete
        await Future.delayed(const Duration(milliseconds: 500));

        developer.log('║ 🚀 Starting subscription...');

        // Determine role
        String role = 'student';
        if (currentUser.isTeacher) {
          role = 'teacher';
        } else if (currentUser.isStudent || currentUser.student != null) {
          role = 'student';
        } else if (currentUser.isParent) {
          role = 'parent';
        }

        developer.log('║ 🎯 Subscribing as: $role');

        // Subscribe to topics
        await _firebaseService.subscribeToDefaultTopics(role);

        developer.log('║ ✅ Subscription completed successfully');
        developer.log('╚═══════════════════════════════════════════╝');
        developer.log('');
      } catch (e, stack) {
        developer.log('║ ❌ Background subscription failed: $e');
        developer.log('║ Stack: $stack');
        developer.log('╚═══════════════════════════════════════════╝');
        developer.log('');

        // Retry once after 2 seconds
        developer.log('🔄 Retrying subscription in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));

        try {
          String role = currentUser.isTeacher ? 'teacher' : 'student';
          await _firebaseService.subscribeToDefaultTopics(role);
          developer.log('✅ Retry successful!');
        } catch (retryError) {
          developer.log('❌ Retry failed: $retryError');
        }
      }
    });
  }

  /// ✅ Send FCM token to server
  Future<void> _sendFCMToken() async {
    try {
      developer.log('🔔 _sendFCMToken() called');

      final token = await _firebaseService.getToken();
      developer.log('🔑 Got token: ${token?.substring(0, 20)}...');

      if (token != null) {
        final success = await _firebaseService.sendTokenToServer(token);

        if (success) {
          developer.log('✅ FCM token sent to server');
        } else {
          developer.log('⚠️ Failed to send FCM token');
        }
      } else {
        developer.log('⚠️ FCM token is null');
      }
    } catch (e, stack) {
      developer.log('❌ Error in _sendFCMToken: $e');
      developer.log('Stack: $stack');
      rethrow; // Re-throw to let caller handle
    }
  }

  /// Logout function
  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Unsubscribe from topics
      if (user.value != null) {
        await _unsubscribeFromTopics(user.value!);
      }

      // Delete FCM token
      await _firebaseService.deleteToken();
      developer.log('✅ FCM token deleted on logout');

      // Call logout API
      await _apiService.logout();

      // Clear all local data
      await _clearAuthData();

      _showSuccessSnackbar(
        'وداعاً',
        'جزاك الله خيراً - Semoga Allah membalas kebaikan Anda',
      );

      Get.rootDelegate.offNamed(Routes.LOGIN);
    } catch (e) {
      developer.log('Logout error: $e');
      await _clearAuthData();
      Get.rootDelegate.offNamed(Routes.LOGIN);
    } finally {
      isLoading.value = false;
    }
  }

  /// Unsubscribe from topics
  Future<void> _unsubscribeFromTopics(UserModel currentUser) async {
    try {
      developer.log('🔕 Unsubscribing from notification topics...');

      String role = 'student';
      if (currentUser.isTeacher) {
        role = 'teacher';
      } else if (currentUser.isStudent || currentUser.student != null) {
        role = 'student';
      } else if (currentUser.isParent) {
        role = 'parent';
      }

      await _firebaseService.unsubscribeFromAllTopics(role);

      developer.log('✅ Successfully unsubscribed from all topics');
    } catch (e) {
      developer.log('❌ Error unsubscribing from topics: $e');
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

  /// Redirect user based on role
  void redirectBasedOnRole() {
    final currentUser = user.value;
    if (currentUser == null) {
      Get.rootDelegate.offNamed(Routes.LOGIN);
      return;
    }

    developer.log('=== REDIRECT DEBUG ===');
    developer.log('User: ${currentUser.name}');
    developer.log('Email: ${currentUser.email}');
    developer.log('Is Teacher: ${currentUser.isTeacher}');
    developer.log('Is Security: ${currentUser.isSecurity}');
    developer.log('Is Student: ${currentUser.isStudent}');
    developer.log('Is Parent: ${currentUser.isParent}');
    developer.log('Current Role: ${currentUser.currentRole}');
    developer.log('Roles: ${currentUser.roleNames}');
    developer.log('Has Employee: ${currentUser.employee != null}');
    developer.log('Employee Position: ${currentUser.employee?.position}');
    developer.log('Has Student Data: ${currentUser.student != null}');
    developer.log('=====================');

    // Priority: Teacher > Security > Student > Parent

    // 1. Jika user punya role teacher, arahkan ke teacher dashboard
    if (currentUser.isTeacher) {
      developer.log('  → TEACHER dashboard');
      Get.rootDelegate.offNamed(Routes.MAIN);
    }
    // 2. Jika user punya role security, arahkan ke security dashboard
    else if (currentUser.isSecurity) {
      developer.log('✅ Redirecting to SECURITY dashboard');
      Get.rootDelegate.offNamed(Routes.SECURITY);
    }
    // 3. Jika user punya student data (santri yang login sendiri)
    else if (currentUser.student != null || currentUser.isStudent) {
      developer.log('✅ Redirecting to STUDENT dashboard');
      Get.rootDelegate.offNamed(Routes.STUDENT);
    }
    // 4. Jika user adalah parent
    else if (currentUser.isParent) {
      developer.log('✅ Redirecting to PARENT dashboard');
      Get.rootDelegate.offNamed(Routes.PARENT);
    }
    // 5. Jika tidak ada role yang dikenali
    else {
      developer.log('❌ Unknown role, redirecting to login');
      _showErrorSnackbar(
        'Error',
        'Role tidak dikenali. Hubungi administrator.',
      );
      Get.rootDelegate.offNamed(Routes.LOGIN);
    }
  }

  /// Show Islamic welcome message
  void _showIslamicWelcomeMessage() {
    final hour = DateTime.now().hour;
    String greeting = '';

    if (hour < 5) {
      greeting = 'لَيْلَة سَعِيدَة';
    } else if (hour < 11) {
      greeting = 'صَبَاح الْخَيْر';
    } else if (hour < 15) {
      greeting = 'ظُهْر سَعِيد';
    } else if (hour < 19) {
      greeting = 'عَصْر سَعِيد';
    } else {
      greeting = 'مَسَاء الْخَيْر';
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
    Get.snackbar(
      title,
      message,
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

  /// Get current user from server
  Future<void> getCurrentUser() async {
    try {
      final freshUser = await _apiService.getCurrentUser();
      user.value = freshUser;
      await _storageService.saveUser(freshUser);
      isLoggedIn.value = true;
    } catch (e) {
      developer.log('Failed to get current user: $e');
      rethrow;
    }
  }

  /// Check if session is still valid
  Future<bool> isSessionValid() async {
    try {
      if (!_storageService.hasValidToken) return false;
      await getCurrentUser();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Auto-login with saved credentials
  Future<bool> tryAutoLogin() async {
    try {
      if (!rememberMe.value) return false;
      return await checkAuthStatus();
    } catch (e) {
      developer.log('Auto-login failed: $e');
      return false;
    }
  }

  /// Refresh FCM token
  Future<void> refreshFCMToken() async {
    try {
      developer.log('🔄 Refreshing FCM token...');
      await _firebaseService.refreshAndSendToken();
      developer.log('✅ FCM token refreshed successfully');
    } catch (e) {
      developer.log('❌ Error refreshing FCM token: $e');
    }
  }

  /// ✅ NEW: Manual subscribe (untuk button test atau retry)
  Future<void> manualSubscribe() async {
    try {
      final currentUser = user.value;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      developer.log('🔔 Manual subscribe triggered');

      String role = 'student';
      if (currentUser.isTeacher) {
        role = 'teacher';
      } else if (currentUser.isStudent || currentUser.student != null) {
        role = 'student';
      } else if (currentUser.isParent) {
        role = 'parent';
      }

      await _firebaseService.subscribeToDefaultTopics(role);

      Get.snackbar(
        'Success',
        'Berhasil subscribe ke notifikasi $role',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      developer.log('❌ Manual subscribe failed: $e');
      Get.snackbar(
        'Error',
        'Gagal subscribe: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
