import 'package:flutter/material.dart';
import '../services/student_service.dart';

class StudentController extends ChangeNotifier {
  final StudentService _studentService = StudentService();

  List<StudentModel> _students = [];
  List<StudentModel> get students => _students;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStudentsByKelas(int kelasId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _studentService.getStudentsByKelas(kelasId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 