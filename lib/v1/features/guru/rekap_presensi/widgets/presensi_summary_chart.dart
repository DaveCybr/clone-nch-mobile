import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../controllers/rekap_presensi_controller.dart';

class PresensiSummaryChart extends StatelessWidget {
  const PresensiSummaryChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RekapPresensiController>(
      builder: (context, controller, child) {
        if (controller.presensiSummary == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                _buildLoadingCard(),
                const SizedBox(width: 16),
                _buildLoadingCard(),
                const SizedBox(width: 16),
                _buildLoadingCard(),
              ],
            ),
          );
        }

        final summary = controller.presensiSummary!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              _buildPresensiStatusCard(
                'Hadir',
                summary.totalHadir,
                summary.totalPresensi,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildPresensiStatusCard(
                'Sakit',
                summary.totalSakit,
                summary.totalPresensi,
                Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildPresensiStatusCard(
                'Izin',
                summary.totalIzin,
                summary.totalPresensi,
                Colors.yellow[700]!,
              ),
              const SizedBox(width: 16),
              _buildPresensiStatusCard(
                'Alpha',
                summary.totalAlpha,
                summary.totalPresensi,
                Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresensiStatusCard(
    String status,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? count / total : 0.0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            CircularPercentIndicator(
              radius: 30.0,
              lineWidth: 6.0,
              percent: percentage,
              center: Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
              progressColor: color,
              backgroundColor: color.withOpacity(0.2),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0F7836),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 25,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
