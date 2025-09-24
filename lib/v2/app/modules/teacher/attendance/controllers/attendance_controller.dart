import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../data/services/api_service.dart';

class AttendanceController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Observables
  final isLoading = false.obs;
  final isSaving = false.obs;
  final scheduleDetail = Rxn<ScheduleDetailModel>();
  final studentsAttendance = <StudentAttendanceModel>[].obs;
  final selectedDate = DateTime.now().obs;

  // Form state
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  // Schedule info from arguments
  TodayScheduleModel? get schedule => Get.arguments?['schedule'] as TodayScheduleModel?;
  String? get scheduleId => schedule?.id ?? Get.arguments?['schedule_id'] as String?;

  @override
  void onInit() {
    super.onInit();
    if (scheduleId != null) {
      loadScheduleAttendance();
    } else {
      _showErrorSnackbar('Error', 'Jadwal tidak ditemukan');
      Get.back();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Load schedule and students for attendance
  Future<void> loadScheduleAttendance() async {
    try {
      isLoading.value = true;
      developer.log('Loading attendance for schedule: $scheduleId');

      final detail = await _apiService.getScheduleAttendance(
        scheduleId: scheduleId!,
        date: selectedDate.value,
      );

      scheduleDetail.value = detail;
      studentsAttendance.value = detail.students;
      
      developer.log('Loaded ${detail.students.length} students');
    } catch (e) {
      developer.log('Error loading attendance: $e');
      _showErrorSnackbar('Error', 'Gagal memuat data absensi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit attendance data
  Future<void> submitAttendance() async {
    try {
      isSaving.value = true;

      // Create submission model
      final submission = AttendanceSubmissionModel(
        scheduleId: scheduleId!,
        attendanceDate: selectedDate.value,
        attendances: studentsAttendance
            .map((student) => AttendanceRecordModel(
                  studentId: student.studentId,
                  status: student.currentStatus,
                  notes: student.notes,
                ))
            .toList(),
      );

      await _apiService.submitAttendance(submission);

      _showSuccessSnackbar(
        'بَارَكَ اللهُ فِيكَ',
        'Absensi berhasil disimpan. جزاك الله خيرا',
      );

      // Refresh data
      await loadScheduleAttendance();
    } catch (e) {
      developer.log('Error submitting attendance: $e');
      _showErrorSnackbar('Error', 'Gagal menyimpan absensi: $e');
    } finally {
      isSaving.value = false;
    }
  }

  /// Update student attendance status
  void updateStudentAttendance(String studentId, AttendanceStatus status, {String? notes}) {
    final index = studentsAttendance.indexWhere((s) => s.studentId == studentId);
    if (index != -1) {
      studentsAttendance[index] = studentsAttendance[index].copyWith(
        currentStatus: status,
        notes: notes,
      );
    }
  }

  /// Get filtered students based on search
  List<StudentAttendanceModel> get filteredStudents {
    if (searchQuery.value.isEmpty) {
      return studentsAttendance;
    }
    
    return studentsAttendance.where((student) {
      return student.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
             student.nisn.contains(searchQuery.value);
    }).toList();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Change attendance date
  Future<void> changeAttendanceDate(DateTime newDate) async {
    selectedDate.value = newDate;
    await loadScheduleAttendance();
  }

  /// Show attendance options bottom sheet
  void showAttendanceOptions(StudentAttendanceModel student) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            
            Text(
              student.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'NIS: ${student.nisn}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            
            SizedBox(height: 20),
            
            // Attendance options
            ...AttendanceStatus.values.map((status) => 
              ListTile(
                leading: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                ),
                title: Text(status.displayName),
                trailing: student.currentStatus == status 
                    ? Icon(Icons.check, color: Colors.green) 
                    : null,
                onTap: () {
                  updateStudentAttendance(student.studentId, status);
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Get attendance summary
  Map<AttendanceStatus, int> get attendanceSummary {
    final summary = <AttendanceStatus, int>{};
    for (final status in AttendanceStatus.values) {
      summary[status] = studentsAttendance
          .where((s) => s.currentStatus == status)
          .length;
    }
    return summary;
  }

  /// Get icon for attendance status
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

  /// Get color for attendance status
  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir:
        return Colors.green;
      case AttendanceStatus.sakit:
        return Colors.blue;
      case AttendanceStatus.izin:
        return Colors.orange;
      case AttendanceStatus.alpha:
        return Colors.red;
    }
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: Icon(Icons.check_circle, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      duration: Duration(seconds: 3),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: Icon(Icons.error, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      duration: Duration(seconds: 3),
    );
  }
}