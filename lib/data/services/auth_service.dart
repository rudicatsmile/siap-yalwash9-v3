import 'package:logger/logger.dart';
import '../models/models.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Authentication service
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _apiService = ApiService();
  final _storageService = StorageService();
  final _logger = Logger();

  /// Login with username and password
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      _logger.d('Attempting login for user: $username');

      final response = await _apiService.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
      );
      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final bool ok = (body['success'] == true) ||
          ((body['status'] is int) &&
              (body['status'] >= 200 && body['status'] < 300)) ||
          ((response.statusCode ?? 0) >= 200 &&
              (response.statusCode ?? 0) < 300);

      if (ok) {
        final data = body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : body;
        final token = data['token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;

        if (token == null || userData == null) {
          throw ApiException(
            'Format respons tidak valid',
            statusCode: response.statusCode ?? 0,
            data: response.data,
          );
        }

        await _storageService.saveAuthToken(token);
        await _storageService.saveUserData(userData);

        _logger.i('Login successful for user: $username');
        return {
          'success': true,
          'token': token,
          'user': UserModel.fromJson(userData),
        };
      }

      throw ApiException(
        (body['message'] as String?) ?? 'Login gagal',
        statusCode: response.statusCode ?? 0,
        data: response.data,
      );
    } catch (e) {
      _logger.e('Login failed: $e');
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      _logger.d('Logging out');

      // Call logout API
      try {
        await _apiService.post(ApiConstants.logout);
      } catch (e) {
        _logger.w('Logout API call failed: $e');
        // Continue with local logout even if API fails
      }

      // Clear local data
      await _storageService.removeAuthToken();
      await _storageService.removeUserData();

      _logger.i('Logout completed');
    } catch (e) {
      _logger.e('Logout failed: $e');
      rethrow;
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      _logger.d('Fetching current user');

      final response = await _apiService.get(ApiConstants.getUser);

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final bool ok = (body['success'] == true) ||
          ((body['status'] is int) &&
              (body['status'] >= 200 && body['status'] < 300)) ||
          ((response.statusCode ?? 0) >= 200 &&
              (response.statusCode ?? 0) < 300);

      if (!ok) return null;

      final userData = (body['data'] is Map<String, dynamic>
              ? body['data'] as Map<String, dynamic>
              : body['user'] as Map<String, dynamic>?) ??
          <String, dynamic>{};

      if (userData.isEmpty) return null;

      await _storageService.saveUserData(userData);
      return UserModel.fromJson(userData);
    } catch (e) {
      _logger.e('Failed to get current user: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    final token = _storageService.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Get cached user data
  UserModel? getCachedUser() {
    try {
      final userData = _storageService.getUserData();
      if (userData != null) {
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get cached user: $e');
      return null;
    }
  }

  /// Update FCM token
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _storageService.saveFcmToken(fcmToken);
      _logger.d('FCM token updated');
    } catch (e) {
      _logger.e('Failed to update FCM token: $e');
    }
  }
}
