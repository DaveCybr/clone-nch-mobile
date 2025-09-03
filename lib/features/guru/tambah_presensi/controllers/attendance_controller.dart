import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceController extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();

  List<AttendanceModel> _attendances = [];
  List<AttendanceModel> get attendances => _attendances;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAttendances({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _attendances = await _attendanceService.getAttendances(
        page: page,
        limit: limit,
        search: search,
        status: status,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AttendanceModel?> createAttendance(AttendanceModel attendance) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdAttendance = await _attendanceService.createAttendance(
        attendance,
      );
      _attendances.add(createdAttendance);
      notifyListeners();
      return createdAttendance;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<AttendanceModel>?> createBulkAttendance(
    List<AttendanceModel> attendances,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdAttendances = await _attendanceService.createBulkAttendance(
        attendances,
      );
      _attendances.addAll(createdAttendances);
      notifyListeners();
      return createdAttendances;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AttendanceModel?> updateAttendance(
    int id,
    AttendanceModel attendance,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedAttendance = await _attendanceService.updateAttendance(
        id,
        attendance,
      );

      // Perbarui data di list
      final index = _attendances.indexWhere((a) => a.id == id);
      if (index != -1) {
        _attendances[index] = updatedAttendance;
      }

      notifyListeners();
      return updatedAttendance;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAttendance(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _attendanceService.deleteAttendance(id);

      // Hapus dari list
      _attendances.removeWhere((a) => a.id == id);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
