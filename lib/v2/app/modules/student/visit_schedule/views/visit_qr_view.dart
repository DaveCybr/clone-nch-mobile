// lib/v2/app/modules/student/visit_schedule/views/visit_qr_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/visit_schedule_model.dart';

class VisitQRView extends StatelessWidget {
  final VisitLogModel visit; // ✅ Required parameter

  const VisitQRView({Key? key, required this.visit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final schedule = visit.visitSchedule;

    // Debug log
    print('✅ VisitQRView - Loaded successfully');
    print('Visit ID: ${visit.id}');
    print('Barcode: ${visit.barcode}');

    return Scaffold(
      appBar: AppBar(title: const Text('QR Code Kunjungan'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: _getStatusColor(visit.status),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                visit.statusText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // QR Code Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Container(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Text(
                      schedule?.title ?? 'Kunjungan',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.h),

                    // QR Code
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                      child: QrImageView(
                        data: visit.barcode,
                        version: QrVersions.auto,
                        size: 250.w,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primaryGreen,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // ✅ BARCODE TEXT DIHAPUS - Tidak ditampilkan lagi
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Visit Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Container(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detail Kunjungan', style: AppTextStyles.heading3),
                    SizedBox(height: 16.h),
                    _buildInfoRow(
                      Icons.person,
                      'Tujuan Kunjungan',
                      visit.student?.name ?? '-',
                    ),
                    if (visit.student?.className != null)
                      _buildInfoRow(
                        Icons.school,
                        'Kelas',
                        visit.student!.className!,
                      ),
                    _buildInfoRow(
                      Icons.location_on,
                      'Lokasi',
                      schedule?.location ?? '-',
                    ),
                    _buildInfoRow(
                      Icons.access_time,
                      'Jadwal',
                      schedule?.dateRange ?? '-',
                    ),
                    _buildInfoRow(
                      Icons.timer,
                      'Durasi Maksimal',
                      '${schedule?.maxDurationMinutes ?? 0} menit',
                    ),
                    _buildInfoRow(Icons.notes, 'Keperluan', visit.visitPurpose),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Instructions Card
            Card(
              elevation: 2,
              color: AppColors.primaryGreenLight.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primaryGreen,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Petunjuk',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _buildInstruction(
                      '1',
                      'Tunjukkan QR Code ini kepada petugas keamanan',
                    ),
                    _buildInstruction(
                      '2',
                      'Petugas akan melakukan scan untuk check-in',
                    ),
                    _buildInstruction(
                      '3',
                      'Setelah selesai berkunjung, scan kembali untuk check-out',
                    ),
                    _buildInstruction(
                      '4',
                      'Pastikan tidak melebihi durasi maksimal kunjungan',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: AppColors.primaryGreen),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'CHECKED_IN':
        return AppColors.attendancePresent;
      case 'CHECKED_OUT':
        return Colors.grey;
      case 'OVERSTAY':
        return Colors.red;
      case 'CANCELLED':
        return Colors.red;
      default:
        return AppColors.primaryGreen;
    }
  }
}
