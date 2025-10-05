import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/attendance_model.dart';
import '../controllers/attendance_controller.dart';

class AttendanceView extends GetView<AttendanceController> {
  const AttendanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        final scheduleDetail = controller.scheduleDetail.value;
        if (scheduleDetail == null) {
          return _buildErrorState();
        }

        return SafeArea(
          child: Column(
            children: [
              // Schedule Info
              _buildScheduleInfo(scheduleDetail),

              // Search Bar
              _buildSearchBar(),

              // Attendance Summary
              _buildAttendanceSummary(),

              // Students List
              Expanded(child: _buildStudentsList()),
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  // lib/v2/app/modules/teacher/attendance/views/attendance_view.dart - UPDATE AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Absensi Siswa'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.calendar_today),
          onPressed: _showDatePicker,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (String value) {
            switch (value) {
              case 'export':
                controller.showExportOptions();
                break;
              case 'print':
                controller.exportToExcel();
                break;
              case 'summary':
                _showAttendanceSummaryDialog();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.file_download, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Ekspor Laporan'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.print, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Cetak'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'summary',
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Ringkasan'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAttendanceSummaryDialog() {
    Get.dialog(
      SafeArea(
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ringkasan Absensi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),

                Obx(() {
                  final summary = controller.attendanceSummary;
                  final total = controller.studentsAttendance.length;

                  return Column(
                    children: [
                      _buildSummaryRow('Total Siswa', '$total', Colors.grey),
                      _buildSummaryRow(
                        'Hadir',
                        '${summary[AttendanceStatus.hadir] ?? 0}',
                        Colors.green,
                      ),
                      _buildSummaryRow(
                        'Sakit',
                        '${summary[AttendanceStatus.sakit] ?? 0}',
                        Colors.blue,
                      ),
                      _buildSummaryRow(
                        'Izin',
                        '${summary[AttendanceStatus.izin] ?? 0}',
                        Colors.orange,
                      ),
                      _buildSummaryRow(
                        'Alpha',
                        '${summary[AttendanceStatus.alpha] ?? 0}',
                        Colors.red,
                      ),

                      Divider(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Persentase Kehadiran:'),
                          Text(
                            '${total > 0 ? ((summary[AttendanceStatus.hadir] ?? 0) / total * 100).toStringAsFixed(1) : 0}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),

                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Tutup'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.showExportOptions();
                      },
                      child: Text('Ekspor'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInfo(ScheduleDetailModel schedule) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            schedule.subjectName,
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.class_, color: Colors.white70, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                schedule.className,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
              SizedBox(width: 16.w),
              Icon(Icons.access_time, color: Colors.white70, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                schedule.timeRange,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white70, size: 16.sp),
              SizedBox(width: 4.w),
              Obx(
                () => Text(
                  _formatDate(controller.selectedDate.value),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${schedule.totalStudents} Siswa',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Cari siswa...',
          prefixIcon: Icon(Icons.search, color: AppColors.textHint),
          border: InputBorder.none,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Obx(() {
        final summary = controller.attendanceSummary;
        return Row(
          children: AttendanceStatus.values.map((status) {
            final count = summary[status] ?? 0;
            final color = _getStatusColor(status);

            return Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      count.toString(),
                      style: AppTextStyles.heading2.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      status.displayName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildStudentsList() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Obx(() {
        final students = controller.filteredStudents;

        if (students.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return _buildStudentItem(student);
          },
        );
      }),
    );
  }

  Widget _buildStudentItem(StudentAttendanceModel student) {
    final statusColor = _getStatusColor(student.currentStatus);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
            style: AppTextStyles.bodyMedium.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'NIS: ${student.nisn}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: GestureDetector(
          onTap: () => controller.showAttendanceOptions(student),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(student.currentStatus),
                  size: 16.sp,
                  color: statusColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  student.currentStatus.displayName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        onTap: () => controller.showAttendanceOptions(student),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64.sp, color: AppColors.textHint),
          SizedBox(height: 16.h),
          Text(
            'Tidak ada siswa ditemukan',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
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
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
          SizedBox(height: 16.h),
          Text(
            'Memuat data siswa...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            'Gagal memuat data',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: controller.loadScheduleAttendance,
            child: Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SafeArea(
      bottom: true, // Ini akan memberikan padding otomatis dari navigation bar
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Obx(
          () => SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : controller.submitAttendance,
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
                        Text('Menyimpan...', style: AppTextStyles.buttonText),
                      ],
                    )
                  : Text('Simpan Absensi', style: AppTextStyles.buttonText),
            ),
          ),
        ),
      ),
    );
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    debugPrint(picked.toString());
    if (picked != null && picked != controller.selectedDate.value) {
      debugPrint(picked.toIso8601String());
      await controller.changeAttendanceDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final days = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return '${days[date.weekday]}, ${date.day} ${months[date.month]} ${date.year}';
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir:
        return Icons.check_circle;
      case AttendanceStatus.sakit:
        return Icons.local_hospital;
      case AttendanceStatus.izin:
        return Icons.info;
      case AttendanceStatus.alpha:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir:
        return AppColors.attendancePresent;
      case AttendanceStatus.sakit:
        return AppColors.attendanceSick;
      case AttendanceStatus.izin:
        return AppColors.attendancePermit;
      case AttendanceStatus.alpha:
        return AppColors.attendanceAbsent;
    }
  }
}
