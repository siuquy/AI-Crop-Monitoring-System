class ApiConfig {
  // Set this to true to use the public production API
  static const bool useProduction = true;

  static String get baseUrl => useProduction
      ? 'https://cmms-api.duckdns.org'
      // : 'https://10.0.2.2:7093'; // Fallback for local Android emulator testing
      : 'https://192.168.1.189:7093';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
