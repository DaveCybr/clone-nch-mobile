import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nch_mobile/v2/app/routes/app_routes.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../auth/controllers/auth_controller.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // ✅ Add loading state
  final RxString _statusMessage = 'جَزَاكَ اللهُ خَيْرًا'.obs;

  @override
  void initState() {
    super.initState();
    developer.log('SplashView: initState called');
    _setupAnimations();
    _initializeAppAndCheckAuth();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    developer.log('SplashView: Animations setup complete');
  }

  void _initializeAppAndCheckAuth() async {
    developer.log('SplashView: Starting initialization');

    // Wait for animation to start
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      _statusMessage.value = 'Memeriksa autentikasi...';

      // Get auth controller - should be available via InitialBinding
      final authController = Get.find<AuthController>();
      developer.log('SplashView: AuthController found');

      // Use the new checkAuthStatus method
      final isAuthenticated = await authController.checkAuthStatus();

      developer.log('SplashView: Auth check result: $isAuthenticated');

      // Wait for minimum splash duration
      await Future.delayed(const Duration(seconds: 2));

      if (isAuthenticated) {
        developer.log('SplashView: User is authenticated, redirecting...');
        _statusMessage.value = 'Mengalihkan...';
        _redirectBasedOnRole(authController);
      } else {
        developer.log('SplashView: User not authenticated, going to login');
        _statusMessage.value = 'Menuju halaman login...';
        Get.rootDelegate.offNamed(Routes.LOGIN);
      }
    } catch (e) {
      developer.log('SplashView: Error during initialization: $e');
      _statusMessage.value = 'Error: $e';
      // If any error occurs during auth check, go to login
      await Future.delayed(const Duration(seconds: 1));
      Get.rootDelegate.offNamed(Routes.LOGIN);
    }
  }

  void _redirectBasedOnRole(AuthController authController) {
    final user = authController.user.value;
    if (user == null) {
      developer.log('SplashView: No user data, going to login');
      Get.rootDelegate.offNamed(Routes.LOGIN);
      return;
    }

    developer.log('=== SPLASH REDIRECT INFO ===');
    developer.log('User: ${user.name}');
    developer.log('Email: ${user.email}');
    developer.log('Current Role: ${user.currentRole}');
    developer.log('Roles: ${user.roleNames}');
    developer.log('===========================');

    // Gunakan method yang sudah ada di AuthController
    authController.redirectBasedOnRole();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: 120.w,
                            height: 120.h,
                            decoration: BoxDecoration(
                              color: AppColors.goldAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.school,
                              size: 60.sp,
                              color: AppColors.primaryGreen,
                            ),
                          ),

                          SizedBox(height: 30.h),

                          // Bismillah
                          Text(
                            'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
                            style: AppTextStyles.arabicText.copyWith(
                              color: Colors.white,
                              fontSize: 18.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 20.h),

                          // App Name
                          Text(
                            'My NCH',
                            style: AppTextStyles.heading1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            'Teacher Portal',
                            style: AppTextStyles.heading3.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),

                          SizedBox(height: 10.h),

                          Text(
                            'Portal Ustadz/Ustadzah Pesantren',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 40.h),

                          // Loading indicator
                          SizedBox(
                            width: 40.w,
                            height: 40.h,
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.goldAccent,
                              ),
                              strokeWidth: 3,
                            ),
                          ),

                          SizedBox(height: 20.h),

                          // ✅ FIXED: Status message - Simple Obx without try-catch
                          Obx(
                            () => Text(
                              _statusMessage.value,
                              style: AppTextStyles.arabicSubtitle.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
