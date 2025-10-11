import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/attendance_model.dart';
import '../controllers/student_data_controller.dart';

class StudentDataView extends GetView<StudentDataController> {
  const StudentDataView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return _buildLoadingState();
          }

          if (controller.teacherClasses.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Class Tabs
              _buildClassTabs(),

              // Search Bar
              _buildSearchBar(),

              // Class Info
              _buildClassInfo(),

              // Students List
              Expanded(child: _buildStudentsList()),
            ],
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Data Santri'),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (String value) {
            switch (value) {
              case 'export':
                controller.exportAttendanceReport();
                break;
              case 'refresh':
                controller.loadTeacherClasses();
                break;
              case 'filter':
                _showFilterDialog();
                break;
            }
          },
          itemBuilder:
              (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.file_download, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Ekspor Rekap Kelas'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'filter',
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Filter Data'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Muat Ulang'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  void _showFilterDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Data Siswa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              const Text(
                'Status Kehadiran:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Semua'),
                    selected: true,
                    onSelected: (selected) {},
                  ),
                  FilterChip(
                    label: const Text('Kehadiran > 90%'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                  FilterChip(
                    label: const Text('Kehadiran 75-90%'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                  FilterChip(
                    label: const Text('Kehadiran < 75%'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      // Apply filter logic here
                    },
                    child: const Text('Terapkan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassTabs() {
    return Container(
      height: 50.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Obx(
        () => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.teacherClasses.length,
          itemBuilder: (context, index) {
            final classData = controller.teacherClasses[index];
            final isSelected = controller.selectedClassIndex.value == index;

            return GestureDetector(
              onTap: () => controller.selectClass(index),
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.primaryGreen
                            : AppColors.dividerColor,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${classData.className}\n${classData.subjectName}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Cari santri...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
          border: InputBorder.none,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ),
    );
  }

  Widget _buildClassInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Obx(() {
        final selectedClass = controller.selectedClass;
        if (selectedClass == null) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedClass.subjectName,
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      selectedClass.className,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${selectedClass.studentCount} Santri',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
          return _buildEmptyStudentsState();
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

  Widget _buildStudentItem(StudentSummaryModel student) {
    final attendanceColor = controller.getAttendanceStatusColor(
      student.attendancePercentage,
    );
    final attendanceText = controller.getAttendanceStatusText(
      student.attendancePercentage,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              'NIS: ${student.nisn}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: attendanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Kehadiran: ${student.attendancePercentage.toStringAsFixed(1)}%',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: attendanceColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: attendanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    attendanceText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: attendanceColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () => controller.showStudentOptions(student),
      ),
    );
  }

  Widget _buildEmptyStudentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64.sp, color: AppColors.textHint),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_, size: 64.sp, color: AppColors.textHint),
          SizedBox(height: 16.h),
          Text(
            'Belum ada kelas yang diampu',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Hubungi admin untuk mengatur jadwal mengajar',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
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
            'Memuat data kelas...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
