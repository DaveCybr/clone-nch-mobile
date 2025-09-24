import 'package:flutter/foundation.dart';

class ScheduleModel {
  final String id; // Changed from int to String to support UUID
  final String day;
  final String jamMulai;
  final String jamSelesai;
  final String mataPelajaran;
  final String kelas;
  final String kelasId; // Changed from int to String to support UUID
  final String subjectTeacherId; // Changed from int to String to support UUID
  final dynamic
  timeSlotId; // Added to support time slot ID (can be UUID or int)

  ScheduleModel({
    required this.id,
    required this.day,
    required this.jamMulai,
    required this.jamSelesai,
    required this.mataPelajaran,
    required this.kelas,
    required this.kelasId,
    required this.subjectTeacherId,
    this.timeSlotId,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('🔍 ScheduleModel.fromJson input: $json');

      final schedule = ScheduleModel(
        id: json['id']?.toString() ?? '0', // Convert to String to support UUID
        day: json['day'] ?? '',
        jamMulai: json['jam_mulai'] ?? '',
        jamSelesai: json['jam_selesai'] ?? '',
        mataPelajaran: json['mata_pelajaran'] ?? '',
        kelas: json['kelas'] ?? '',
        kelasId:
            json['kelas_id']?.toString() ??
            '0', // Convert to String to support UUID
        subjectTeacherId:
            json['subject_teacher_id']?.toString() ??
            '0', // Convert to String to support UUID
        timeSlotId: json['time_slot_id'], // Support both UUID string and int
      );

      debugPrint('🔍 ScheduleModel created successfully: $schedule');
      return schedule;
    } catch (e) {
      debugPrint('❌ Error in ScheduleModel.fromJson: $e');
      debugPrint('❌ Input data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day': day,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'mata_pelajaran': mataPelajaran,
      'kelas': kelas,
      'kelas_id': kelasId,
      'subject_teacher_id': subjectTeacherId,
      'time_slot_id': timeSlotId,
    };
  }

  @override
  String toString() {
    return 'ScheduleModel(id: $id, day: $day, time: $jamMulai-$jamSelesai, subject: $mataPelajaran, kelas: $kelas)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Helper method untuk mendapatkan hari dalam bahasa Indonesia
  String get dayInIndonesian {
    switch (day.toUpperCase()) {
      case 'MONDAY':
        return 'SENIN';
      case 'TUESDAY':
        return 'SELASA';
      case 'WEDNESDAY':
        return 'RABU';
      case 'THURSDAY':
        return 'KAMIS';
      case 'FRIDAY':
        return 'JUMAT';
      case 'SATURDAY':
        return 'SABTU';
      case 'SUNDAY':
        return 'MINGGU';
      default:
        return day;
    }
  }

  // Helper method untuk format waktu
  String get timeRange => '$jamMulai - $jamSelesai';
}
