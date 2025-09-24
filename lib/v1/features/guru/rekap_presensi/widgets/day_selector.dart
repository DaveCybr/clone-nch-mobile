import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rekap_presensi_controller.dart';

class DaySelector extends StatelessWidget {
  const DaySelector({super.key});

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
                  'Pilih Hari',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F7836),
                  ),
                ),
              ),
              Container(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.availableDays.length,
                  itemBuilder: (context, index) {
                    final day = controller.availableDays[index];
                    final isSelected = controller.selectedDay == day;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          // Instead of calling setSelectedDay, create a new date with the selected day
                          final currentDate =
                              controller.selectedDate ?? DateTime.now();
                          final targetDay = _getDayIndex(day);
                          final currentDay = currentDate.weekday % 7;
                          final dayDifference = targetDay - currentDay;

                          final newDate = currentDate.add(
                            Duration(days: dayDifference),
                          );
                          controller.setSelectedDate(newDate);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xFF0F7836)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF0F7836),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _getDayDisplayName(day),
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : const Color(0xFF0F7836),
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDayDisplayName(String day) {
    switch (day) {
      case 'SENIN':
        return 'Senin';
      case 'SELASA':
        return 'Selasa';
      case 'RABU':
        return 'Rabu';
      case 'KAMIS':
        return 'Kamis';
      case 'JUMAT':
        return 'Jumat';
      case 'SABTU':
        return 'Sabtu';
      case 'MINGGU':
        return 'Minggu';
      default:
        return day;
    }
  }

  int _getDayIndex(String day) {
    switch (day) {
      case 'MINGGU':
        return 0;
      case 'SENIN':
        return 1;
      case 'SELASA':
        return 2;
      case 'RABU':
        return 3;
      case 'KAMIS':
        return 4;
      case 'JUMAT':
        return 5;
      case 'SABTU':
        return 6;
      default:
        return 1; // Default to Monday
    }
  }
}
