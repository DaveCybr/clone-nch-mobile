// app/data/models/user_model.dart
// app/data/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime? emailVerifiedAt;
  final bool isChangePassword;
  final String status; // 'ACTIVE' or 'INACTIVE'
  final String? gender; // 'MALE' or 'FEMALE'
  final String religion; // 'ISLAM', 'KRISTEN', etc.
  final String? birthPlace;
  final DateTime? birthDate;
  final String? phoneNumber;
  final String? nationality;
  final String? imgPath;
  final String? imgName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Role dari relationship (untuk sementara simple string)
  final String? role; // 'teacher', 'admin', 'parent'
  final EmployeeModel? employee;
  final StudentModel? student;
  
  // Fields dari response server
  final String? currentRole;
  final List<String> permissions;
  final bool? isAdmin;
  final bool? isTeacherFromServer; // Dari field is_teacher server

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
    this.role,
    this.employee,
    this.student,
    this.currentRole,
    this.permissions = const [],
    this.isAdmin,
    this.isTeacherFromServer,
  });

  // Manual fromJson constructor
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      // ✅ Fix: Konversi aman untuk boolean dari server response
      isChangePassword: _safeBoolConversion(json['is_change_password']),
      status: json['status'] ?? 'ACTIVE',
      gender: json['gender'],
      religion: json['religion'] ?? 'ISLAM',
      birthPlace: json['birth_place'],
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date']) 
          : null,
      phoneNumber: json['phone_number'],
      nationality: json['nationality'],
      imgPath: json['img_path'],
      imgName: json['img_name'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      role: _extractRoleFromJson(json),
      employee: json['employee'] != null
          ? EmployeeModel.fromJson(json['employee'])
          : null,
      student: json['student'] != null
          ? StudentModel.fromJson(json['student'])
          : null,
      // ✅ Fields baru dari server response
      currentRole: json['current_role'],
      permissions: json['permissions'] != null 
          ? List<String>.from(json['permissions'])
          : [],
      isAdmin: _safeBoolConversion(json['is_admin']),
      isTeacherFromServer: _safeBoolConversion(json['is_teacher']),
    );
  }

  // ✅ Helper method untuk konversi boolean yang aman
  static bool _safeBoolConversion(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  // Helper method to extract role
  static String? _extractRoleFromJson(Map<String, dynamic> json) {
    // Cek current_role dulu (yang dikirim server)
    if (json['current_role'] != null) return json['current_role'];
    
    // Jika ada field 'role' langsung
    if (json['role'] != null) return json['role'];

    // Jika ada array 'roles' dari Laravel Spatie
    if (json['roles'] != null && json['roles'] is List) {
      final roles = json['roles'] as List;
      if (roles.isNotEmpty && roles.first is Map) {
        return roles.first['name'];
      }
    }

    return null;
  }

  // Manual toJson method
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
      'birth_date': birthDate?.toIso8601String().split('T')[0], // Date only
      'phone_number': phoneNumber,
      'nationality': nationality,
      'img_path': imgPath,
      'img_name': imgName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'role': role,
      'current_role': currentRole,
      'permissions': permissions,
      'is_admin': isAdmin,
      'is_teacher': isTeacherFromServer,
      'employee': employee?.toJson(),
      'student': student?.toJson(),
    };
  }

  // Helper methods - Updated berdasarkan response server
  bool get isActive => status == 'ACTIVE';
  
  // ✅ Gunakan is_teacher dari server response, fallback ke logic lama
  bool get isTeacher => 
      isTeacherFromServer ?? 
      (role == 'teacher' || currentRole == 'teacher' || employee != null);
      
  bool get isParent => role == 'parent' || currentRole == 'parent' || student != null;
  
  // ✅ Gunakan is_admin dari server response, fallback ke logic lama  
  bool get isAdminUser => 
      isAdmin ?? 
      (role == 'admin' || currentRole == 'admin');

  String get displayName => name;
  String get avatarUrl => imgPath ?? '';
  String get roleDisplay {
    if (isTeacher) return 'Ustadz/Ustadzah';
    if (isAdminUser) return 'Administrator';
    if (isParent) return 'Wali Santri';
    return 'User';
  }

  // Employee info for teachers
  String? get nip => employee?.nip;
  String? get position => employee?.position;

  // Permission checking
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  // Copy with method untuk update data
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
    String? role,
    String? currentRole,
    List<String>? permissions,
    bool? isAdmin,
    bool? isTeacherFromServer,
    EmployeeModel? employee,
    StudentModel? student,
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
      role: role ?? this.role,
      currentRole: currentRole ?? this.currentRole,
      permissions: permissions ?? this.permissions,
      isAdmin: isAdmin ?? this.isAdmin,
      isTeacherFromServer: isTeacherFromServer ?? this.isTeacherFromServer,
      employee: employee ?? this.employee,
      student: student ?? this.student,
    );
  }
}

class EmployeeModel {
  final String id;
  final String userId;
  final String? nip;
  final String position; // 'TEACHER', 'ADMINISTRATOR', 'TECHNICIAN'
  final String? nuptk;
  final String? nik;
  final String? pendidikanTerakhir;
  final String? jurusan;
  final String? universitas;
  final String? tahunLulus;
  // ✅ Fields tambahan dari response
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

  bool get isTeacher => position == 'TEACHER';
  bool get isAdmin => position == 'ADMINISTRATOR';
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

// Auth Response Model - Updated untuk response aktual
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
    // Check if this is an error response
    if (json.containsKey('message') && json.containsKey('errors')) {
      return AuthResponse(
        success: false,
        message: json['message'] ?? 'Login failed',
        token: null,
        user: null,
      );
    }

    // Check if this is a successful response with access_token
    if (json.containsKey('access_token') && json.containsKey('user')) {
      return AuthResponse(
        success: true,
        message: 'Login successful',
        token: json['access_token'], // ✅ Fix: Gunakan access_token
        user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      );
    }

    // Legacy format support
    return AuthResponse(
      success: _safeBoolConversion(json['success']),
      message: json['message'] ?? '',
      token: json['token'] ?? json['access_token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  // ✅ Helper method untuk konversi boolean yang aman
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
      'token': token,
      'user': user?.toJson(),
    };
  }

  @override
  String toString() {
    return 'AuthResponse(success: $success, message: "$message", hasToken: ${token != null}, hasUser: ${user != null})';
  }
}