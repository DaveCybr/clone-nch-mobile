import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../../app/data/models/dashboard_model.dart';

class PrayerTimeWidget extends StatelessWidget {
  final List<PrayerTimeModel> prayerTimes;
  final int currentIndex;

  const PrayerTimeWidget({
    Key? key,
    required this.prayerTimes,
    this.currentIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
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
          // Header
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppColors.primaryGreen,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text('Jadwal Shalat', style: AppTextStyles.cardTitle),
            ],
          ),

          SizedBox(height: 12.h),

          // Prayer Times List
          ...prayerTimes.asMap().entries.map((entry) {
            final index = entry.key;
            final prayer = entry.value;
            return _buildPrayerTimeItem(prayer, index == currentIndex);
          }).toList(),

          SizedBox(height: 8.h),

          // Dua
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.lightGreenBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children: [
                Text(
                  'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً',
                  style: AppTextStyles.arabicText.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.primaryGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Text(
                  'Rabbana atina fi\'d-dunya hasanah',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeItem(PrayerTimeModel prayer, bool isNext) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      margin: EdgeInsets.only(bottom: 4.h),
      decoration: BoxDecoration(
        color:
            isNext
                ? AppColors.primaryGreen.withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
        border:
            isNext
                ? Border.all(color: AppColors.primaryGreen.withOpacity(0.3))
                : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prayer.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                  color:
                      isNext ? AppColors.primaryGreen : AppColors.textPrimary,
                ),
              ),
              if (prayer.arabicName.isNotEmpty)
                Text(
                  prayer.arabicName,
                  style: AppTextStyles.arabicText.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color:
                  isNext
                      ? AppColors.primaryGreen
                      : AppColors.textHint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              prayer.time,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isNext ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
