// lib/v2/app/modules/auth/views/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nch_mobile/v2/app/data/services/navigations_services.dart';
import 'dart:developer' as developer;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Loading state dengan pesan status
  final RxString _statusMessage = 'جَزَاكَ اللهُ خَيْرًا'.obs;

  @override
  void initState() {
    super.initState();
    developer.log('AuthWrapper: initState called');
    _setupAnimations();
    _checkAuthAndNavigate();
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
    developer.log('AuthWrapper: Animations setup complete');
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      developer.log('');
      developer.log('╔═══════════════════════════════════════════╗');
      developer.log('║       🔐 AUTH WRAPPER STARTED            ║');
      developer.log('╚═══════════════════════════════════════════╝');

      // Wait for animation to start
      await Future.delayed(const Duration(milliseconds: 500));

      _statusMessage.value = 'Memeriksa autentikasi...';

      // Get atau buat AuthController
      final authController = Get.put(AuthController());
      developer.log('AuthWrapper: AuthController initialized');

      // Check auth status
      final isAuthenticated = await authController.checkAuthStatus();
      developer.log('AuthWrapper: Auth check result: $isAuthenticated');

      // Wait for minimum splash duration
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (isAuthenticated && authController.user.value != null) {
        final user = authController.user.value!;
        developer.log('✅ User authenticated');
        developer.log('   User: ${user.name}');
        developer.log('   Role: ${user.currentRole}');

        _statusMessage.value = 'Mengalihkan...';

        // Get target route berdasarkan role
        final targetRoute = Routes.getDefaultRouteByRole(
          user.currentRole ?? '',
        );

        developer.log('🎯 Target route: $targetRoute');

        // Navigate dengan clear stack
        await NavigationService.to.fromSplash(targetRoute);
      } else {
        developer.log('❌ User not authenticated, redirecting to login');
        _statusMessage.value = 'Menuju halaman login...';

        // Navigate to login dengan clear stack
        await NavigationService.to.fromSplash(Routes.LOGIN);
      }

      developer.log('');
      developer.log('╔═══════════════════════════════════════════╗');
      developer.log('║    ✅ AUTH WRAPPER COMPLETED             ║');
      developer.log('╚═══════════════════════════════════════════╝');
      developer.log('');

      NavigationService.to.printState();
    } catch (e, stackTrace) {
      developer.log('');
      developer.log('╔═══════════════════════════════════════════╗');
      developer.log('║       ❌ AUTH WRAPPER ERROR              ║');
      developer.log('╚═══════════════════════════════════════════╝');
      developer.log('Error: $e');
      developer.log('Stack: $stackTrace');

      _statusMessage.value = 'Error: $e';

      // Jika error, redirect ke login dengan clear stack
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        await NavigationService.to.fromSplash(Routes.LOGIN);
      }
    }
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

                          // Status message
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
