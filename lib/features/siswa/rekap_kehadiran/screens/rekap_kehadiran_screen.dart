import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class RekapKehadiranScreen extends StatefulWidget {
  const RekapKehadiranScreen({super.key});

  @override
  State<RekapKehadiranScreen> createState() => _RekapKehadiranScreenState();
}

class _RekapKehadiranScreenState extends State<RekapKehadiranScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<AttendanceModel> _attendanceList = [];
  Map<String, int> _attendanceSummary = {};
  double _attendancePercentage = 0.0;
  bool _isLoading = true;
  String? _studentId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _studentId = prefs.getString('student_id_uuid');

      print('📊 Loading attendance for student: $_studentId');

      await _fetchAttendanceData();
    } catch (e) {
      print('❌ Error loading student data: $e');
      setState(() {
        _errorMessage = 'Gagal memuat data siswa: $e';
        _attendanceList = [];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchAttendanceData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final attendanceList = await _attendanceService.getStudentAttendance();
      _attendanceList = attendanceList;
      _calculateSummary();
    } catch (e) {
      print('❌ Error fetching attendance: $e');
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _attendanceList = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateSummary() {
    _attendanceSummary = {'HADIR': 0, 'SAKIT': 0, 'IZIN': 0, 'ALPHA': 0};

    for (var attendance in _attendanceList) {
      String status = attendance.status.toUpperCase();
      _attendanceSummary[status] = (_attendanceSummary[status] ?? 0) + 1;
    }

    // Hitung persentase kehadiran (hadir saja)
    int totalHadir = _attendanceSummary['HADIR'] ?? 0;
    int totalHari = _attendanceList.length;

    if (totalHari > 0) {
      _attendancePercentage = (totalHadir / totalHari) * 100;
    } else {
      _attendancePercentage = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF5),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar - mengikuti style teacher
            _buildCustomAppBar(),

            // Content
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0F7836),
                        ),
                      )
                      : _errorMessage != null
                      ? _buildErrorState()
                      : _attendanceList.isEmpty
                      ? _buildEmptyState()
                      : _buildContentState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F7836).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F7836),
                size: 24,
              ),
            ),
          ),
          const Text(
            'Rekap Kehadiran',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F7836),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F7836),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Siswa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return RefreshIndicator(
      onRefresh: _loadStudentData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Informasi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _loadStudentData,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Coba Lagi',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7836),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadStudentData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F7836).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: Color(0xFF0F7836),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum Ada Data Kehadiran',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Data kehadiran belum tersedia di sistem.\nFitur ini akan aktif setelah guru mulai mencatat kehadiran siswa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _loadStudentData,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Periksa Ulang',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7836),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentState() {
    return RefreshIndicator(
      onRefresh: _loadStudentData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Card - mengikuti style teacher
            _buildStudentInfoCard(),
            const SizedBox(height: 16),

            // Summary Card dengan style teacher
            _buildSummaryCard(),
            const SizedBox(height: 16),

            // Statistics Grid dengan style teacher
            _buildStatisticsGrid(),
            const SizedBox(height: 16),

            // Attendance List dengan style teacher
            _buildAttendanceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F7836).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF0F7836),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rekap Kehadiran Siswa',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _studentId != null
                          ? 'ID: ${_studentId!.substring(0, 8)}...'
                          : 'Tidak tersedia',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F7836),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F7836).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF0F7836),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menampilkan data kehadiran untuk 30 hari terakhir',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF0F7836),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F7836), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Persentase Kehadiran',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_attendanceList.length} hari',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_attendancePercentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(
                _attendancePercentage >= 80
                    ? Icons.trending_up
                    : _attendancePercentage >= 60
                    ? Icons.trending_flat
                    : Icons.trending_down,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _attendancePercentage / 100,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Kehadiran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F7836),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                'Hadir',
                _attendanceSummary['HADIR'] ?? 0,
                const Color(0xFF0F7836),
                Icons.check_circle,
              ),
              _buildStatItem(
                'Sakit',
                _attendanceSummary['SAKIT'] ?? 0,
                Colors.orange,
                Icons.local_hospital,
              ),
              _buildStatItem(
                'Izin',
                _attendanceSummary['IZIN'] ?? 0,
                Colors.blue,
                Icons.assignment,
              ),
              _buildStatItem(
                'Alpha',
                _attendanceSummary['ALPHA'] ?? 0,
                Colors.red,
                Icons.cancel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Kehadiran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F7836),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F7836).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_attendanceList.length} records',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0F7836),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_attendanceList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada data kehadiran',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attendanceList.length,
              separatorBuilder:
                  (context, index) => Divider(
                    color: Colors.grey[200],
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
              itemBuilder: (context, index) {
                return _buildAttendanceItem(_attendanceList[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(AttendanceModel attendance) {
    final dateTime = attendance.dateTime;
    final dayName = dateTime != null ? _getDayName(dateTime.weekday) : '';
    final formattedDate =
        dateTime != null
            ? '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}'
            : attendance.date;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Date Circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor(attendance.status).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getStatusColor(attendance.status).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                dateTime?.day.toString() ?? '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(attendance.status),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Date and Subject Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayName, $formattedDate',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                if (attendance.subject != null)
                  Text(
                    '${attendance.subject} • ${attendance.teacherName ?? 'Guru tidak diketahui'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                if (attendance.note != null && attendance.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      attendance.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(attendance.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attendance.statusEmoji,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  attendance.statusDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return weekday <= days.length ? days[weekday - 1] : '';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return const Color(0xFF0F7836);
      case 'sakit':
        return Colors.orange;
      case 'izin':
        return Colors.blue;
      case 'alpha':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
