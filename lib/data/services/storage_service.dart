import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';
import '../../core/constants/app_constants.dart';

/// Service for local storage operations
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _storage = GetStorage();
  final _logger = Logger();

  /// Initialize storage
  Future<void> init() async {
    try {
      await GetStorage.init();
      _logger.i('Storage initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize storage: $e');
      rethrow;
    }
  }

  /// Save authentication token
  Future<void> saveAuthToken(String token) async {
    try {
      await _storage.write(AppConstants.storageAuthToken, token);
      _logger.d('Auth token saved');
    } catch (e) {
      _logger.e('Failed to save auth token: $e');
      rethrow;
    }
  }

  /// Get authentication token
  String? getAuthToken() {
    try {
      return _storage.read<String>(AppConstants.storageAuthToken);
    } catch (e) {
      _logger.e('Failed to get auth token: $e');
      return null;
    }
  }

  /// Remove authentication token
  Future<void> removeAuthToken() async {
    try {
      await _storage.remove(AppConstants.storageAuthToken);
      _logger.d('Auth token removed');
    } catch (e) {
      _logger.e('Failed to remove auth token: $e');
      rethrow;
    }
  }

  /// Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _storage.write(AppConstants.storageUserData, userData);
      _logger.d('User data saved');
    } catch (e) {
      _logger.e('Failed to save user data: $e');
      rethrow;
    }
  }

  /// Get user data
  Map<String, dynamic>? getUserData() {
    try {
      return _storage.read<Map<String, dynamic>>(AppConstants.storageUserData);
    } catch (e) {
      _logger.e('Failed to get user data: $e');
      return null;
    }
  }

  /// Remove user data
  Future<void> removeUserData() async {
    try {
      await _storage.remove(AppConstants.storageUserData);
      _logger.d('User data removed');
    } catch (e) {
      _logger.e('Failed to remove user data: $e');
      rethrow;
    }
  }

  /// Save FCM token
  Future<void> saveFcmToken(String token) async {
    try {
      await _storage.write(AppConstants.storageFcmToken, token);
      _logger.d('FCM token saved');
    } catch (e) {
      _logger.e('Failed to save FCM token: $e');
      rethrow;
    }
  }

  /// Get FCM token
  String? getFcmToken() {
    try {
      return _storage.read<String>(AppConstants.storageFcmToken);
    } catch (e) {
      _logger.e('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Save remember me preference
  Future<void> saveRememberMe(bool remember) async {
    try {
      await _storage.write(AppConstants.storageRememberMe, remember);
      _logger.d('Remember me preference saved: $remember');
    } catch (e) {
      _logger.e('Failed to save remember me preference: $e');
      rethrow;
    }
  }

  /// Get remember me preference
  bool getRememberMe() {
    try {
      return _storage.read<bool>(AppConstants.storageRememberMe) ?? false;
    } catch (e) {
      _logger.e('Failed to get remember me preference: $e');
      return false;
    }
  }

  /// Save generic data
  Future<void> save(String key, dynamic value) async {
    try {
      await _storage.write(key, value);
      _logger.d('Data saved with key: $key');
    } catch (e) {
      _logger.e('Failed to save data with key $key: $e');
      rethrow;
    }
  }

  /// Get generic data
  T? get<T>(String key) {
    try {
      return _storage.read<T>(key);
    } catch (e) {
      _logger.e('Failed to get data with key $key: $e');
      return null;
    }
  }

  /// Remove generic data
  Future<void> remove(String key) async {
    try {
      await _storage.remove(key);
      _logger.d('Data removed with key: $key');
    } catch (e) {
      _logger.e('Failed to remove data with key $key: $e');
      rethrow;
    }
  }

  /// Clear all storage
  Future<void> clearAll() async {
    try {
      await _storage.erase();
      _logger.w('All storage data cleared');
    } catch (e) {
      _logger.e('Failed to clear all storage: $e');
      rethrow;
    }
  }

  /// Check if key exists
  bool hasData(String key) {
    try {
      return _storage.hasData(key);
    } catch (e) {
      _logger.e('Failed to check if key exists: $e');
      return false;
    }
  }
}
