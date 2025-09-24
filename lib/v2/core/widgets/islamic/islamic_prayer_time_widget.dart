import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class PrayerTimeWidget extends StatelessWidget {
  final List<PrayerTime> prayerTimes;

  const PrayerTimeWidget({Key? key, required this.prayerTimes})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppColors.primaryGreen,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Jadwal Shalat Hari Ini',
                style: AppTextStyles.heading3.copyWith(fontSize: 16.sp),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Prayer Times List
          ...prayerTimes.map((prayer) => _buildPrayerTimeItem(prayer)),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeItem(PrayerTime prayer) {
    final isCurrentPrayer = _isCurrentPrayerTime(prayer);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      margin: EdgeInsets.only(bottom: 4.h),
      decoration: BoxDecoration(
        color:
            isCurrentPrayer
                ? AppColors.primaryGreen.withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: prayer.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.brightness_1,
                  size: 8.sp,
                  color: prayer.color,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                prayer.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight:
                      isCurrentPrayer ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            prayer.time,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isCurrentPrayer ? FontWeight.bold : FontWeight.w500,
              color:
                  isCurrentPrayer
                      ? AppColors.primaryGreen
                      : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentPrayerTime(PrayerTime prayer) {
    // Simple logic to determine current prayer time
    // final now = TimeOfDay.now();
    // final prayerTime = TimeOfDay(
    //   hour: int.parse(prayer.time.split(':')[0]),
    //   minute: int.parse(prayer.time.split(':')[1]),
    // );

    // This is simplified - you would implement proper prayer time logic here
    return false; // Placeholder
  }
}

class PrayerTime {
  final String name;
  final String time;
  final Color color;

  const PrayerTime({
    required this.name,
    required this.time,
    required this.color,
  });

  static List<PrayerTime> getDefaultPrayerTimes() {
    return [
      PrayerTime(name: 'Subuh', time: '04:30', color: AppColors.fajrColor),
      PrayerTime(name: 'Dzuhur', time: '12:00', color: AppColors.dhuhrColor),
      PrayerTime(name: 'Ashar', time: '15:30', color: AppColors.asrColor),
      PrayerTime(name: 'Maghrib', time: '18:15', color: AppColors.maghribColor),
      PrayerTime(name: 'Isya', time: '19:30', color: AppColors.ishaColor),
    ];
  }
}
