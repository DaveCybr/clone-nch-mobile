class AttendanceRecordModel {
  final dynamic id; // Changed to dynamic to support UUID
  final dynamic scheduleId; // Changed to dynamic to support UUID
  final dynamic studentId; // Changed to dynamic to support UUID
  final String status;
  final String? notes;
  final String attendanceDate;
  final StudentModel student;
  final ScheduleModel? schedule;

  AttendanceRecordModel({
    required this.id,
    required this.scheduleId,
    required this.studentId,
    required this.status,
    this.notes,
    required this.attendanceDate,
    required this.student,
    this.schedule,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'], // Keep as dynamic to support both int and String UUID
      scheduleId:
          json['schedule_id'], // Keep as dynamic to support both int and String UUID
      studentId:
          json['student_id'], // Keep as dynamic to support both int and String UUID
      status: json['status'],
      notes: json['notes'],
      attendanceDate: json['attendance_date'],
      student: StudentModel.fromJson(json['student'] ?? {}),
      schedule:
          json['schedule'] != null
              ? ScheduleModel.fromJson(json['schedule'])
              : null,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'HADIR':
        return 'Hadir';
      case 'SAKIT':
        return 'Sakit';
      case 'IZIN':
        return 'Izin';
      case 'ALPHA':
        return 'Alpha';
      case 'belum_diambil':
        return 'Belum Diambil';
      default:
        return status;
    }
  }
}

class StudentModel {
  final dynamic id; // Changed to dynamic to support UUID
  final dynamic userId; // Changed to dynamic to support UUID
  final dynamic kelasId; // Changed to dynamic to support UUID
  final String nim;
  final int generation;
  final UserModel user;

  StudentModel({
    required this.id,
    required this.userId,
    required this.kelasId,
    required this.nim,
    required this.generation,
    required this.user,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'], // Keep as dynamic to support both int and String UUID
      userId:
          json['user_id'] ??
          json['id'], // Keep as dynamic to support both int and String UUID
      kelasId:
          json['kelas_id'], // Keep as dynamic to support both int and String UUID
      nim:
          json['nisn']?.toString() ??
          json['nim']?.toString() ??
          '', // Handle both nisn and nim fields
      generation: json['generation'] ?? 1,
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}

class UserModel {
  final dynamic id; // Changed to dynamic to support UUID
  final String name;
  final String email;
  final String? gender;
  final String? religion;
  final String? birthPlace;
  final String? birthDate;
  final String? phoneNumber;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.gender,
    this.religion,
    this.birthPlace,
    this.birthDate,
    this.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'], // Keep as dynamic to support both int and String UUID
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'],
      religion: json['religion'],
      birthPlace: json['birth_place'],
      birthDate: json['birth_date'],
      phoneNumber: json['phone_number'],
    );
  }
}

class ScheduleModel {
  final String id; // Changed from int to String to support UUID
  final String subjectTeacherId; // Changed from int to String to support UUID
  final String day;
  final dynamic timeSlotId; // Changed to dynamic to support UUID

  ScheduleModel({
    required this.id,
    required this.subjectTeacherId,
    required this.day,
    this.timeSlotId,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id']?.toString() ?? '0', // Convert to String to support UUID
      subjectTeacherId:
          json['subject_teacher_id']?.toString() ??
          '0', // Convert to String to support UUID
      day: json['day'] ?? '',
      timeSlotId:
          json['time_slot_id'], // Keep as dynamic to support both int and String UUID
    );
  }
}

class SubjectInfoModel {
  final String id; // Changed from int to String to support UUID
  final String namaMataPelajaran;
  final String kelas;
  final List<TeacherModel> guru;

  SubjectInfoModel({
    required this.id,
    required this.namaMataPelajaran,
    required this.kelas,
    required this.guru,
  });

  factory SubjectInfoModel.fromJson(Map<String, dynamic> json) {
    return SubjectInfoModel(
      id: json['id']?.toString() ?? '0', // Convert to String to support UUID
      namaMataPelajaran: json['nama_mata_pelajaran'] ?? '',
      kelas: json['kelas'] ?? '',
      guru:
          (json['guru'] as List<dynamic>?)
              ?.map((g) => TeacherModel.fromJson(g))
              .toList() ??
          [],
    );
  }
}

class TeacherModel {
  final String id; // Changed from int to String to support UUID
  final String namaGuru;

  TeacherModel({required this.id, required this.namaGuru});

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id']?.toString() ?? '0',
      namaGuru: json['nama_guru'] ?? '',
    ); // Convert to String to support UUID
  }
}

class KelasModel {
  final dynamic
  id; // Changed from int to dynamic to support both int and String UUID
  final String name;
  final String level;
  final String description;

  KelasModel({
    required this.id,
    required this.name,
    required this.level,
    required this.description,
  });

  factory KelasModel.fromJson(Map<String, dynamic> json) {
    return KelasModel(
      id: json['id'], // Keep original type (int or String UUID)
      name: json['name'] ?? '',
      level: json['level'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class PresensiSummaryModel {
  final int totalHadir;
  final int totalSakit;
  final int totalIzin;
  final int totalAlpha;
  final int totalSiswa;

  PresensiSummaryModel({
    required this.totalHadir,
    required this.totalSakit,
    required this.totalIzin,
    required this.totalAlpha,
    required this.totalSiswa,
  });

  int get totalPresensi => totalHadir + totalSakit + totalIzin + totalAlpha;

  double get persentaseHadir {
    if (totalPresensi == 0) return 0.0;
    return (totalHadir / totalPresensi) * 100;
  }

  double get persentaseSakit {
    if (totalPresensi == 0) return 0.0;
    return (totalSakit / totalPresensi) * 100;
  }

  double get persentaseIzin {
    if (totalPresensi == 0) return 0.0;
    return (totalIzin / totalPresensi) * 100;
  }

  double get persentaseAlpha {
    if (totalPresensi == 0) return 0.0;
    return (totalAlpha / totalPresensi) * 100;
  }
}
