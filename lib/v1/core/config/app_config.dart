class AppConfig {
  // Base URL untuk API backend
  static String url = 'https://be.nurulchotib.com';
  static String baseUrl = '$url/api';

  // Token autentikasi
  static String _token = '';

  // ID Pegawai (guru)
  static int? _employeeId;
  static String? _employeeIdUuid;

  // Connection configuration
  static const int connectTimeout = 15000; // Increased from 10000
  static const int receiveTimeout = 15000; // Increased from 6000
  static const int sendTimeout = 15000; // Added send timeout

  // Retry configuration
  static const int maxRetries = 3;
  static const int retryDelayMs = 1000;

  // Security: Getter untuk token (read-only access)
  static String get token => _token;
  static int? get employeeId => _employeeId;
  static String? get employeeIdUuid => _employeeIdUuid;

  // Method untuk mengatur token dengan validation
  static bool setToken(String newToken) {
    if (newToken.isEmpty) {
      return false;
    }
    _token = newToken;
    return true;
  }

  // Method untuk menghapus token
  static void clearToken() {
    _token = '';
  }

  // Method untuk mengatur ID Pegawai dengan validation
  static bool setEmployeeId(int newEmployeeId) {
    if (newEmployeeId <= 0) {
      return false;
    }
    _employeeId = newEmployeeId;
    return true;
  }

  // Method untuk mengatur employee UUID dengan validation
  static bool setEmployeeIdString(String newEmployeeId) {
    if (newEmployeeId.isEmpty) {
      return false;
    }
    _employeeIdUuid = newEmployeeId;
    return true;
  }

  // Method untuk menghapus employee ID
  static void clearEmployeeId() {
    _employeeId = null;
    _employeeIdUuid = null;
  }

  // Method untuk validasi konfigurasi
  static bool isConfigured() {
    return url!.isNotEmpty &&
        baseUrl!.isNotEmpty &&
        _token.isNotEmpty &&
        (_employeeId != null || _employeeIdUuid != null);
  }

  // Method untuk reset semua konfigurasi
  static void reset() {
    clearToken();
    clearEmployeeId();
  }

  // Method untuk debug info (tanpa sensitive data)
  static Map<String, dynamic> getDebugInfo() {
    return {
      'url': url,
      'baseUrl': baseUrl,
      'hasToken': _token.isNotEmpty,
      'hasEmployeeId': _employeeId != null,
      'hasEmployeeUuid': _employeeIdUuid != null,
      'connectTimeout': connectTimeout,
      'receiveTimeout': receiveTimeout,
    };
  }
}
