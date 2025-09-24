import 'package:flutter/material.dart';
import 'dart:async';
import '../services/rekap_service.dart';
import '../models/teacher_info_model.dart';
import '../models/schedule_model.dart' as schedule;
// import '../models/schedule_model.dart';

class RekapController extends ChangeNotifier {
  final RekapService _rekapService = RekapService();

  // Disposal management
  bool _disposed = false;
  Timer? _refreshTimer;
  Timer? _loadingTimeoutTimer;
  final List<StreamSubscription> _subscriptions = [];

  // State variables
  TeacherInfoModel? _teacherInfo;
  List<SubjectInfoModel> _subjects = [];
  List<schedule.ScheduleModel> _schedules = [];
  String _selectedMataPelajaran = '';
  Map<String, int> _attendanceStats = {};

  // Loading states
  bool _isLoading = false;
  bool _isLoadingSchedules = false;
  bool _isLoadingAttendanceStats = true;
  bool _isInitialized = false;

  // Loading timeout tracking
  DateTime? _attendanceLoadingStartTime;
  static const Duration _loadingTimeoutDuration = Duration(seconds: 30);

  // Error states
  String? _errorMessage;
  String? _scheduleErrorMessage;

  // Retry mechanism
  int _retryCount = 0;
  static const int _maxRetries = 3;

  // Getters with null safety
  TeacherInfoModel? get teacherInfo => _disposed ? null : _teacherInfo;
  List<SubjectInfoModel> get subjects =>
      _disposed ? [] : List.unmodifiable(_subjects);
  List<schedule.ScheduleModel> get schedules =>
      _disposed ? [] : List.unmodifiable(_schedules);
  String get selectedMataPelajaran => _disposed ? '' : _selectedMataPelajaran;
  Map<String, int> get attendanceStats =>
      _disposed ? {} : Map.unmodifiable(_attendanceStats);

  // Status getters
  bool get isLoading => _disposed ? false : _isLoading;
  bool get isLoadingSchedules => _disposed ? false : _isLoadingSchedules;
  bool get isLoadingAttendanceStats {
    if (_disposed) return false;

    // Check for timeout
    if (_isLoadingAttendanceStats && _attendanceLoadingStartTime != null) {
      final elapsed = DateTime.now().difference(_attendanceLoadingStartTime!);
      if (elapsed > _loadingTimeoutDuration) {
        debugPrint('⏰ Attendance loading timeout detected, forcing stop');
        _forceStopAttendanceLoading();
        return false;
      }
    }

    return _isLoadingAttendanceStats;
  }

  bool get isInitialized => _disposed ? false : _isInitialized;
  bool get isDisposed => _disposed;

  // Error getters
  String? get errorMessage => _disposed ? null : _errorMessage;
  String? get scheduleErrorMessage => _disposed ? null : _scheduleErrorMessage;

  // Safe getters for UI
  String get teacherName {
    if (_disposed || _teacherInfo == null) return 'Nama Tidak Tersedia';
    return _teacherInfo!.name;
  }

  String get teacherRole {
    if (_disposed || _teacherInfo == null) return 'Staff';
    return _teacherInfo!.roleDisplayName;
  }

  List<String> get subjectDisplayNames {
    if (_disposed) return [];
    return _subjects.map((subject) => subject.displayName).toList();
  }

  String get totalPresensiDisplay {
    if (_disposed) return '0';
    final total = _attendanceStats['total_presensi'] ?? 0;
    return total.toString();
  }

  // Detail statistics getters
  int get totalHadir => _disposed ? 0 : (_attendanceStats['hadir'] ?? 0);
  int get totalSakit => _disposed ? 0 : (_attendanceStats['sakit'] ?? 0);
  int get totalIzin => _disposed ? 0 : (_attendanceStats['izin'] ?? 0);
  int get totalAlpha => _disposed ? 0 : (_attendanceStats['alpha'] ?? 0);

  // Force stop attendance loading (timeout handler)
  void _forceStopAttendanceLoading() {
    if (_disposed) return;

    debugPrint('🔄 Force stopping attendance loading due to timeout');
    _isLoadingAttendanceStats = false;
    _attendanceLoadingStartTime = null;
    _loadingTimeoutTimer?.cancel();

    // Set empty stats if no data
    if (_attendanceStats.isEmpty) {
      _setEmptyAttendanceStats(notify: false);
    }

    _safeNotifyListeners();
  }

  // Enhanced notification method with disposal check
  @override
  void notifyListeners() {
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_disposed && hasListeners) {
      try {
        super.notifyListeners();
      } catch (e) {
        debugPrint('⚠️ Error notifying listeners: $e');
      }
    }
  }

  // Initialize controller with proper error handling
  Future<void> initialize() async {
    if (_disposed || _isInitialized) return;

    await _safeExecute(() async {
      _setLoadingState(true);
      _clearErrors();

      try {
        await _loadTeacherInfo();
        await _loadSubjects();

        _isInitialized = true;
        _setLoadingState(false);

        // Load additional data asynchronously
        if (_subjects.isNotEmpty) {
          _selectedMataPelajaran = _subjects.first.displayName;
          unawaited(_loadAdditionalDataAsync());
        } else {
          // No subjects, stop loading attendance stats
          _setEmptyAttendanceStats();
        }

        _retryCount = 0; // Reset retry count on success
      } catch (e) {
        _handleError('Gagal menginisialisasi data: $e', e);
        _setLoadingState(false);

        // Implement retry logic
        if (_retryCount < _maxRetries) {
          _retryCount++;
          debugPrint(
            '🔄 Retrying initialization (attempt $_retryCount/$_maxRetries)',
          );
          await Future.delayed(Duration(seconds: _retryCount * 2));
          return initialize(); // Recursive retry
        } else {
          // Max retries reached, set empty stats
          _setEmptyAttendanceStats();
        }
      }
    });
  }

  // Safe execution wrapper
  Future<T?> _safeExecute<T>(Future<T> Function() operation) async {
    if (_disposed) return null;

    try {
      return await operation();
    } catch (e) {
      if (!_disposed) {
        debugPrint('❌ Safe execution error: $e');
      }
      return null;
    }
  }

  // Load additional data asynchronously with proper error handling
  Future<void> _loadAdditionalDataAsync() async {
    if (_disposed) return;

    await _safeExecute(() async {
      try {
        await Future.wait([
          loadSchedulesForSelectedSubject(),
          loadAttendanceStats(),
        ]).timeout(
          const Duration(seconds: 45),
          onTimeout: () {
            debugPrint('⏰ Additional data loading timeout');
            if (!_disposed) {
              _setAttendanceLoadingState(false);
              _setScheduleLoadingState(false);
              _setEmptyAttendanceStats(notify: false);
            }
            return <void>[]; // Ensure a non-null List<void> is returned
          },
        );
      } catch (e) {
        debugPrint('❌ Error loading additional data: $e');
        if (!_disposed) {
          _setAttendanceLoadingState(false);
          _setScheduleLoadingState(false);
          _setEmptyAttendanceStats(notify: false);
        }
      }
    });
  }

  // Enhanced teacher info loading with timeout
  Future<void> _loadTeacherInfo() async {
    if (_disposed) return;

    debugPrint('🔍 Loading teacher info...');

    final teacherInfo = await _rekapService.getTeacherInfo().timeout(
      const Duration(seconds: 30),
    );

    if (!_disposed) {
      _teacherInfo = teacherInfo;
      debugPrint('✅ Teacher info loaded: ${_teacherInfo?.name}');
    }
  }

  // Enhanced subjects loading
  Future<void> _loadSubjects() async {
    if (_disposed || _teacherInfo == null) return;

    debugPrint('🔍 Loading subjects for teacher ID: ${_teacherInfo!.id}');

    final subjects = await _rekapService
        .getSubjectsWithClassInfo(_teacherInfo!.id)
        .timeout(const Duration(seconds: 15));

    if (!_disposed) {
      _subjects = subjects;
      debugPrint('✅ Subjects loaded: ${_subjects.length} items');
    }
  }

  // Enhanced subject selection with timeout protection
  void setSelectedMataPelajaran(String mataPelajaran) {
    if (_disposed || _selectedMataPelajaran == mataPelajaran) return;

    _selectedMataPelajaran = mataPelajaran;
    _safeNotifyListeners();

    // Start loading attendance stats
    _setAttendanceLoadingState(true);

    // Load related data asynchronously with timeout
    unawaited(
      _safeExecute(() async {
        try {
          await Future.wait([
            loadSchedulesForSelectedSubject(),
            loadAttendanceStats(),
          ]).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('⏰ Subject selection data loading timeout');
              if (!_disposed) {
                _setAttendanceLoadingState(false);
                _setScheduleLoadingState(false);
                _setEmptyAttendanceStats(notify: false);
              }
              return <void>[];
            },
          );
        } catch (e) {
          debugPrint('❌ Error in setSelectedMataPelajaran: $e');
          if (!_disposed) {
            _setAttendanceLoadingState(false);
            _setScheduleLoadingState(false);
            _setEmptyAttendanceStats(notify: false);
          }
        }
      }),
    );
  }

  // Enhanced schedule loading
  Future<void> loadSchedulesForSelectedSubject() async {
    if (_disposed || _selectedMataPelajaran.isEmpty || _teacherInfo == null)
      return;

    await _safeExecute(() async {
      _setScheduleLoadingState(true);
      _scheduleErrorMessage = null;

      try {
        final selectedSubject =
            _subjects
                .where(
                  (subject) => subject.displayName == _selectedMataPelajaran,
                )
                .firstOrNull;

        if (selectedSubject == null) {
          throw Exception('Subject tidak ditemukan');
        }

        debugPrint(
          '🔍 Loading schedules for subject: ${selectedSubject.displayName}',
        );

        final schedules = await _rekapService
            .getSchedulesForSubject(selectedSubject.id)
            .timeout(const Duration(seconds: 30));

        if (!_disposed) {
          _schedules = schedules;
          debugPrint('✅ Loaded ${_schedules.length} schedules');
        }
      } catch (e) {
        _handleScheduleError('Gagal memuat jadwal: $e', e);
      } finally {
        _setScheduleLoadingState(false);
      }
    });
  }

  // FIXED: Enhanced attendance stats loading dengan proper state management
  Future<void> loadAttendanceStats() async {
    // Early validation tanpa set loading state dulu
    if (_disposed) {
      debugPrint('⚠️ Controller disposed, skipping attendance stats');
      return;
    }

    if (_teacherInfo == null) {
      debugPrint('⚠️ Teacher info not available, setting empty stats');
      _setEmptyAttendanceStats();
      return;
    }

    final selectedSubject = selectedSubjectModel;
    if (selectedSubject == null) {
      debugPrint('⚠️ No subject selected, setting empty stats');
      _setEmptyAttendanceStats();
      return;
    }

    // Set loading state hanya setelah validasi berhasil
    _setAttendanceLoadingState(true);

    try {
      debugPrint(
        '🔍 Loading attendance stats for subject: ${selectedSubject.mataPelajaran}',
      );

      // Add timeout to prevent hanging
      final statsResult = await _rekapService
          .getAttendanceStats(
            teacherId: _teacherInfo!.id,
            subjectId: selectedSubject.id,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('⏰ Attendance stats request timeout');
              return <String, int>{
                'total_presensi': 0,
                'hadir': 0,
                'sakit': 0,
                'izin': 0,
                'alpha': 0,
              };
            },
          );

      if (!_disposed) {
        _attendanceStats = statsResult;
        debugPrint('✅ Attendance stats loaded: $_attendanceStats');
      }
    } catch (e) {
      debugPrint('❌ Error loading attendance stats: $e');

      if (!_disposed) {
        // Set default values on error (graceful degradation)
        _attendanceStats = {
          'total_presensi': 0,
          'hadir': 0,
          'sakit': 0,
          'izin': 0,
          'alpha': 0,
        };
      }
    } finally {
      // ALWAYS reset loading state di finally block
      if (!_disposed) {
        _setAttendanceLoadingState(false);
      }
    }
  }

  // Helper method untuk set empty stats
  void _setEmptyAttendanceStats({bool notify = true}) {
    if (_disposed) return;

    _attendanceStats = {
      'total_presensi': 0,
      'hadir': 0,
      'sakit': 0,
      'izin': 0,
      'alpha': 0,
    };
    _setAttendanceLoadingState(false, notify: notify);
  }

  // Enhanced refresh method
  Future<void> refresh() async {
    if (_disposed) return;

    await _safeExecute(() async {
      _setLoadingState(true);
      _clearErrors();
      _retryCount = 0;

      try {
        await _loadTeacherInfo();
        print('done');
        await _loadSubjects();

        // Reset selected mata pelajaran if not available in new list
        if (_subjects.isNotEmpty &&
            !_subjects.any((s) => s.displayName == _selectedMataPelajaran)) {
          _selectedMataPelajaran = _subjects.first.displayName;
        }

        // Reload related data with timeout
        if (_selectedMataPelajaran.isNotEmpty) {
          unawaited(_loadAdditionalDataAsync());
        } else {
          _setEmptyAttendanceStats();
        }
      } catch (e) {
        _handleError('Gagal memperbarui data: $e', e);
        _setEmptyAttendanceStats();
      } finally {
        _setLoadingState(false);
      }
    });
  }

  // Enhanced helper methods for state management
  void _setLoadingState(bool loading) {
    if (_disposed) return;
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setScheduleLoadingState(bool loading) {
    if (_disposed) return;
    _isLoadingSchedules = loading;
    _safeNotifyListeners();
  }

  void _setAttendanceLoadingState(bool loading, {bool notify = true}) {
    if (_disposed) return;

    _isLoadingAttendanceStats = loading;

    if (loading) {
      _attendanceLoadingStartTime = DateTime.now();
      // Set timeout timer
      _loadingTimeoutTimer?.cancel();
      _loadingTimeoutTimer = Timer(_loadingTimeoutDuration, () {
        if (!_disposed && _isLoadingAttendanceStats) {
          debugPrint('⏰ Attendance loading timeout timer triggered');
          _forceStopAttendanceLoading();
        }
      });
    } else {
      _attendanceLoadingStartTime = null;
      _loadingTimeoutTimer?.cancel();
    }

    if (notify) {
      _safeNotifyListeners();
    }
  }

  void _clearErrors() {
    if (_disposed) return;
    _errorMessage = null;
    _scheduleErrorMessage = null;
  }

  void _handleError(String message, dynamic error) {
    if (_disposed) return;
    _errorMessage = message;
    debugPrint('❌ Error in RekapController: $error');
    _safeNotifyListeners();
  }

  void _handleScheduleError(String message, dynamic error) {
    if (_disposed) return;
    _scheduleErrorMessage = message;
    debugPrint('❌ Schedule error in RekapController: $error');
    _safeNotifyListeners();
  }

  // Clear all data
  void clear() {
    if (_disposed) return;

    _teacherInfo = null;
    _subjects.clear();
    _schedules.clear();
    _attendanceStats.clear();
    _selectedMataPelajaran = '';
    _isInitialized = false;
    _setAttendanceLoadingState(false, notify: false);
    _clearErrors();
    _safeNotifyListeners();
  }

  // Get current selected subject model
  SubjectInfoModel? get selectedSubjectModel {
    if (_disposed) return null;

    try {
      return _subjects
          .where((subject) => subject.displayName == _selectedMataPelajaran)
          .firstOrNull;
    } catch (e) {
      debugPrint('❌ Error getting selected subject model: $e');
      return null;
    }
  }

  // Enhanced disposal
  @override
  void dispose() {
    if (_disposed) return;

    debugPrint('🗑️ Disposing RekapController');
    _disposed = true;

    // Cancel timers
    _refreshTimer?.cancel();
    _loadingTimeoutTimer?.cancel();

    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Dispose service
    _rekapService.dispose();

    super.dispose();
  }

  // Utility method to safely ignore futures
  void unawaited(Future<void> future) {
    future.catchError((error) {
      debugPrint('⚠️ Unawaited future error: $error');
    });
  }
}

// Extension for firstOrNull (if not available in your Dart version)
extension IterableExtension<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
