import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateAfterDelay();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  void _navigateAfterDelay() {
    Future.delayed(Duration(seconds: 3), () {
      // Check authentication status will be handled by AuthController
      if (Get.find<AuthController>().isLoggedIn.value) {
        // Get.find<AuthController>()._redirectBasedOnRole();
      } else {
        Get.offAllNamed('/login');
      }
    });
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
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
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
                            offset: Offset(0, 8),
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
                    ),

                    SizedBox(height: 20.h),

                    // App Name
                    Text(
                      'JTI NCH',
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
                    ),

                    SizedBox(height: 40.h),

                    // Loading indicator
                    SizedBox(
                      width: 40.w,
                      height: 40.h,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.goldAccent,
                        ),
                        strokeWidth: 3,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    Text(
                      'جَزَاكَ اللهُ خَيْرًا',
                      style: AppTextStyles.arabicSubtitle.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
