// lib/v2/app/modules/student/visit_schedule/views/visit_schedule_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/visit_schedule_model.dart';
import '../controllers/visit_schedule_controller.dart';

class VisitScheduleView extends GetView<VisitScheduleController> {
  const VisitScheduleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kunjungan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshData,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return _buildErrorState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUpcomingVisitsSection(),
                SizedBox(height: 16.h),
                _buildActiveSchedulesSection(),
                SizedBox(height: 16.h),
                _buildCompletedVisitsSection(),
                SizedBox(height: 80.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text('Gagal Memuat Data', style: AppTextStyles.heading3),
            SizedBox(height: 8.h),
            Text(
              controller.error.value ?? 'Terjadi kesalahan',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: controller.loadVisitSchedules,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingVisitsSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_available,
                color: AppColors.primaryGreen,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Konfirmasi Kunjungan',
                  style: AppTextStyles.heading3,
                ),
              ),
              if (controller.upcomingVisits.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${controller.upcomingVisits.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          if (controller.upcomingVisits.isEmpty)
            _buildEmptyCard('Tidak ada kunjungan terdaftar')
          else
            ...controller.upcomingVisits.map((visit) => _buildVisitCard(visit)),
        ],
      ),
    );
  }

  Widget _buildActiveSchedulesSection() {
    return Obx(() {
      final availableSchedules =
          controller.activeSchedules
              .where(
                (schedule) =>
                    !controller.usedScheduleIds.contains(schedule.id) &&
                    (schedule.isOngoing || schedule.isUpcoming),
              )
              .toList();

      final hasPending = controller.hasPendingVisit;
      final totalSchedules = controller.activeSchedules.length;
      final usedCount = controller.usedScheduleIds.length;

      return Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.blue, size: 24.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text('Jadwal Tersedia', style: AppTextStyles.heading3),
                ),
                if (availableSchedules.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${availableSchedules.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            if (hasPending) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Anda masih memiliki kunjungan aktif. Selesaikan kunjungan terlebih dahulu.',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 12.h),

            if (availableSchedules.isEmpty)
              _buildEmptyCard(
                hasPending
                    ? 'Selesaikan kunjungan aktif Anda terlebih dahulu'
                    : usedCount == totalSchedules
                    ? 'Semua jadwal sudah Anda daftarkan'
                    : 'Belum ada jadwal kunjungan tersedia',
              )
            else
              ...availableSchedules.map(
                (schedule) => _buildScheduleCard(schedule, hasPending),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildCompletedVisitsSection() {
    return Obx(() {
      return Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.grey[700], size: 24.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Riwayat Kunjungan',
                    style: AppTextStyles.heading3,
                  ),
                ),
                if (controller.completedVisits.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${controller.completedVisits.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            if (controller.completedVisits.isEmpty)
              _buildEmptyCard('Belum ada riwayat kunjungan')
            else ...[
              // ✅ Tampilkan hanya data yang sudah di-load
              ...controller.displayedCompletedVisits.map(
                (visit) => _buildCompletedVisitCard(visit),
              ),

              // ✅ Loading Indicator saat ada data lebih
              if (controller.hasMoreCompletedVisits)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[600]!,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Memuat ${controller.completedVisits.length - controller.displayedCompletedCount.value} data lagi...',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildCompletedVisitCard(VisitLogModel visit) {
    final schedule = visit.visitSchedule;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _getStatusColor(visit.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    _getStatusIcon(visit.status),
                    color: _getStatusColor(visit.status),
                    size: 28.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule?.title ?? 'Kunjungan',
                        style: AppTextStyles.cardTitle,
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(visit.status),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          visit.statusText,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildInfoRow(
              Icons.person,
              'Tujuan: ${visit.student?.name ?? '-'}',
            ),
            if (visit.student?.className != null) ...[
              SizedBox(height: 4.h),
              _buildInfoRow(Icons.school, 'Kelas: ${visit.student!.className}'),
            ],
            SizedBox(height: 4.h),
            _buildInfoRow(Icons.location_on, schedule?.location ?? '-'),
            SizedBox(height: 4.h),
            _buildInfoRow(Icons.access_time, schedule?.dateRange ?? '-'),
            SizedBox(height: 4.h),
            _buildInfoRow(Icons.notes, visit.visitPurpose),

            if (visit.checkInTime != null) ...[
              SizedBox(height: 8.h),
              Divider(),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeInfo(
                      'Check In',
                      _formatTime(visit.checkInTime!),
                      Icons.login,
                      Colors.green,
                    ),
                  ),
                  if (visit.checkOutTime != null) ...[
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildTimeInfo(
                        'Check Out',
                        _formatTime(visit.checkOutTime!),
                        Icons.logout,
                        Colors.blue,
                      ),
                    ),
                  ],
                ],
              ),
              if (visit.durationMinutes != null) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timelapse, size: 16.sp, color: Colors.purple),
                      SizedBox(width: 8.w),
                      Text(
                        'Durasi: ${_formatDuration(visit.durationMinutes!)}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.purple[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            if (visit.notes != null && visit.notes!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sticky_note_2,
                      size: 16.sp,
                      color: Colors.grey[700],
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catatan',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            visit.notes!,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '$hours jam $remainingMinutes menit';
    } else {
      return '$minutes menit';
    }
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(VisitLogModel visit) {
    final schedule = visit.visitSchedule;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () {
          print(
            '🎫 VISIT CARD CLICKED - ID: ${visit.id}, Barcode: ${visit.barcode}',
          );
          controller.navigateToQRCode(visit);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: _getStatusColor(visit.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.qr_code_2,
                      color: _getStatusColor(visit.status),
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule?.title ?? 'Kunjungan',
                          style: AppTextStyles.cardTitle,
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(visit.status),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            visit.statusText,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textHint),
                ],
              ),
              SizedBox(height: 12.h),
              _buildInfoRow(
                Icons.person,
                'Tujuan: ${visit.student?.name ?? '-'}',
              ),
              SizedBox(height: 4.h),
              _buildInfoRow(Icons.location_on, schedule?.location ?? '-'),
              SizedBox(height: 4.h),
              _buildInfoRow(Icons.access_time, schedule?.dateRange ?? '-'),
              SizedBox(height: 4.h),
              _buildInfoRow(Icons.notes, visit.visitPurpose),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreenLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryGreen,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Tap untuk melihat QR Code',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(VisitScheduleModel schedule, bool isDisabled) {
    return Obx(() {
      final isGenerating = controller.isGeneratingQR.value;

      return Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Card(
          margin: EdgeInsets.only(bottom: 12.h),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: InkWell(
            onTap:
                (isGenerating || isDisabled)
                    ? null
                    : () {
                      print('📋 SCHEDULE CARD CLICKED - ID: ${schedule.id}');
                      controller.generateQRFromSchedule(schedule);
                    },
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.event,
                          color: Colors.blue,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.title,
                              style: AppTextStyles.cardTitle,
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.attendancePresent,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'Sedang Berlangsung',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isGenerating)
                        SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (isDisabled)
                        Icon(Icons.lock, color: Colors.grey, size: 20.sp)
                      else
                        Icon(Icons.chevron_right, color: AppColors.textHint),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoRow(Icons.location_on, schedule.location),
                  SizedBox(height: 4.h),
                  _buildInfoRow(Icons.access_time, schedule.dateRange),
                  SizedBox(height: 4.h),
                  _buildInfoRow(
                    Icons.timer,
                    'Durasi maksimal: ${schedule.maxDurationMinutes} menit',
                  ),
                  if (schedule.description != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      schedule.description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (!isGenerating && !isDisabled) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Tap untuk mendaftar dan dapatkan QR Code',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.textHint),
        SizedBox(width: 8.w),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48.sp, color: AppColors.textHint),
            SizedBox(height: 12.h),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'CHECKED_OUT':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      case 'OVERSTAY':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }
}
