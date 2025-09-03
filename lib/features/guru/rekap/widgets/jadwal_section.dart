import 'package:flutter/material.dart';
import '../controllers/rekap_controller.dart';
import '../models/schedule_model.dart';

class JadwalSection extends StatelessWidget {
  final RekapController controller;
  final Function(ScheduleModel)? onJadwalTap;

  const JadwalSection({super.key, required this.controller, this.onJadwalTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Jadwal ${controller.selectedMataPelajaran}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F7836),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              controller.isLoadingSchedules
                  ? _buildLoadingState()
                  : controller.scheduleErrorMessage != null
                  ? _buildErrorState(controller.scheduleErrorMessage!)
                  : controller.schedules.isEmpty
                  ? _buildEmptyState()
                  : _buildScheduleList(controller.schedules),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: const Color(0xFF0F7836)),
            const SizedBox(height: 16),
            Text(
              'Memuat jadwal...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat jadwal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.loadSchedulesForSelectedSubject(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F7836),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
              ),
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.schedule_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada jadwal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada jadwal untuk mata pelajaran ini',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(List<ScheduleModel> schedules) {
    return Column(
      children: [
        ...schedules.asMap().entries.map((entry) {
          final index = entry.key;
          final schedule = entry.value;

          return Column(
            children: [
              _buildScheduleItem(schedule),
              if (index < schedules.length - 1)
                Divider(
                  color: Colors.grey[200],
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildScheduleItem(ScheduleModel schedule) {
    return GestureDetector(
      onTap: () {
        if (onJadwalTap != null) {
          onJadwalTap!(schedule);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Day indicator
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF0F7836), const Color(0xFFB4CE46)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getShortDayName(schedule.day),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Schedule details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.day,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F7836),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${schedule.jamMulai} - ${schedule.jamSelesai}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.class_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          schedule.kelas,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Add tap indicator
              Icon(
                Icons.add_circle_outline,
                color: const Color(0xFF0F7836),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getShortDayName(String day) {
    switch (day.toUpperCase()) {
      case 'SENIN':
        return 'SEN';
      case 'SELASA':
        return 'SEL';
      case 'RABU':
        return 'RAB';
      case 'KAMIS':
        return 'KAM';
      case 'JUMAT':
        return 'JUM';
      case 'SABTU':
        return 'SAB';
      case 'MINGGU':
        return 'MIN';
      default:
        return day.substring(0, 3).toUpperCase();
    }
  }
}
