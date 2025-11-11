import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer show log;

import '../../../routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      developer.log('');
      developer.log('╔═══════════════════════════════════════════╗');
      developer.log('║       🔐 AUTH WRAPPER STARTED            ║');
      developer.log('╚═══════════════════════════════════════════╝');

      // Delay kecil untuk splash effect
      await Future.delayed(const Duration(milliseconds: 800));

      // Get atau buat AuthController
      final authController = Get.put(AuthController());

      developer.log('📱 Checking authentication status...');

      // Check auth status menggunakan AuthController
      final isAuthenticated = await authController.checkAuthStatus();

      developer.log('✅ Auth check completed: $isAuthenticated');

      if (!mounted) return;

      setState(() {
        _isChecking = false;
      });

      // Navigate berdasarkan hasil auth check
      if (isAuthenticated && authController.user.value != null) {
        developer.log('✅ User authenticated, redirecting based on role...');
        developer.log('   User: ${authController.user.value?.name}');
        developer.log('   Role: ${authController.user.value?.currentRole}');

        // Redirect berdasarkan role
        authController.redirectBasedOnRole();
      } else {
        developer.log('❌ User not authenticated, redirecting to login');
        Get.offAllNamed(Routes.LOGIN);
      }

      developer.log('');
      developer.log('╔═══════════════════════════════════════════╗');
      developer.log('║    ✅ AUTH WRAPPER COMPLETED             ║');
      developer.log('╚═══════════════════════════════════════════╝');
      developer.log('');
    } catch (e, stackTrace) {
      developer.log('');
      developer.log('╔═══════════════════════════════════════════╗');
      developer.log('║       ❌ AUTH WRAPPER ERROR              ║');
      developer.log('╚═══════════════════════════════════════════╝');
      developer.log('Error: $e');
      developer.log('Stack: $stackTrace');

      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }

      // Jika error, redirect ke login
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo atau Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mosque,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 32),

            // App Name
            Text(
              'My NCH',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيم',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),

            // Loading Indicator
            if (_isChecking)
              Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'جَارٍ التَّحْمِيل...',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Memuat...',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
