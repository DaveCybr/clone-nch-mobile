import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/services/api_service.dart';

class StudentDataController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Observables
  final isLoading = false.obs;
  final teacherClasses = <TeacherClassModel>[].obs;
  final selectedClassIndex = 0.obs;
  final searchQuery = ''.obs;

  // Form controllers
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadTeacherClasses();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Load teacher's classes and students
  Future<void> loadTeacherClasses() async {
    try {
      isLoading.value = true;
      developer.log('Loading teacher classes');

      final classes = await _apiService.getTeacherClasses();
      teacherClasses.value = classes;
      
      developer.log('Loaded ${classes.length} classes');
    } catch (e) {
      developer.log('Error loading classes: $e');
      _showErrorSnackbar('Error', 'Gagal memuat data kelas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get current selected class
  TeacherClassModel? get selectedClass {
    if (teacherClasses.isEmpty || selectedClassIndex.value >= teacherClasses.length) {
      return null;
    }
    return teacherClasses[selectedClassIndex.value];
  }

  /// Get filtered students based on search
  List<StudentSummaryModel> get filteredStudents {
    final currentClass = selectedClass;
    if (currentClass == null) return [];

    if (searchQuery.value.isEmpty) {
      return currentClass.students;
    }
    
    return currentClass.students.where((student) {
      return student.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
             student.nisn.contains(searchQuery.value);
    }).toList();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Change selected class
  void selectClass(int index) {
    if (index >= 0 && index < teacherClasses.length) {
      selectedClassIndex.value = index;
      // Clear search when changing class
      searchController.clear();
      searchQuery.value = '';
    }
  }

  /// Navigate to student attendance history
  void viewStudentHistory(StudentSummaryModel student) {
    final currentClass = selectedClass;
    if (currentClass != null) {
      Get.toNamed(
        '/teacher/student-history',
        arguments: {
          'student': student,
          'subject_id': currentClass.subjectId,
          'subject_name': currentClass.subjectName,
          'class_name': currentClass.className,
        },
      );
    }
  }

  /// Get attendance status color
  Color getAttendanceStatusColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  /// Get attendance status text
  String getAttendanceStatusText(double percentage) {
    if (percentage >= 90) return 'Baik';
    if (percentage >= 75) return 'Cukup';
    return 'Kurang';
  }

  /// Show student options bottom sheet
  void showStudentOptions(StudentSummaryModel student) {
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
            
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue[100],
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            Text(
              student.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'NIS: ${student.nisn}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            
            SizedBox(height: 8),
            
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: getAttendanceStatusColor(student.attendancePercentage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Kehadiran: ${student.attendancePercentage.toStringAsFixed(1)}% (${getAttendanceStatusText(student.attendancePercentage)})',
                style: TextStyle(
                  color: getAttendanceStatusColor(student.attendancePercentage),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Action buttons
            ListTile(
              leading: Icon(Icons.history, color: Colors.blue),
              title: Text('Lihat Riwayat Kehadiran'),
              onTap: () {
                Get.back();
                viewStudentHistory(student);
              },
            ),
            
            ListTile(
              leading: Icon(Icons.person, color: Colors.green),
              title: Text('Detail Profil Siswa'),
              onTap: () {
                Get.back();
                _showSnackbar('Info', 'Fitur detail profil akan segera tersedia');
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Export attendance report
  void exportAttendanceReport() {
    _showSnackbar('Info', 'Fitur export laporan akan segera tersedia');
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

  void _showSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      icon: Icon(Icons.info, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      duration: Duration(seconds: 3),
    );
  }
}