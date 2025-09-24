// teacher_info_model.dart
import '../../../../core/config/app_config.dart';

class TeacherInfoModel {
  final String id;
  final String name;
  final String email;
  final String position;
  final String nip;
  final List<String> roles;
  final String? imagePath;

  const TeacherInfoModel({
    required this.id,
    required this.name,
    required this.email,
    required this.position,
    required this.nip,
    required this.roles,
    this.imagePath,
  });

  factory TeacherInfoModel.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields
      if (json['id'] == null) {
        throw FormatException('Teacher ID is required');
      }

      // Extract user data with null safety
      final userData = json['user'] as Map<String, dynamic>? ?? {};

      // Extract and validate roles
      final rolesData = userData['roles'] as List<dynamic>? ?? [];
      final roles =
          rolesData
              .where(
                (role) =>
                    role is Map<String, dynamic> && role['name'] is String,
              )
              .map((role) => role['name'] as String)
              .toList();

      // Extract and validate required fields
      final name = userData['name'] as String? ?? '';
      final email = userData['email'] as String? ?? '';
      final position = json['position'] as String? ?? 'TEACHER';
      final nip = json['nip'] as String? ?? '';
      final imagePath = userData['img_path'] as String?;

      // Validate critical fields
      if (name.isEmpty) {
        throw FormatException('Teacher name cannot be empty');
      }

      return TeacherInfoModel(
        id: json['id'].toString(),
        name: name.trim(),
        email: email.trim(),
        position: position.trim().toUpperCase(),
        nip: nip.trim(),
        roles: roles,
        imagePath: imagePath?.trim(),
      );
    } catch (e) {
      throw FormatException('Failed to parse TeacherInfoModel: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'position': position,
      'nip': nip,
      'roles': roles,
      'image_path': imagePath,
    };
  }

  /// Get display-friendly role name
  String get roleDisplayName {
    if (roles.contains('Koordinator')) return 'Koordinator';
    if (roles.contains('Guru')) return 'Guru';
    if (roles.contains('Admin')) return 'Administrator';
    return roles.isNotEmpty ? roles.first : 'Staff';
  }

  /// Get display-friendly position name
  String get positionDisplayName {
    switch (position) {
      case 'TEACHER':
        return 'Guru';
      case 'ADMINISTRATOR':
        return 'Administrator';
      case 'TECHNICIAN':
        return 'Teknisi';
      default:
        return position
            .split('_')
            .map(
              (word) =>
                  word.isEmpty
                      ? ''
                      : word[0].toUpperCase() + word.substring(1).toLowerCase(),
            )
            .join(' ');
    }
  }

  /// Get profile image URL or default
  String get profileImageUrl {
    if (imagePath != null && imagePath!.isNotEmpty) {
      // If it's already a full URL, return as is
      if (imagePath!.startsWith('http')) return imagePath!;
      // Otherwise, construct full URL
      return '${AppConfig.url}/$imagePath';
    }
    // Return default profile image
    return '${AppConfig.url}/assets/images/default-profile.png';
  }

  /// Check if teacher has specific role
  bool hasRole(String role) {
    return roles.any((r) => r.toLowerCase() == role.toLowerCase());
  }

  /// Validate teacher info completeness
  bool get isComplete {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        email.isNotEmpty &&
        position.isNotEmpty;
  }

  @override
  String toString() {
    return 'TeacherInfoModel(id: $id, name: $name, position: $position, roles: $roles)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherInfoModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Create a copy with updated fields
  TeacherInfoModel copyWith({
    String? id,
    String? name,
    String? email,
    String? position,
    String? nip,
    List<String>? roles,
    String? imagePath,
  }) {
    return TeacherInfoModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      position: position ?? this.position,
      nip: nip ?? this.nip,
      roles: roles ?? this.roles,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

// subject_info_model.dart
class SubjectInfoModel {
  final String id;
  final String mataPelajaran;
  final String kelasName;
  final String level;
  final String displayName;

  const SubjectInfoModel({
    required this.id,
    required this.mataPelajaran,
    required this.kelasName,
    required this.level,
    required this.displayName,
  });

  factory SubjectInfoModel.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields
      if (json['id'] == null) {
        throw FormatException('Subject ID is required');
      }

      final id = json['id'].toString();
      final mataPelajaran = (json['mata_pelajaran'] as String? ?? '').trim();
      final kelasName = (json['kelas_name'] as String? ?? '').trim();
      final level = (json['level'] as String? ?? '').trim();
      final displayName = (json['display_name'] as String? ?? '').trim();

      // Validate critical fields
      if (mataPelajaran.isEmpty && displayName.isEmpty) {
        throw FormatException(
          'Subject must have either mata_pelajaran or display_name',
        );
      }

      return SubjectInfoModel(
        id: id,
        mataPelajaran: mataPelajaran,
        kelasName: kelasName,
        level: level.isNotEmpty ? level : kelasName,
        displayName: displayName.isNotEmpty ? displayName : mataPelajaran,
      );
    } catch (e) {
      throw FormatException('Failed to parse SubjectInfoModel: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mata_pelajaran': mataPelajaran,
      'kelas_name': kelasName,
      'level': level,
      'display_name': displayName,
    };
  }

  /// Get formatted level name
  String get formattedLevel {
    if (level.isEmpty) return '';

    final normalizedLevel = level.trim().toUpperCase();

    switch (normalizedLevel) {
      case 'TODDLER':
        return 'Toddler';
      case 'PLAYGROUP':
        return 'Playgroup';
      case 'KINDERGARTEN_1':
      case 'KINDERGARTEN 1':
      case 'TK A':
        return 'TK A';
      case 'KINDERGARTEN_2':
      case 'KINDERGARTEN 2':
      case 'TK B':
        return 'TK B';
      case 'ELEMENTARY_SCHOOL':
      case 'ELEMENTARY SCHOOL':
      case 'SD':
        return 'SD';
      case 'JUNIOR_HIGH_SCHOOL':
      case 'JUNIOR HIGH SCHOOL':
      case 'SMP':
        return 'SMP';
      case 'SENIOR_HIGH_SCHOOL':
      case 'SENIOR HIGH SCHOOL':
      case 'SMA':
        return 'SMA';
      default:
        return level
            .split(' ')
            .map(
              (word) =>
                  word.isEmpty
                      ? ''
                      : word[0].toUpperCase() + word.substring(1).toLowerCase(),
            )
            .join(' ');
    }
  }

  /// Check if subject info is complete
  bool get isComplete {
    return id.isNotEmpty &&
        (mataPelajaran.isNotEmpty || displayName.isNotEmpty);
  }

  /// Get subject key for grouping/sorting
  String get subjectKey {
    return '${kelasName}_${mataPelajaran}'.toLowerCase();
  }

  @override
  String toString() {
    return 'SubjectInfoModel(id: $id, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectInfoModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Create a copy with updated fields
  SubjectInfoModel copyWith({
    String? id,
    String? mataPelajaran,
    String? kelasName,
    String? level,
    String? displayName,
  }) {
    return SubjectInfoModel(
      id: id ?? this.id,
      mataPelajaran: mataPelajaran ?? this.mataPelajaran,
      kelasName: kelasName ?? this.kelasName,
      level: level ?? this.level,
      displayName: displayName ?? this.displayName,
    );
  }
}

// schedule_model.dart
class ScheduleModel {
  final String id;
  final String day;
  final String jamMulai;
  final String jamSelesai;
  final String mataPelajaran;
  final String kelas;
  final String kelasId;
  final String subjectTeacherId;
  final dynamic timeSlotId;

  const ScheduleModel({
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
      // Validate required fields
      if (json['id'] == null) {
        throw FormatException('Schedule ID is required');
      }

      final id = json['id'].toString();
      final day = (json['day'] as String? ?? '').trim().toUpperCase();
      final jamMulai = (json['jam_mulai'] as String? ?? '').trim();
      final jamSelesai = (json['jam_selesai'] as String? ?? '').trim();
      final mataPelajaran = (json['mata_pelajaran'] as String? ?? '').trim();
      final kelas = (json['kelas'] as String? ?? '').trim();
      final kelasId = (json['kelas_id']?.toString() ?? '0').trim();
      final subjectTeacherId =
          (json['subject_teacher_id']?.toString() ?? '0').trim();
      final timeSlotId = json['time_slot_id'];

      // Validate critical fields
      if (day.isEmpty) {
        throw FormatException('Schedule day is required');
      }

      if (jamMulai.isEmpty || jamSelesai.isEmpty) {
        throw FormatException('Schedule time slots are required');
      }

      // Validate time format (basic check)
      if (!_isValidTimeFormat(jamMulai) || !_isValidTimeFormat(jamSelesai)) {
        throw FormatException('Invalid time format in schedule');
      }

      return ScheduleModel(
        id: id,
        day: day,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        mataPelajaran: mataPelajaran,
        kelas: kelas,
        kelasId: kelasId,
        subjectTeacherId: subjectTeacherId,
        timeSlotId: timeSlotId,
      );
    } catch (e) {
      throw FormatException('Failed to parse ScheduleModel: $e');
    }
  }

  /// Basic time format validation (HH:MM)
  static bool _isValidTimeFormat(String time) {
    final timeRegex = RegExp(r'^\d{2}:\d{2}$');
    return timeRegex.hasMatch(time);
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

  /// Get Indonesian day name
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

  /// Get time range display
  String get timeRange => '$jamMulai - $jamSelesai';

  /// Get schedule duration in minutes
  int get durationInMinutes {
    try {
      final startParts = jamMulai.split(':');
      final endParts = jamSelesai.split(':');

      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      return endMinutes - startMinutes;
    } catch (e) {
      return 0;
    }
  }

  /// Check if schedule is valid
  bool get isValid {
    return id.isNotEmpty &&
        day.isNotEmpty &&
        jamMulai.isNotEmpty &&
        jamSelesai.isNotEmpty &&
        _isValidTimeFormat(jamMulai) &&
        _isValidTimeFormat(jamSelesai) &&
        durationInMinutes > 0;
  }

  /// Get schedule key for sorting
  String get scheduleKey {
    final dayOrder = {
      'MONDAY': 1,
      'TUESDAY': 2,
      'WEDNESDAY': 3,
      'THURSDAY': 4,
      'FRIDAY': 5,
      'SATURDAY': 6,
      'SUNDAY': 7,
    };

    final dayNum = dayOrder[day.toUpperCase()] ?? 8;
    return '${dayNum.toString().padLeft(2, '0')}_$jamMulai';
  }

  @override
  String toString() {
    return 'ScheduleModel(id: $id, day: $day, time: $timeRange, subject: $mataPelajaran, kelas: $kelas)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Create a copy with updated fields
  ScheduleModel copyWith({
    String? id,
    String? day,
    String? jamMulai,
    String? jamSelesai,
    String? mataPelajaran,
    String? kelas,
    String? kelasId,
    String? subjectTeacherId,
    dynamic timeSlotId,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      day: day ?? this.day,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      mataPelajaran: mataPelajaran ?? this.mataPelajaran,
      kelas: kelas ?? this.kelas,
      kelasId: kelasId ?? this.kelasId,
      subjectTeacherId: subjectTeacherId ?? this.subjectTeacherId,
      timeSlotId: timeSlotId ?? this.timeSlotId,
    );
  }
}
