class TeacherInfoModel {
  final String id; // Changed from int to String to support UUID
  final String name;
  final String email;
  final String position;
  final String nip;
  final List<String> roles;
  final String? imagePath;

  TeacherInfoModel({
    required this.id,
    required this.name,
    required this.email,
    required this.position,
    required this.nip,
    required this.roles,
    this.imagePath,
  });

  factory TeacherInfoModel.fromJson(Map<String, dynamic> json) {
    // Extract user data
    final userData = json['user'] ?? {};

    // Extract roles
    final rolesData = userData['roles'] as List<dynamic>? ?? [];
    final roles = rolesData.map((role) => role['name'] as String).toList();

    return TeacherInfoModel(
      id: json['id']?.toString() ?? '0', // Convert to String to support UUID
      name: userData['name'] ?? 'Nama Tidak Tersedia',
      email: userData['email'] ?? '',
      position: json['position'] ?? 'TEACHER',
      nip: json['nip'] ?? '',
      roles: roles,
      imagePath: userData['img_path'],
    );
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

  // Helper untuk mendapatkan role display name
  String get roleDisplayName {
    if (roles.contains('Koordinator')) {
      return 'Koordinator';
    } else if (roles.contains('Guru')) {
      return 'Guru';
    } else if (roles.contains('Admin')) {
      return 'Administrator';
    } else {
      return roles.isNotEmpty ? roles.first : 'Staff';
    }
  }

  // Helper untuk format posisi
  String get positionDisplayName {
    switch (position) {
      case 'TEACHER':
        return 'Guru';
      case 'ADMINISTRATOR':
        return 'Administrator';
      case 'TECHNICIAN':
        return 'Teknisi';
      default:
        return position;
    }
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
}

class SubjectInfoModel {
  final String id; // Changed from int to String to support UUID
  final String mataPelajaran;
  final String kelasName;
  final String level;
  final String displayName;

  SubjectInfoModel({
    required this.id,
    required this.mataPelajaran,
    required this.kelasName,
    required this.level,
    required this.displayName,
  });

  factory SubjectInfoModel.fromJson(Map<String, dynamic> json) {
    return SubjectInfoModel(
      id: json['id']?.toString() ?? '0', // Convert to String to support UUID
      mataPelajaran: json['mata_pelajaran'] ?? '',
      kelasName: json['kelas_name'] ?? '',
      level: json['level'] ?? '',
      displayName: json['display_name'] ?? '',
    );
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
}
