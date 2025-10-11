// UPDATE: lib/v2/app/data/models/user_model.dart
// Perbaikan untuk parsing response actual

class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime? emailVerifiedAt;
  final bool isChangePassword;
  final String status;
  final String? gender;
  final String religion;
  final String? birthPlace;
  final DateTime? birthDate;
  final String? phoneNumber;
  final String? nationality;
  final String? imgPath;
  final String? imgName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Role info
  final String? currentRole;
  final List<String> permissions;
  final bool? isAdmin;
  final bool? isTeacherFromServer;
  final EmployeeModel? employee;
  final StudentModel? student;
  final List<RoleModel> roles; // ← ADD THIS

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.isChangePassword = false,
    this.status = 'ACTIVE',
    this.gender,
    this.religion = 'ISLAM',
    this.birthPlace,
    this.birthDate,
    this.phoneNumber,
    this.nationality,
    this.imgPath,
    this.imgName,
    this.createdAt,
    this.updatedAt,
    this.currentRole,
    this.permissions = const [],
    this.isAdmin,
    this.isTeacherFromServer,
    this.employee,
    this.student,
    this.roles = const [], // ← ADD THIS
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle roles: bisa string list atau object list
    final roles = <RoleModel>[];
    if (json['roles'] is List) {
      final rawRoles = json['roles'] as List;
      if (rawRoles.isNotEmpty && rawRoles.first is String) {
        // Convert list string ke RoleModel sederhana
        for (var r in rawRoles) {
          roles.add(
            RoleModel(id: '', name: r, guardName: 'web', permissions: []),
          );
        }
      } else {
        roles.addAll(rawRoles.map((r) => RoleModel.fromJson(r)).toList());
      }
    }

    // Handle permission/permissions
    final allPermissions = <String>[];
    if (json['permission'] is List) {
      allPermissions.addAll(List<String>.from(json['permission']));
    }
    if (json['permissions'] is List) {
      allPermissions.addAll(List<String>.from(json['permissions']));
    }

    // Determine if user is teacher from roles or employee data
    final hasTeacherRole = roles.any(
      (role) => role.name.toLowerCase() == 'teacher',
    );
    final hasEmployeeData = json['employee'] != null;
    final currentRole = json['current_role'] as String?;

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerifiedAt:
          json['email_verified_at'] != null
              ? DateTime.parse(json['email_verified_at'])
              : null,
      isChangePassword: _safeBoolConversion(json['is_change_password']),
      status: json['status'] ?? 'ACTIVE',
      gender: json['gender'],
      religion: json['religion'] ?? 'ISLAM',
      birthPlace: json['birth_place'],
      birthDate:
          json['birth_date'] != null
              ? DateTime.tryParse(json['birth_date'])
              : null,
      phoneNumber: json['phone_number'],
      nationality: json['nationality'],
      imgPath: json['img_path'],
      imgName: json['img_name'],
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'])
              : null,
      currentRole: currentRole,
      permissions: allPermissions.toSet().toList(), // Remove duplicates
      isAdmin: _safeBoolConversion(json['is_admin']),
      isTeacherFromServer: _safeBoolConversion(json['is_teacher']),
      employee:
          json['employee'] != null
              ? EmployeeModel.fromJson(json['employee'])
              : null,
      student:
          json['student'] != null
              ? StudentModel.fromJson(json['student'])
              : null,
      roles: roles,
    );
  }

  static bool _safeBoolConversion(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'is_change_password': isChangePassword ? 1 : 0,
      'status': status,
      'gender': gender,
      'religion': religion,
      'birth_place': birthPlace,
      'birth_date': birthDate?.toIso8601String().split('T')[0],
      'phone_number': phoneNumber,
      'nationality': nationality,
      'img_path': imgPath,
      'img_name': imgName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'current_role': currentRole,
      'permissions': permissions,
      'is_admin': isAdmin,
      'is_teacher': isTeacherFromServer,
      'employee': employee?.toJson(),
      'student': student?.toJson(),
      'roles': roles.map((r) => r.toJson()).toList(),
    };
  }

  // ✅ IMPROVED HELPER METHODS
  bool get isActive => status == 'ACTIVE';

  // ✅ FIX: Better teacher detection logic
  bool get isTeacher {
    // Check multiple sources to determine if user is a teacher
    if (currentRole?.toLowerCase() == 'teacher') return true;
    if (roles.any((role) => role.name.toLowerCase() == 'teacher')) return true;
    if (employee != null && employee!.isTeacher) return true;
    if (isTeacherFromServer == true) return true;
    return false;
  }

  // lib/v2/app/data/models/user_model.dart
  // UPDATE bagian getter isStudent

  bool get isStudent {
    // 1. Cek dari current_role
    if (currentRole?.toLowerCase() == 'student' ||
        currentRole?.toLowerCase() == 'santri') {
      print('✅ isStudent: true (from current_role: $currentRole)');
      return true;
    }

    // 2. Cek dari roles array
    if (roles.any(
      (role) =>
          role.name.toLowerCase() == 'student' ||
          role.name.toLowerCase() == 'santri',
    )) {
      print('✅ isStudent: true (from roles array)');
      return true;
    }

    // 3. Jika punya student data sendiri (bukan parent)
    if (student != null && !isTeacher && !isParent) {
      print('✅ isStudent: true (has student data)');
      return true;
    }

    print('❌ isStudent: false');
    return false;
  }

  bool get isParent {
    // 1. Cek dari current_role
    if (currentRole?.toLowerCase() == 'parent' ||
        currentRole?.toLowerCase() == 'wali') {
      print('✅ isParent: true (from current_role: $currentRole)');
      return true;
    }

    // 2. Cek dari roles array
    if (roles.any(
      (role) =>
          role.name.toLowerCase() == 'parent' ||
          role.name.toLowerCase() == 'wali',
    )) {
      print('✅ isParent: true (from roles array)');
      return true;
    }

    print('❌ isParent: false');
    return false;
  }

  String get roleDisplay {
    if (isTeacher) return 'Ustadz/Ustadzah';
    if (isStudent) return 'Santri';
    if (isParent) return 'Wali Santri';
    if (isAdminUser) return 'Administrator';
    return 'User';
  }

  bool get isAdminUser => isAdmin ?? (currentRole?.toLowerCase() == 'admin');

  String get displayName => name;
  String get avatarUrl => imgPath ?? '';

  String? get nip => employee?.nip;
  String? get position => employee?.position;

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  // ✅ ADD: Get role names
  List<String> get roleNames => roles.map((r) => r.name).toList();

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? emailVerifiedAt,
    bool? isChangePassword,
    String? status,
    String? gender,
    String? religion,
    String? birthPlace,
    DateTime? birthDate,
    String? phoneNumber,
    String? nationality,
    String? imgPath,
    String? imgName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currentRole,
    List<String>? permissions,
    bool? isAdmin,
    bool? isTeacherFromServer,
    EmployeeModel? employee,
    StudentModel? student,
    List<RoleModel>? roles,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      isChangePassword: isChangePassword ?? this.isChangePassword,
      status: status ?? this.status,
      gender: gender ?? this.gender,
      religion: religion ?? this.religion,
      birthPlace: birthPlace ?? this.birthPlace,
      birthDate: birthDate ?? this.birthDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationality: nationality ?? this.nationality,
      imgPath: imgPath ?? this.imgPath,
      imgName: imgName ?? this.imgName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentRole: currentRole ?? this.currentRole,
      permissions: permissions ?? this.permissions,
      isAdmin: isAdmin ?? this.isAdmin,
      isTeacherFromServer: isTeacherFromServer ?? this.isTeacherFromServer,
      employee: employee ?? this.employee,
      student: student ?? this.student,
      roles: roles ?? this.roles,
    );
  }
}

// ✅ ADD: RoleModel class
class RoleModel {
  final String id;
  final String name;
  final String guardName;
  final List<PermissionModel> permissions;

  const RoleModel({
    required this.id,
    required this.name,
    required this.guardName,
    required this.permissions,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      guardName: json['guard_name'] as String,
      permissions:
          (json['permissions'] as List?)
              ?.map((p) => PermissionModel.fromJson(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'guard_name': guardName,
      'permissions': permissions.map((p) => p.toJson()).toList(),
    };
  }
}

// ✅ ADD: PermissionModel class
class PermissionModel {
  final String id;
  final String name;
  final String guardName;

  const PermissionModel({
    required this.id,
    required this.name,
    required this.guardName,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      guardName: json['guard_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'guard_name': guardName};
  }
}

// EmployeeModel tetap sama seperti sebelumnya...
class EmployeeModel {
  final String id;
  final String userId;
  final String? nip;
  final String position;
  final String? nuptk;
  final String? nik;
  final String? pendidikanTerakhir;
  final String? jurusan;
  final String? universitas;
  final String? tahunLulus;
  final String? jabatan;
  final String? bidangStudiDiampu;
  final String? tugasTambahan;
  final String? statusGtyGtty;
  final String? mengajarMulaiTahun;
  final String? serdikStatus;
  final String? statusMenikah;
  final String? golDarah;
  final String? alamatJalan;
  final String? rt;
  final String? rw;
  final String? desaKelurahan;
  final String? kecamatan;
  final String? kodepos;

  const EmployeeModel({
    required this.id,
    required this.userId,
    this.nip,
    required this.position,
    this.nuptk,
    this.nik,
    this.pendidikanTerakhir,
    this.jurusan,
    this.universitas,
    this.tahunLulus,
    this.jabatan,
    this.bidangStudiDiampu,
    this.tugasTambahan,
    this.statusGtyGtty,
    this.mengajarMulaiTahun,
    this.serdikStatus,
    this.statusMenikah,
    this.golDarah,
    this.alamatJalan,
    this.rt,
    this.rw,
    this.desaKelurahan,
    this.kecamatan,
    this.kodepos,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nip: json['nip'],
      position: json['position'] as String,
      nuptk: json['nuptk'],
      nik: json['nik'],
      pendidikanTerakhir: json['pendidikan_terakhir'],
      jurusan: json['jurusan'],
      universitas: json['universitas'],
      tahunLulus: json['tahun_lulus'],
      jabatan: json['jabatan'],
      bidangStudiDiampu: json['bidang_studi_diampu'],
      tugasTambahan: json['tugas_tambahan'],
      statusGtyGtty: json['status_gty_gtty'],
      mengajarMulaiTahun: json['mengajar_mulai_tahun'],
      serdikStatus: json['serdik_status'],
      statusMenikah: json['status_menikah'],
      golDarah: json['gol_darah'],
      alamatJalan: json['alamat_jalan'],
      rt: json['rt'],
      rw: json['rw'],
      desaKelurahan: json['desa_kelurahan'],
      kecamatan: json['kecamatan'],
      kodepos: json['kodepos'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nip': nip,
      'position': position,
      'nuptk': nuptk,
      'nik': nik,
      'pendidikan_terakhir': pendidikanTerakhir,
      'jurusan': jurusan,
      'universitas': universitas,
      'tahun_lulus': tahunLulus,
      'jabatan': jabatan,
      'bidang_studi_diampu': bidangStudiDiampu,
      'tugas_tambahan': tugasTambahan,
      'status_gty_gtty': statusGtyGtty,
      'mengajar_mulai_tahun': mengajarMulaiTahun,
      'serdik_status': serdikStatus,
      'status_menikah': statusMenikah,
      'gol_darah': golDarah,
      'alamat_jalan': alamatJalan,
      'rt': rt,
      'rw': rw,
      'desa_kelurahan': desaKelurahan,
      'kecamatan': kecamatan,
      'kodepos': kodepos,
    };
  }

  bool get isTeacher => position.toLowerCase() == 'teacher';
  bool get isAdmin => position.toLowerCase() == 'administrator';
}

class StudentModel {
  final String id;
  final String userId;
  final String kelasId;
  final String nisn;
  final int generation;
  final String? address;

  const StudentModel({
    required this.id,
    required this.userId,
    required this.kelasId,
    required this.nisn,
    required this.generation,
    this.address,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      kelasId: json['kelas_id'] as String,
      nisn: json['nisn'] as String,
      generation: json['generation'] as int,
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'kelas_id': kelasId,
      'nisn': nisn,
      'generation': generation,
      'address': address,
    };
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;

  const AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Response structure sesuai dengan backend actual
    if (json.containsKey('access_token') && json.containsKey('user')) {
      return AuthResponse(
        success: true,
        message: 'Login successful',
        token: json['access_token'], // Menggunakan access_token
        user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      );
    }

    // Fallback untuk error response
    if (json.containsKey('message') && json.containsKey('errors')) {
      return AuthResponse(
        success: false,
        message: json['message'] ?? 'Login failed',
        token: null,
        user: null,
      );
    }

    // Default fallback
    return AuthResponse(
      success: _safeBoolConversion(json['success']),
      message: json['message'] ?? '',
      token: json['token'] ?? json['access_token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  static bool _safeBoolConversion(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'access_token': token,
      'user': user?.toJson(),
    };
  }

  @override
  String toString() {
    return 'AuthResponse(success: $success, message: "$message", hasToken: ${token != null}, hasUser: ${user != null})';
  }
}
