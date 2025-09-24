import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../core/services/base_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/koordinator_card.dart';
import '../widgets/rekap_card.dart';
import '../widgets/jadwal_section.dart';
import '../widgets/mata_pelajaran_sidebar.dart';
import '../controllers/rekap_controller.dart';
import '../models/schedule_model.dart';
import '../../tambah_presensi/screens/tambah_presensi_screen.dart';
import '../../rekap_presensi/screens/rekap_presensi_screen.dart';

class RekapScreen extends StatefulWidget {
  const RekapScreen({super.key});

  @override
  State<RekapScreen> createState() => _RekapScreenState();
}

class _RekapScreenState extends State<RekapScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late RekapController _rekapController;

  // Lifecycle management
  bool _isInitialized = false;
  bool _isDisposed = false;
  Timer? _refreshTimer;
  Timer? _healthCheckTimer;

  // Error recovery
  int _initRetryCount = 0;
  static const int _maxInitRetries = 3;

  // Loading timeout tracking
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    _initializeComponents();
    _initializeData();
  }

  void _initializeComponents() {
    if (_isDisposed) return;

    try {
      _rekapController = RekapController();

      _animationController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Error initializing components: $e');
      _showErrorAndRetry('Gagal menginisialisasi komponen');
    }
  }

  void _initializeData() {
    if (_isDisposed || !_isInitialized) return;

    // Use post frame callback to ensure widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _safeExecute(() => _rekapController.initialize());
      }
    });
  }

  // Safe execution wrapper
  Future<void> _safeExecute(Future<void> Function() operation) async {
    if (_isDisposed || !mounted) return;

    try {
      _lastRefreshTime = DateTime.now();
      await operation();
    } catch (e) {
      if (!_isDisposed && mounted) {
        debugPrint('❌ Safe execution error: $e');
        _handleError(e);
      }
    }
  }

  // Enhanced error handling
  void _handleError(dynamic error) {
    if (_isDisposed || !mounted) return;

    String errorMessage;
    if (error is NetworkException) {
      errorMessage = error.message;
    } else if (error is AuthenticationException) {
      errorMessage = 'Sesi berakhir, silakan login kembali';
      _handleAuthenticationError();
      return;
    } else if (error is TimeoutException) {
      errorMessage = 'Koneksi timeout, periksa jaringan Anda';
    } else {
      errorMessage = 'Terjadi kesalahan tidak terduga';
    }

    _showErrorSnackBar(errorMessage);
  }

  void _handleAuthenticationError() {
    // Navigate to login screen or show authentication dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Sesi Berakhir'),
            content: const Text('Silakan login kembali untuk melanjutkan.'),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false),
                child: const Text('Login'),
              ),
            ],
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (_isDisposed || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Coba Lagi',
          textColor: Colors.white,
          onPressed: () => _safeExecute(() => _rekapController.refresh()),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showErrorAndRetry(String message) {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Terjadi Kesalahan'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_initRetryCount < _maxInitRetries) {
                    _initRetryCount++;
                    _retryInitialization();
                  }
                },
                child: const Text('Coba Lagi'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _retryInitialization() {
    if (_isDisposed) return;

    Future.delayed(Duration(seconds: _initRetryCount), () {
      if (!_isDisposed && mounted) {
        _initializeData();
      }
    });
  }

  @override
  void didUpdateWidget(RekapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Refresh attendance stats when returning from other screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted && _rekapController.isInitialized) {
        _safeExecute(() => _rekapController.loadAttendanceStats());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_isDisposed) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // Refresh data when app comes back to foreground
        if (_isInitialized && mounted) {
          debugPrint('📱 App resumed, refreshing data...');
          _safeExecute(() => _rekapController.loadAttendanceStats());
        }
        break;
      case AppLifecycleState.paused:
        // Cancel any ongoing operations
        _refreshTimer?.cancel();
        debugPrint('📱 App paused');
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    debugPrint('🗑️ Disposing RekapScreen');
    _isDisposed = true;

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Cancel timers
    _refreshTimer?.cancel();
    _healthCheckTimer?.cancel();

    // Dispose controllers safely
    if (_isInitialized) {
      try {
        _animationController.dispose();
        _rekapController.dispose();
      } catch (e) {
        debugPrint('⚠️ Error disposing controllers: $e');
      }
    }

    super.dispose();
  }

  void _openMataPelajaranSidebar() {
    if (_isDisposed || !mounted) return;

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: MataPelajaranSidebar(
              controller: _rekapController,
              onMataPelajaranSelected: (mapel) {
                if (!_isDisposed && mounted) {
                  _rekapController.setSelectedMataPelajaran(mapel);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTambahDataDialog([ScheduleModel? selectedSchedule]) async {
    if (_isDisposed || !mounted) return;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Jenis Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F7836),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTambahDataButton(
                  label: 'Tambah Tugas',
                  onPressed: () {
                    Navigator.pop(context);
                    _showComingSoonSnackBar('Fitur Tambah Tugas');
                  },
                  isDisabled: true,
                ),
                const SizedBox(height: 16),
                _buildTambahDataButton(
                  label: 'Tambah Presensi',
                  onPressed:
                      () => _handleTambahPresensi(context, selectedSchedule),
                ),
                const SizedBox(height: 16),
                _buildTambahDataButton(
                  label: 'Tambah Ujian',
                  onPressed: () {
                    Navigator.pop(context);
                    _showComingSoonSnackBar('Fitur Tambah Ujian');
                  },
                  isDisabled: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoonSnackBar(String feature) {
    if (_isDisposed || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan segera tersedia'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleTambahPresensi(
    BuildContext context,
    ScheduleModel? selectedSchedule,
  ) async {
    Navigator.pop(context);

    if (_isDisposed || !mounted) return;

    try {
      final selectedSubject = _rekapController.selectedSubjectModel;

      // Determine class ID and schedule info
      final ScheduleModel? scheduleToUse =
          selectedSchedule ??
          (_rekapController.schedules.isNotEmpty
              ? _rekapController.schedules.first as ScheduleModel
              : null);

      String? preselectedKelasId = scheduleToUse?.kelasId;

      // Fallback logic for class ID mapping
      if (preselectedKelasId == null || preselectedKelasId == '0') {
        if (selectedSubject != null) {
          preselectedKelasId = _mapKelasNameToId(selectedSubject.kelasName);
        }
      }

      final result = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
          builder:
              (context) => TambahPresensiScreen(
                preselectedKelas: preselectedKelasId,
                preselectedMataPelajaran: selectedSubject?.mataPelajaran,
                subjectId: selectedSubject?.id,
                scheduleInfo:
                    scheduleToUse != null
                        ? '${scheduleToUse.day}, ${scheduleToUse.jamMulai} - ${scheduleToUse.jamSelesai}'
                        : null,
                selectedSchedule: scheduleToUse,
              ),
        ),
      );

      // Refresh stats after returning
      if (!_isDisposed && mounted && result == null) {
        await _safeExecute(() => _rekapController.loadAttendanceStats());
      }
    } catch (e) {
      debugPrint('❌ Error handling tambah presensi: $e');
      _handleError(e);
    }
  }

  String? _mapKelasNameToId(String? kelasName) {
    if (kelasName == null) return null;

    final normalizedName = kelasName.trim().toLowerCase();

    switch (normalizedName) {
      case "toddler":
        return "0198c546-cae8-70b0-8446-01b7d13bc619";
      case "playgroup":
        return "0198c546-caed-71c5-b1c8-8e9a96a09d7c";
      case "kindergarten 1":
        return "0198c546-caf1-706a-9f72-e0579219b292";
      case "kindergarten 2":
        return "0198c546-caf7-713a-8f6a-0dfbecc80624";
      case "elementary school":
        return "0198c546-cafc-718d-96a0-fd88a0d46598";
      case "junior high school":
        return "0198c546-cb01-700c-b506-43ec4cf8b7e4";
      case "senior high school":
        return "0198c546-cb06-7145-b2cb-407a8fe77554";
      default:
        return null;
    }
  }

  Widget _buildTambahDataButton({
    required String label,
    required VoidCallback onPressed,
    bool isDisabled = false,
  }) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? Colors.grey[300] : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: StadiumBorder(
          side: BorderSide(
            color: isDisabled ? Colors.grey[400]! : const Color(0xFF0F7836),
            width: 2,
          ),
        ),
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDisabled ? Colors.grey[600] : const Color(0xFF0F7836),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isDisabled) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Coming Soon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleRekapPresensiTap() async {
    if (_isDisposed || !mounted) return;

    try {
      final selectedSubject = _rekapController.selectedSubjectModel;

      String? kelasName;
      String? kelasId;
      dynamic timeSlotId;

      if (_rekapController.schedules.isNotEmpty) {
        final firstSchedule = _rekapController.schedules.first;
        kelasName = firstSchedule.kelas;
        kelasId = firstSchedule.kelasId;
        timeSlotId = firstSchedule.timeSlotId;
      } else if (selectedSubject != null) {
        kelasName = selectedSubject.kelasName;
        kelasId = _mapKelasNameToId(selectedSubject.kelasName);
      }

      debugPrint('🔍 Navigating to RekapPresensiPage with:');
      debugPrint('   - kelasId: $kelasId');
      debugPrint('   - kelasName: $kelasName');
      debugPrint('   - subjectId: ${selectedSubject?.id}');
      debugPrint('   - subjectName: ${selectedSubject?.mataPelajaran}');
      debugPrint('   - timeSlotId: $timeSlotId');

      final result = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
          builder:
              (context) => RekapPresensiPage(
                kelasId: kelasId,
                subjectId: selectedSubject?.id,
                subjectName: selectedSubject?.mataPelajaran,
                kelasName: kelasName,
                teacherName: _rekapController.teacherName,
                teacherId: _rekapController.teacherInfo?.id,
                timeSlotId: timeSlotId,
              ),
        ),
      );

      // Refresh stats when returning
      if (!_isDisposed && mounted && result == null) {
        await _safeExecute(() => _rekapController.loadAttendanceStats());
      }
    } catch (e) {
      debugPrint('❌ Error handling rekap presensi tap: $e');
      _handleError(e);
    }
  }

  // Check if loading has been stuck for too long
  bool _isLoadingStuck() {
    if (!_rekapController.isLoadingAttendanceStats) return false;
    if (_lastRefreshTime == null) return false;

    final elapsed = DateTime.now().difference(_lastRefreshTime!);
    return elapsed > const Duration(seconds: 45);
  }

  @override
  Widget build(BuildContext context) {
    // Early return if disposed
    if (_isDisposed) {
      return const Scaffold(body: Center(child: Text('Screen disposed')));
    }

    // Check if components are initialized
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0FFF5),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF0F7836)),
              SizedBox(height: 16),
              Text('Memuat komponen...'),
            ],
          ),
        ),
      );
    }

    return ChangeNotifierProvider<RekapController>.value(
      value: _rekapController,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FFF5),
        body: SafeArea(
          child: Consumer<RekapController>(
            builder: (context, controller, child) {
              // Show critical error only if not initialized and not loading
              if (controller.errorMessage != null &&
                  !controller.isInitialized &&
                  !controller.isLoading) {
                return _buildErrorScreen(controller);
              }

              // Show loading for initial load
              if (controller.isLoading && !controller.isInitialized) {
                return _buildLoadingScreen();
              }

              // Main content
              return RefreshIndicator(
                onRefresh: () => _safeExecute(() => controller.refresh()),
                color: const Color(0xFF0F7836),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomAppBar(
                          onOpenMataPelajaranSidebar: _openMataPelajaranSidebar,
                        ),
                        const SizedBox(height: 24),
                        KoordinatorCard(controller: controller),
                        const SizedBox(height: 24),
                        _buildRekapCards(controller),
                        const SizedBox(height: 24),
                        if (controller.selectedMataPelajaran.isNotEmpty)
                          JadwalSection(
                            controller: controller,
                            onJadwalTap: (ScheduleModel selectedSchedule) {
                              _showTambahDataDialog(selectedSchedule);
                            },
                          ),
                        const SizedBox(height: 40),

                        // Debug info in development mode
                        if (kDebugMode) _buildDebugInfo(controller),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF0F7836)),
          SizedBox(height: 16),
          Text(
            'Memuat data...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(RekapController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage ?? 'Kesalahan tidak diketahui',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.red[600]),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _safeExecute(() => controller.refresh()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F7836),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Coba Lagi'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F7836),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRekapCards(RekapController controller) {
    // Determine if loading is stuck
    final bool isLoadingStuck = _isLoadingStuck();
    final bool showLoading =
        controller.isLoadingAttendanceStats && !isLoadingStuck;

    return Row(
      children: [
        RekapCard(
          value: '0',
          label: 'Tugas',
          type: 'tugas',
          isLoading: false,
          isDisabled: true,
          comingSoonLabel: 'Coming Soon',
          onTap: null,
        ),
        const SizedBox(width: 16),
        RekapCard(
          value: showLoading ? '...' : controller.totalPresensiDisplay,
          label: 'Presensi',
          type: 'presensi',
          isLoading: showLoading,
          onTap: isLoadingStuck ? null : _handleRekapPresensiTap,
        ),
        const SizedBox(width: 16),
        RekapCard(
          value: '0',
          label: 'Ujian',
          type: 'ujian',
          isLoading: false,
          isDisabled: true,
          comingSoonLabel: 'Coming Soon',
          onTap: null,
        ),
      ],
    );
  }

  // Debug information widget (only shown in debug mode)
  Widget _buildDebugInfo(RekapController controller) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Info',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Initialized: ${controller.isInitialized}',
            style: _debugTextStyle,
          ),
          Text('Loading: ${controller.isLoading}', style: _debugTextStyle),
          Text(
            'Loading Attendance: ${controller.isLoadingAttendanceStats}',
            style: _debugTextStyle,
          ),
          Text('Loading Stuck: ${_isLoadingStuck()}', style: _debugTextStyle),
          Text(
            'Selected Subject: ${controller.selectedMataPelajaran}',
            style: _debugTextStyle,
          ),
          Text(
            'Subjects Count: ${controller.subjects.length}',
            style: _debugTextStyle,
          ),
          Text(
            'Schedules Count: ${controller.schedules.length}',
            style: _debugTextStyle,
          ),
          Text(
            'Error: ${controller.errorMessage ?? 'None'}',
            style: _debugTextStyle,
          ),
          if (_lastRefreshTime != null)
            Text(
              'Last Refresh: ${_formatTime(_lastRefreshTime!)}',
              style: _debugTextStyle,
            ),
        ],
      ),
    );
  }

  TextStyle get _debugTextStyle =>
      TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'monospace');

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
