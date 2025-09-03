import 'package:flutter/material.dart';
import 'package:nch_mobile/features/login/models/auth_model.dart';
import 'package:nch_mobile/features/login/services/auth_service.dart';
import 'package:nch_mobile/features/guru/dashboard/screens/dashboard_screen.dart';
import 'package:nch_mobile/features/siswa/dashboard/screens/dashboard_screen.dart';
import 'package:nch_mobile/features/login/screens/login_screen.dart';

class AuthController {
  final LoginService _loginService = LoginService.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog(context, 'Email dan password tidak boleh kosong');
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('🔐 Starting login process...');
      // Login menggunakan endpoint utama
      final result = await _loginService.login(email, password);

      // Hide loading indicator
      Navigator.of(context).pop();

      if (result['success']) {
        print('🔍 Login result success, processing user data...');

        // Ambil data user mentah dari response untuk role checking
        final userData = result['user']; // UserModel object
        final userRaw = result['userRaw']; // Raw JSON data

        print('👤 Checking user role from response data...');
        print('👤 UserModel type: ${userData.runtimeType}');
        print('👤 Raw user data type: ${userRaw.runtimeType}');

        if (userRaw != null) {
          print('👤 User data keys: ${userRaw.keys}');
          print('👤 Student data: ${userRaw['student']}');
          print('👤 Employee data: ${userRaw['employee']}');
        } else {
          print('❌ userRaw is null!');
          _showErrorDialog(context, 'Data user tidak lengkap');
          return;
        }

        try {
          print('🚀 Starting navigation logic...');

          // Cek apakah user adalah student (memiliki student object)
          if (userRaw != null && userRaw['student'] != null) {
            print('🎓 User is a student, redirecting to student dashboard');
            // Navigate to student dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreenSiswa(),
              ),
            );
            print('🎓 Navigation to student dashboard completed');
            return;
          }

          // Cek apakah user adalah teacher (memiliki employee object)
          if (userRaw != null && userRaw['employee'] != null) {
            print('👨‍🏫 User is a teacher, redirecting to teacher dashboard');
            // Navigate to teacher dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreenGuru(),
              ),
            );
            print('👨‍🏫 Navigation to teacher dashboard completed');
            return;
          }

          // Default fallback ke teacher dashboard jika tidak ada role yang terdeteksi
          print('❓ Role not detected, defaulting to teacher dashboard');
          print('❓ Available user data: ${userRaw?.toString()}');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardScreenGuru(),
            ),
          );
          print('❓ Default navigation completed');
        } catch (navigationError, stackTrace) {
          print('❌ Error during navigation: $navigationError');
          print('❌ Stack trace: $stackTrace');
          _showErrorDialog(
            context,
            'Terjadi kesalahan saat membuka dashboard: ${navigationError.toString()}',
          );
        }
      } else {
        _showErrorDialog(context, result['message'] ?? 'Login gagal');
      }
    } catch (e, stackTrace) {
      print('❌ Main login error: $e');
      print('❌ Main error stack trace: $stackTrace');

      // Hide loading indicator if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      String errorMessage = 'Terjadi kesalahan saat login';

      if (e.toString().contains('401')) {
        errorMessage = 'Email atau password salah';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Akses ditolak. Periksa kredensial Anda.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Koneksi timeout. Periksa koneksi internet Anda.';
      }

      _showErrorDialog(context, errorMessage);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Login Gagal'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<UserModel?> fetchUserProfile() async {
    return await _loginService.fetchUserProfile();
  }

  Future<void> logout(BuildContext context) async {
    try {
      final success = await _loginService.logout();

      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        // Even if logout failed on server, redirect to login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Force logout locally
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
