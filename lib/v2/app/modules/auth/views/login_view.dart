import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../../../data/widgets/developer_settings_dialog.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
                SizedBox(height: 40.h),

                // Islamic Header
                // _buildIslamicHeader(),
                SizedBox(height: 40.h),

                // Login Form with Easter Egg
                _LoginFormWithEasterEgg(controller: controller),

                SizedBox(height: 24.h),

                // Islamic Footer
                _buildIslamicFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIslamicHeader() {
    return Column(
      children: [
        // Logo with Islamic design
        Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: const BoxDecoration(
              color: AppColors.goldAccent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 40.sp,
              color: AppColors.primaryGreen,
            ),
          ),
        ),

        SizedBox(height: 20.h),

        // Bismillah
        Text(
          'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
          style: AppTextStyles.arabicText.copyWith(fontSize: 20.sp),
        ),

        SizedBox(height: 12.h),

        // App Name
        Text(
          'My NCH',
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          'Teacher Portal',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        SizedBox(height: 8.h),

        Text(
          'Portal Ustadz/Ustadzah Pesantren',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildIslamicFooter() {
    return Column(
      children: [
        Text(
          'وَفِي اللّٰهِ فَلْيَتَوَكَّلِ الْمُؤْمِنُوْنَ',
          style: AppTextStyles.arabicSubtitle.copyWith(fontSize: 14.sp),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 8.h),

        Text(
          'Dan kepada Allah lah hendaknya orang-orang mukmin bertawakal',
          style: AppTextStyles.bodySmall.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 20.h),

        Text(
          '© 2025 My NCH. All rights reserved.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Stateful widget untuk handle easter egg
class _LoginFormWithEasterEgg extends StatefulWidget {
  final AuthController controller;

  const _LoginFormWithEasterEgg({required this.controller});

  @override
  State<_LoginFormWithEasterEgg> createState() =>
      _LoginFormWithEasterEggState();
}

class _LoginFormWithEasterEggState extends State<_LoginFormWithEasterEgg> {
  // Easter egg variables
  int _tapCount = 0;
  Timer? _resetTimer;

  // Password visibility toggle
  bool _isPasswordVisible = false;

  void _handleEasterEgg() {
    _tapCount++;

    // Reset counter setelah 2 detik tidak ada tap
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _tapCount = 0;
      });
    });

    // Jika tap 5 kali, buka developer settings
    if (_tapCount >= 5) {
      setState(() {
        _tapCount = 0;
      });
      _resetTimer?.cancel();

      // Tampilkan feedback
      Get.snackbar(
        '🔓 Developer Mode',
        'Developer settings unlocked!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primaryGreen,
        colorText: Colors.white,
        duration: const Duration(milliseconds: 800),
        margin: EdgeInsets.all(16.w),
      );

      // Delay sedikit untuk efek
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.dialog(const DeveloperSettingsDialog(), barrierDismissible: true);
      });
    } else if (_tapCount >= 3) {
      // Hint setelah 3x tap
      Get.snackbar(
        '',
        '${5 - _tapCount} more taps...',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade400,
        colorText: Colors.white,
        duration: const Duration(milliseconds: 500),
        margin: EdgeInsets.only(top: 10.h, left: 20.w, right: 20.w),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Title with Easter Egg
          Center(
            child: Column(
              children: [
                // Text(
                //   'أَهْلاً وَسَهْلاً',
                //   style: AppTextStyles.arabicText.copyWith(fontSize: 18.sp),
                // ),
                SizedBox(height: 4.h),
                GestureDetector(
                  onTap: _handleEasterEgg,
                  child: Text('Selamat Datang', style: AppTextStyles.heading2),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Email Field
          Text(
            'Email',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: widget.controller.emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Email tidak boleh kosong';
              }
              if (!GetUtils.isEmail(value!)) {
                return 'Format email tidak valid';
              }
              return null;
            },
            decoration: const InputDecoration(
              hintText: 'Masukkan email Anda',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppColors.primaryGreen,
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Password Field
          Text(
            'Password',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: widget.controller.passwordController,
            obscureText: !_isPasswordVisible,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Password tidak boleh kosong';
              }
              if (value!.length < 6) {
                return 'Password minimal 6 karakter';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Masukkan password Anda',
              prefixIcon: const Icon(
                Icons.lock_outlined,
                color: AppColors.primaryGreen,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.primaryGreen,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // Login Button
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed:
                    widget.controller.isLoading.value
                        ? null
                        : widget.controller.login,
                child:
                    widget.controller.isLoading.value
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Sedang masuk...',
                              style: AppTextStyles.buttonText,
                            ),
                          ],
                        )
                        : Text('Masuk', style: AppTextStyles.buttonText),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }
}
