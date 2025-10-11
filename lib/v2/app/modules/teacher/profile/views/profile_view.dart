// lib/v2/app/modules/teacher/profile/views/profile_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(),

              SizedBox(height: 20.h),

              // Profile Form
              _buildProfileForm(),

              SizedBox(height: 20.h),

              // Action Buttons
              _buildActionButtons(),

              SizedBox(height: 20.h),

              // Statistics Card
              _buildStatisticsCard(),
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Profil Saya'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // Toggle edit mode or show edit dialog
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              CircleAvatar(
                radius: 50.r,
                backgroundColor: AppColors.goldAccent,
                backgroundImage:
                    controller.user.value?.avatarUrl.isNotEmpty == true
                    ? NetworkImage(controller.user.value!.avatarUrl)
                    : null,
                child: controller.user.value?.avatarUrl.isEmpty != false
                    ? Icon(
                        Icons.person,
                        size: 50.sp,
                        color: AppColors.primaryGreen,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: const BoxDecoration(
                    color: AppColors.goldAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 16.sp,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Name and Role
          Text(
            controller.user.value?.displayName ?? 'Nama Pengguna',
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          Text(
            controller.user.value?.roleDisplay ?? 'Role',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),

          SizedBox(height: 8.h),

          // NIP if available
          if (controller.user.value?.nip != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'NIP: ${controller.user.value!.nip}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informasi Personal', style: AppTextStyles.cardTitle),
            SizedBox(height: 16.h),

            // Name Field
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person, color: AppColors.primaryGreen),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Nama tidak boleh kosong' : null,
            ),

            SizedBox(height: 16.h),

            // Email Field (Read-only)
            TextFormField(
              controller: controller.emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email, color: AppColors.primaryGreen),
              ),
              readOnly: true,
              style: const TextStyle(color: AppColors.textSecondary),
            ),

            SizedBox(height: 16.h),

            // Phone Field
            TextFormField(
              controller: controller.phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                prefixIcon: Icon(Icons.phone, color: AppColors.primaryGreen),
              ),
              keyboardType: TextInputType.phone,
            ),

            SizedBox(height: 16.h),

            // Address Field
            TextFormField(
              controller: controller.addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                prefixIcon: Icon(
                  Icons.location_on,
                  color: AppColors.primaryGreen,
                ),
              ),
              maxLines: 2,
              readOnly: true,
              style: const TextStyle(color: AppColors.textSecondary),
            ),

            SizedBox(height: 20.h),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
<<<<<<< HEAD
                  onPressed:
                      controller.isSaving.value
                          ? null
                          : controller.updateProfile,
                  child:
                      controller.isSaving.value
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
                              const Text('Menyimpan...'),
                            ],
                          )
                          : const Text('Simpan Perubahan'),
=======
                  onPressed: controller.isSaving.value
                      ? null
                      : controller.updateProfile,
                  child: controller.isSaving.value
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
                            Text('Menyimpan...'),
                          ],
                        )
                      : Text('Simpan Perubahan'),
>>>>>>> 49d3e7f6c546314a0079c5f85aecd72981ffaa46
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Change Password
        _buildActionTile(
          icon: Icons.lock,
          title: 'Ubah Password',
          subtitle: 'Ganti password akun Anda',
          onTap: controller.showChangePasswordDialog,
        ),

        SizedBox(height: 8.h),

        // About App
        _buildActionTile(
          icon: Icons.info,
          title: 'Tentang Aplikasi',
          subtitle: 'Versi 1.0.0 - My NCH',
          onTap: () => _showAboutDialog(),
        ),

        SizedBox(height: 8.h),

        // Logout
        _buildActionTile(
          icon: Icons.logout,
          title: 'Keluar',
          subtitle: 'Logout dari aplikasi',
          color: Colors.red,
          onTap: controller.logout,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primaryGreen).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: color ?? AppColors.primaryGreen,
            size: 20.sp,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistik Mengajar', style: AppTextStyles.cardTitle),
          SizedBox(height: 16.h),

          // Stats would come from API
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Kelas',
                  '4',
                  Icons.class_,
                  AppColors.primaryGreen,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatItem(
                  'Total Siswa',
                  '120',
                  Icons.people,
                  Colors.blue,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Absensi Bulan Ini',
                  '28',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatItem(
                  'Rata-rata Kehadiran',
                  '94%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
          SizedBox(height: 16.h),
          Text(
            'Memuat profil...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.school, color: AppColors.primaryGreen),
            SizedBox(width: 8.w),
            Text('My NCH'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
              style: AppTextStyles.arabicText.copyWith(fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            const Text('Aplikasi Absensi Guru'),
            const Text('Versi: 1.0.0'),
            const Text('Build: 2025.01.01'),
            SizedBox(height: 8.h),
            Text('جزاك الله خيرا', style: AppTextStyles.arabicSubtitle),
            Text(
              'Semoga aplikasi ini bermanfaat',
              style: AppTextStyles.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
              ),
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
