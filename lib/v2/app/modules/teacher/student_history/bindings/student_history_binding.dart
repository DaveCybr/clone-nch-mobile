import 'package:get/get.dart';
import '../../../../data/models/attendance_model.dart';
import '../controllers/student_history_controller.dart';

class StudentHistoryBinding extends Bindings {
  @override
  void dependencies() {
    // ✅ CRITICAL FIX: Get arguments dengan fallback
    // Kadang Get.arguments masih null saat binding di-execute

    // Method 1: Coba ambil dari Get.arguments
    var args = Get.arguments as Map<String, dynamic>?;

    // Method 2: Jika null, coba dari Get.parameters (routing fallback)
    args ??= Get.parameters.isNotEmpty ? Get.parameters : null;

    // ✅ Log untuk debug
    print('📦 StudentHistoryBinding - Raw arguments: $args');

    if (args != null) {
      print('✅ Arguments found:');
      print('   - student: ${args['student']}');
      print('   - subject_id: ${args['subject_id']}');
      print('   - subject_name: ${args['subject_name']}');
      print('   - class_name: ${args['class_name']}');
    } else {
      print('⚠️ WARNING: Arguments is NULL in binding!');
    }

    // ✅ Create controller with arguments
    Get.lazyPut<StudentHistoryController>(
      () {
        final student = args?['student'] as StudentSummaryModel?;
        final subjectId = args?['subject_id'] as String?;
        final subjectName = args?['subject_name'] as String?;
        final className = args?['class_name'] as String?;

        print('🏗️ Creating StudentHistoryController with:');
        print('   - student: ${student?.name ?? "NULL"}');
        print('   - subjectId: ${subjectId ?? "NULL"}');
        print('   - subjectName: ${subjectName ?? "NULL"}');
        print('   - className: ${className ?? "NULL"}');

        return StudentHistoryController(
          student: student,
          subjectId: subjectId,
          subjectName: subjectName,
          className: className,
        );
      },
      fenix: true, // ✅ Allow recreation if needed
    );
  }
}
