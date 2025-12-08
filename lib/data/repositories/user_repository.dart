import 'package:logger/logger.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

/// Repository for user operations
class UserRepository {
  final _apiService = ApiService();
  final _logger = Logger();

  /// Get user profile
  Future<UserModel?> getProfile() async {
    try {
      _logger.d('Fetching user profile');
      
      final response = await _apiService.get(ApiConstants.profile);

      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      }

      return null;
    } catch (e) {
      _logger.e('Failed to fetch profile: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      _logger.d('Updating user profile');
      
      final response = await _apiService.put(
        ApiConstants.profile,
        data: data,
      );

      if (response.data['success'] == true) {
        _logger.i('Profile updated successfully');
        return UserModel.fromJson(response.data['data']);
      }

      throw Exception('Failed to update profile');
    } catch (e) {
      _logger.e('Failed to update profile: $e');
      rethrow;
    }
  }
}
