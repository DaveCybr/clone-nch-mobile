import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';

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

                // Login Form
                _buildLoginForm(),

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
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
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
          'JTI NCH',
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

  Widget _buildLoginForm() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Title
          Center(
            child: Column(
              children: [
                // Text(
                //   'أَهْلاً وَسَهْلاً',
                //   style: AppTextStyles.arabicText.copyWith(fontSize: 18.sp),
                // ),
                SizedBox(height: 4.h),
                Text('Selamat Datang', style: AppTextStyles.heading2),
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
            controller: controller.emailController,
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
            decoration: InputDecoration(
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
          // Fixed: Removed unnecessary Obx here since we're not using any observable
          TextFormField(
            controller: controller.passwordController,
            obscureText: true,
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
              prefixIcon: Icon(
                Icons.lock_outlined,
                color: AppColors.primaryGreen,
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // Login Button - Only wrap this in Obx since it uses observable
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.login,
                child:
                    controller.isLoading.value
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
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
