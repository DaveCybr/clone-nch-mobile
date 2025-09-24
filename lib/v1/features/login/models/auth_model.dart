class UserModel {
  final String? id; // Changed from int? to String? for UUID
  final String name;
  final String email;
  final String? password;
  final String? imgPath;
  final String? gender;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.password,
    this.imgPath,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(), // Convert to String to handle UUID
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString(),
      imgPath: json['img_path']?.toString(),
      gender: json['gender']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'img_path': imgPath,
      'gender': gender,
    };
  }

  UserModel copyWith({
    String? id, // Changed from int? to String?
    String? name,
    String? email,
    String? password,
    String? imgPath,
    String? gender,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      imgPath: imgPath ?? this.imgPath,
      gender: gender ?? this.gender,
    );
  }
}
