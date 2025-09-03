import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rekap_presensi_controller.dart';

class DateSelector extends StatelessWidget {
  const DateSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RekapPresensiController>(
      builder: (context, controller, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Pilih Tanggal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F7836),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _selectDate(context, controller),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0F7836).withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: const Color(0xFF0F7836),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            controller.selectedDate != null
                                ? _formatDate(controller.selectedDate!)
                                : 'Pilih Tanggal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  controller.selectedDate != null
                                      ? Colors.black87
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: const Color(0xFF0F7836),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    RekapPresensiController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF0F7836),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0F7836),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != controller.selectedDate) {
      controller.setSelectedDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    // Format: Senin, 15 Juli 2024
    final days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final dayName = days[date.weekday % 7];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;

    return '$dayName, $day $month $year';
  }
}
