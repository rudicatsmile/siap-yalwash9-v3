import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/api_service.dart';

/// Controller for authentication operations
class AuthController extends GetxController {
  final _authService = AuthService();

  // Observable state
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuthentication();
  }

  /// Check if user is already authenticated
  Future<void> checkAuthentication() async {
    try {
      isLoading.value = true;
      
      final cachedUser = _authService.getCachedUser();
      final hasToken = _authService.isAuthenticated();

      if (hasToken && cachedUser != null) {
        currentUser.value = cachedUser;
        isAuthenticated.value = true;
        
        // Try to refresh user data
        final user = await _authService.getCurrentUser();
        if (user != null) {
          currentUser.value = user;
        }
      } else {
        isAuthenticated.value = false;
      }
    } catch (e) {
      isAuthenticated.value = false;
      debugPrint('Authentication check failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Login with username and password
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _authService.login(
        username: username,
        password: password,
      );

      if (result['success'] == true) {
        currentUser.value = result['user'] as UserModel;
        isAuthenticated.value = true;
        
        Get.snackbar(
          'Berhasil',
          'Login berhasil. Selamat datang ${currentUser.value!.namaLengkap}!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        
        return true;
      }
      
      return false;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      Get.snackbar(
        'Login Gagal',
        e.message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan saat login';
      Get.snackbar(
        'Error',
        'Terjadi kesalahan saat login. Silakan coba lagi.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      isLoading.value = true;

      await _authService.logout();

      currentUser.value = null;
      isAuthenticated.value = false;

      Get.snackbar(
        'Logout',
        'Anda telah berhasil logout',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal logout. Silakan coba lagi.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        currentUser.value = user;
      }
    } catch (e) {
      debugPrint('Failed to refresh user: $e');
    }
  }
}
