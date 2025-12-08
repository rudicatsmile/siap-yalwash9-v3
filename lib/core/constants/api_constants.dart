/// API configuration constants
class ApiConstants {
  // Base URL - To be configured based on environment
  // For Android Emulator: use 10.0.2.2 (special alias to host machine's localhost)
    // For iOS Simulator: use 127.0.0.1 or localhost directly
    // For Physical Device: use your machine's local IP (e.g., 192.168.x.x)
    static const String baseUrl = 'http://192.168.1.6:8000';
  
  // API Endpoints - Authentication
  static const String login = '/api/login';
  static const String logout = '/api/logout';
  static const String getUser = '/api/user';
  
  // API Endpoints - Documents
  static const String documents = '/api/documents';
  static String documentDetail(int id) => '/api/documents/$id';
  static String updateDocumentStatus(int id) => '/api/documents/$id/status';
  
  // API Endpoints - Meetings
  static const String meetings = '/api/meetings';
  static String meetingDecision(int id) => '/api/meetings/$id/decision';
  
  // API Endpoints - History
  static const String history = '/api/history';
  
  // API Endpoints - Profile
  static const String profile = '/api/profile';
  
  // Headers
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String headerAuthorization = 'Authorization';
  
  // Header Values
  static const String applicationJson = 'application/json';
  static String bearerToken(String token) => 'Bearer $token';
}

/// Environment configuration
class Environment {
  static const String dev = 'development';
  static const String staging = 'staging';
  static const String production = 'production';
  
  // Current environment - Change this based on build
  static const String current = dev;
  
  static bool get isDevelopment => current == dev;
  static bool get isStaging => current == staging;
  static bool get isProduction => current == production;
  
  // Environment-specific configurations
  static String get apiBaseUrl {
    switch (current) {
      case dev:
        return 'http://localhost:8000'; // Local development
      case staging:
        return 'https://staging-api.siap.example.com'; // Staging server
      case production:
        return 'https://api.siap.example.com'; // Production server
      default:
        return 'http://localhost:8000';
    }
  }
}
