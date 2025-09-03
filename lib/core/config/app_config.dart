class AppConfig {
  // Base URL untuk API backend
  static String url = 'https://be.nurulchotib.com';
  static String baseUrl = 'https://be.nurulchotib.com/api';

  // Token autentikasi
  static String token = '';

  // ID Pegawai (guru)
  static int? employeeId;
  static String? employeeIdUuid;

  // Timeout configuration
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 6000;

  // Method untuk mengatur token
  static void setToken(String newToken) {
    token = newToken;
  }

  // Method untuk menghapus token
  static void clearToken() {
    token = '';
  }

  // Method untuk mengatur ID Pegawai
  static void setEmployeeId(int newEmployeeId) {
    employeeId = newEmployeeId;
  }

  // Method untuk mengatur employee UUID
  static void setEmployeeIdString(String newEmployeeId) {
    employeeIdUuid = newEmployeeId;
  }

  // Method untuk menghapus employee ID
  static void clearEmployeeId() {
    employeeId = null;
    employeeIdUuid = null;
  }
}
