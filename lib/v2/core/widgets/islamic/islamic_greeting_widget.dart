import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/data/models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class IslamicGreetingWidget extends StatelessWidget {
  final UserModel user;
  final bool showTime;

  const IslamicGreetingWidget({
    Key? key,
    required this.user,
    this.showTime = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // Profile Picture or Avatar
          CircleAvatar(
            radius: 30.r,
            backgroundColor: AppColors.goldAccent,
            backgroundImage:
                user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
            child:
                user.avatarUrl.isEmpty
                    ? Icon(
                      Icons.person,
                      size: 30.sp,
                      color: AppColors.primaryGreen,
                    )
                    : null,
          ),

          SizedBox(width: 16.w),

          // Greeting Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Arabic Greeting
                Text(
                  _getIslamicGreeting(),
                  style: AppTextStyles.arabicText.copyWith(
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),

                SizedBox(height: 4.h),

                // Indonesian Greeting
                Text(
                  _getIndonesianGreeting(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 8.h),

                // User name and role
                Text(
                  user.displayName,
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  user.roleDisplay,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),

                if (showTime) ...[
                  SizedBox(height: 4.h),
                  Text(
                    _getCurrentTime(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getIslamicGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 5) {
      return 'لَيْلَة سَعِيدَة'; // Good night
    } else if (hour < 11) {
      return 'صَبَاح الْخَيْر'; // Good morning
    } else if (hour < 15) {
      return 'ظُهْر سَعِيد'; // Good afternoon
    } else if (hour < 19) {
      return 'عَصْر سَعِيد'; // Good afternoon/evening
    } else {
      return 'مَسَاء الْخَيْر'; // Good evening
    }
  }

  String _getIndonesianGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 5) {
      return 'Selamat Malam';
    } else if (hour < 11) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 19) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
