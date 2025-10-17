import 'package:get/get.dart';
import '../../../../data/models/attendance_model.dart';
import '../controllers/student_history_controller.dart';

class StudentHistoryBinding extends Bindings {
  @override
  void dependencies() {
    // ✅ Ambil arguments dan pass ke controller
    final args = Get.arguments as Map<String, dynamic>?;

    Get.lazyPut<StudentHistoryController>(
      () => StudentHistoryController(
        student: args?['student'] as StudentSummaryModel?,
        subjectId: args?['subject_id'] as String?,
        subjectName: args?['subject_name'] as String?,
        className: args?['class_name'] as String?,
      ),
      fenix: true,
    );
  }
}
