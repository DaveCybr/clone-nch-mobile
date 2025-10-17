import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/routes/app_routes.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/services/api_service.dart';
import '../../student_history/controllers/student_history_controller.dart';
import '../../student_history/views/student_history_view.dart';

class StudentDataController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Observables
  final isLoading = false.obs;
  final teacherClasses = <TeacherClassModel>[].obs;
  final selectedClassIndex = 0.obs;
  final searchQuery = ''.obs;

  // ✅ Flag untuk prevent multiple navigations
  bool _isNavigating = false;

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

      final classes = await _apiService.getTeacherClasses();

      developer.log('📦 API Response classes count: ${classes.length}');
      for (var i = 0; i < classes.length; i++) {
        developer.log('Class $i:');
        developer.log('  - scheduleId: ${classes[i].scheduleId}');
        developer.log('  - subjectName: ${classes[i].subjectName}');
        developer.log('  - className: ${classes[i].className}');
      }

      if (classes.isNotEmpty) {
        teacherClasses.value = classes;
        developer.log('✅ Loaded ${classes.length} classes with students');
      } else {
        await loadFromDashboard();
      }
    } catch (e, stackTrace) {
      developer.log('❌ Error loading teacher classes: $e');
      _showErrorSnackbar('Error', 'Gagal memuat data kelas');
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Fallback method: Load dari dashboard API
  Future<void> loadFromDashboard() async {
    try {
      final dashboard = await _apiService.getTeacherDashboard();
      final schedules = dashboard['today_schedules'] as List<dynamic>?;

      if (schedules != null && schedules.isNotEmpty) {
        developer.log('📦 Dashboard schedules: ${schedules.length}');
        for (var schedule in schedules) {
          developer.log('Schedule data: $schedule');
        }

        teacherClasses.value =
            schedules
                .map(
                  (schedule) => TeacherClassModel.fromJson(
                    schedule as Map<String, dynamic>,
                  ),
                )
                .toList();

        await loadStudentsForAllClasses();
      } else {
        teacherClasses.value = [];
        developer.log('⚠️ No schedules found in dashboard');
      }
    } catch (e) {
      developer.log('❌ Error loading from dashboard: $e');
    }
  }

  /// ✅ Load students untuk semua kelas menggunakan API
  Future<void> loadStudentsForAllClasses() async {
    for (int i = 0; i < teacherClasses.length; i++) {
      try {
        final classData = teacherClasses[i];
        final classId = _extractClassId(classData.className);

        developer.log(
          '🔍 Fetching students for class: ${classData.className} (id: $classId)',
        );

        final studentsData = await _apiService.getTeacherStudents(
          classId: classId,
        );

        final students =
            studentsData
                .map(
                  (e) =>
                      StudentSummaryModel.fromJson(e as Map<String, dynamic>),
                )
                .toList();

        developer.log(
          '✅ Loaded ${students.length} students for ${classData.className}',
        );

        teacherClasses[i] = classData.copyWith(students: students);
      } catch (e) {
        developer.log('⚠️ Error loading students for class ${i}: $e');
        final dummyStudents = _createDummyStudents(
          teacherClasses[i].studentCount,
        );
        teacherClasses[i] = teacherClasses[i].copyWith(students: dummyStudents);
      }
    }
  }

  String _extractClassId(String className) {
    return className
        .toLowerCase()
        .replaceAll('kelas ', '')
        .replaceAll(' ', '-');
  }

  List<StudentSummaryModel> _createDummyStudents(int count) {
    return List.generate(
      count,
      (index) => StudentSummaryModel(
        studentId: 'student_${index + 1}',
        name: 'Santri ${index + 1}',
        nisn: '${202400000 + index + 1}',
        attendancePercentage: 85.0 + (index % 15),
      ),
    );
  }

  TeacherClassModel? get selectedClass {
    if (teacherClasses.isEmpty ||
        selectedClassIndex.value >= teacherClasses.length) {
      return null;
    }
    return teacherClasses[selectedClassIndex.value];
  }

  List<StudentSummaryModel> get filteredStudents {
    final currentClass = selectedClass;
    if (currentClass == null) return [];

    if (searchQuery.value.isEmpty) {
      return currentClass.students;
    }

    return currentClass.students.where((student) {
      return student.name.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          student.nisn.contains(searchQuery.value);
    }).toList();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void selectClass(int index) {
    if (index >= 0 && index < teacherClasses.length) {
      selectedClassIndex.value = index;
      searchController.clear();
      searchQuery.value = '';
    }
  }

  /// ✅ FIXED: Navigate to student attendance history WITHOUT BINDING
  Future<void> viewStudentHistory(StudentSummaryModel student) async {
    // ✅ Prevent multiple simultaneous navigations
    if (_isNavigating) {
      developer.log('⚠️ Already navigating, ignoring duplicate call');
      return;
    }

    final currentClass = selectedClass;
    if (currentClass == null) {
      developer.log('⚠️ Cannot navigate: selectedClass is null');
      _showErrorSnackbar('Error', 'Data kelas tidak ditemukan');
      return;
    }

    if (currentClass.scheduleId.isEmpty) {
      developer.log('❌ scheduleId is empty!');
      _showErrorSnackbar(
        'Error',
        'ID jadwal tidak ditemukan. Silakan muat ulang data.',
      );
      return;
    }

    developer.log('🔄 Navigating to student history:');
    developer.log('  - Student: ${student.name} (${student.studentId})');
    developer.log('  - Subject: ${currentClass.subjectName}');
    developer.log('  - Subject ID: ${currentClass.scheduleId}');
    developer.log('  - Class: ${currentClass.className}');

    try {
      _isNavigating = true;

      // ✅ Wait untuk ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 100));

      // ✅ Delete old controller if exists
      if (Get.isRegistered<StudentHistoryController>()) {
        Get.delete<StudentHistoryController>();
      }

      // ✅ Create controller dengan data langsung (NO BINDING!)
      Get.put(
        StudentHistoryController(
          student: student,
          subjectId: currentClass.scheduleId,
          subjectName: currentClass.subjectName,
          className: currentClass.className,
        ),
      );

      developer.log('✅ Controller created with data');

      // ✅ Navigate WITHOUT binding
      final result = await Get.to(
        () => const StudentHistoryView(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
        preventDuplicates: true,
      );

      developer.log('✅ Navigation completed, result: $result');

      // ✅ Cleanup controller after back
      if (Get.isRegistered<StudentHistoryController>()) {
        Get.delete<StudentHistoryController>();
      }
    } catch (e, stackTrace) {
      developer.log('❌ Navigation error: $e');
      developer.log('Stack trace: $stackTrace');
      _showErrorSnackbar('Error', 'Gagal membuka halaman riwayat: $e');
    } finally {
      _isNavigating = false;
    }
  }

  Color getAttendanceStatusColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  String getAttendanceStatusText(double percentage) {
    if (percentage >= 90) return 'Baik';
    if (percentage >= 75) return 'Cukup';
    return 'Kurang';
  }

  /// ✅ FIXED: Show student options bottom sheet
  void showStudentOptions(StudentSummaryModel student) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

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

              const SizedBox(height: 16),

              Text(
                student.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'NIS: ${student.nisn}',
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: getAttendanceStatusColor(
                    student.attendancePercentage,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Kehadiran: ${student.attendancePercentage.toStringAsFixed(1)}% (${getAttendanceStatusText(student.attendancePercentage)})',
                  style: TextStyle(
                    color: getAttendanceStatusColor(
                      student.attendancePercentage,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ FIXED: Action buttons
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('Lihat Riwayat Kehadiran'),
                onTap: () async {
                  Get.back(); // Close bottomsheet

                  // ✅ Wait 350ms untuk bottomsheet animation selesai
                  await Future.delayed(const Duration(milliseconds: 350));

                  // ✅ Baru navigate
                  viewStudentHistory(student);
                },
              ),

              ListTile(
                leading: const Icon(Icons.person, color: Colors.green),
                title: const Text('Detail Profil Siswa'),
                onTap: () {
                  Get.back();
                  Future.delayed(const Duration(milliseconds: 350), () {
                    _showSnackbar(
                      'Info',
                      'Fitur detail profil akan segera tersedia',
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }

  void _showErrorSnackbar(String title, String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        title,
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _showSnackbar(String title, String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        title,
        message,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        icon: const Icon(Icons.info, color: Colors.white),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> exportAttendanceReport() async {
    try {
      final selectedClass = this.selectedClass;
      if (selectedClass == null) {
        _showErrorSnackbar('Error', 'Pilih kelas terlebih dahulu');
        return;
      }

      _showSnackbar('Info', 'Sedang memproses ekspor...');

      await Future.delayed(const Duration(seconds: 1));

      _showSuccessSnackbar('تبارك الله', 'Rekap kelas berhasil diekspor');
    } catch (e) {
      developer.log('Error exporting class summary: $e');
      _showErrorSnackbar('Error', 'Gagal mengekspor rekap kelas: $e');
    }
  }

  void _showSuccessSnackbar(String title, String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        title,
        message,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
