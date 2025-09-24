import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';

class StorageService extends GetxService {
  late GetStorage _box;

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _rememberMeKey = 'remember_me';
  static const String _lastLoginKey = 'last_login';

  @override
  Future<void> onInit() async {
    super.onInit();
    _box = GetStorage();
    await _box.initStorage;
  }

  // Token management
  Future<void> saveToken(String token) async {
    await _box.write(_tokenKey, token);
  }

  String? getToken() {
    return _box.read(_tokenKey);
  }

  Future<void> removeToken() async {
    await _box.remove(_tokenKey);
  }

  bool get hasValidToken => getToken() != null;

  // User data management
  Future<void> saveUser(UserModel user) async {
    await _box.write(_userKey, user.toJson());
  }

  UserModel? getUser() {
    final userData = _box.read(_userKey);
    if (userData != null) {
      return UserModel.fromJson(Map<String, dynamic>.from(userData));
    }
    return null;
  }

  Future<void> removeUser() async {
    await _box.remove(_userKey);
  }

  // Remember me functionality
  Future<void> setRememberMe(bool remember) async {
    await _box.write(_rememberMeKey, remember);
  }

  bool getRememberMe() {
    return _box.read(_rememberMeKey) ?? false;
  }

  // Last login timestamp
  Future<void> saveLastLogin() async {
    await _box.write(_lastLoginKey, DateTime.now().toIso8601String());
  }

  DateTime? getLastLogin() {
    final lastLogin = _box.read(_lastLoginKey);
    if (lastLogin != null) {
      return DateTime.parse(lastLogin);
    }
    return null;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _box.erase();
  }
}
