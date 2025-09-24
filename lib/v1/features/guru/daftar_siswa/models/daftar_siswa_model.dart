class DaftarSiswaModel {
  final String id; // Changed from int to String to support UUID
  final String name;
  final String nim;
  final int generation;
  final String kelasName;
  final String kelasId; // Changed from int to String to support UUID
  final String? email;
  final String? phone;
  final String? gender;

  DaftarSiswaModel({
    required this.id,
    required this.name,
    required this.nim,
    required this.generation,
    required this.kelasName,
    required this.kelasId,
    this.email,
    this.phone,
    this.gender,
  });

  factory DaftarSiswaModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data - API might not return user object
    final userData = json['user'] ?? {};

    // Try to get name from different possible sources
    String studentName = 'Nama Tidak Tersedia';
    if (userData['name'] != null && userData['name'].toString().isNotEmpty) {
      studentName = userData['name'].toString();
    } else if (json['name'] != null && json['name'].toString().isNotEmpty) {
      studentName = json['name'].toString();
    } else if (json['nisn'] != null && json['nisn'].toString().isNotEmpty) {
      studentName = 'Siswa ${json['nisn']}'; // Fallback to NISN if no name
    }

    // Try to get kelas name from different sources or use default from service
    String kelasName = 'Kelas Tidak Tersedia';
    if (json['kelas']?['name'] != null) {
      kelasName = json['kelas']['name'].toString();
    } else if (json['kelas_name'] != null) {
      kelasName = json['kelas_name'].toString();
    }
    // Note: kelasName will be set by service if not available in student data

    return DaftarSiswaModel(
      id: (json['id'] ?? '0').toString(), // Convert to String to support UUID
      name: studentName,
      nim: json['nisn'] ?? json['nim'] ?? '', // API uses 'nisn' not 'nim'
      generation: json['generation'] ?? 0,
      kelasName: kelasName,
      kelasId:
          (json['kelas_id'] ?? '0')
              .toString(), // Convert to String to support UUID
      email: userData['email']?.toString(),
      phone: userData['phone_number']?.toString(),
      gender: userData['gender']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nim': nim,
      'generation': generation,
      'kelas_name': kelasName,
      'kelas_id': kelasId,
      'email': email,
      'phone': phone,
      'gender': gender,
    };
  }

  @override
  String toString() {
    return 'DaftarSiswaModel(id: $id, name: $name, nim: $nim, kelas: $kelasName)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DaftarSiswaModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class KelasModel {
  final int id;
  final String name;
  final String code;

  KelasModel({required this.id, required this.name, required this.code});

  factory KelasModel.fromJson(Map<String, dynamic> json) {
    return KelasModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code};
  }

  @override
  String toString() => 'KelasModel(id: $id, name: $name, code: $code)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KelasModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SubjectModel {
  final String id; // Changed from int to String to support UUID
  final String mataPelajaran;
  final String kelas;

  SubjectModel({
    required this.id,
    required this.mataPelajaran,
    required this.kelas,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id:
          json['id']?.toString() ??
          '', // Convert to string to handle both int and UUID
      mataPelajaran: json['mata_pelajaran'] ?? '',
      kelas: json['kelas'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'mata_pelajaran': mataPelajaran, 'kelas': kelas};
  }

  @override
  String toString() =>
      'SubjectModel(id: $id, mata_pelajaran: $mataPelajaran, kelas: $kelas)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
