import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';

/// Confirmation dialog helper
class ConfirmationDialog {
  /// Show confirmation dialog
  static Future<bool> show({
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    Color? confirmColor,
    bool isDangerous = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous 
                  ? AppTheme.errorColor 
                  : confirmColor ?? AppTheme.primaryColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Show delete confirmation
  static Future<bool> showDelete({
    required String itemName,
  }) {
    return show(
      title: 'Hapus $itemName',
      message: 'Apakah Anda yakin ingin menghapus $itemName ini? Tindakan ini tidak dapat dibatalkan.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDangerous: true,
    );
  }

  /// Show logout confirmation
  static Future<bool> showLogout() {
    return show(
      title: 'Logout',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
      confirmText: 'Logout',
      cancelText: 'Batal',
      isDangerous: true,
    );
  }

  /// Show approve confirmation
  static Future<bool> showApprove({
    required String documentTitle,
  }) {
    return show(
      title: 'Setujui Dokumen',
      message: 'Apakah Anda yakin ingin menyetujui dokumen "$documentTitle"?',
      confirmText: 'Setujui',
      confirmColor: AppTheme.successColor,
    );
  }

  /// Show reject confirmation
  static Future<bool> showReject({
    required String documentTitle,
  }) {
    return show(
      title: 'Tolak Dokumen',
      message: 'Apakah Anda yakin ingin menolak dokumen "$documentTitle"?',
      confirmText: 'Tolak',
      isDangerous: true,
    );
  }

  /// Show return confirmation
  static Future<bool> showReturn({
    required String documentTitle,
  }) {
    return show(
      title: 'Kembalikan Dokumen',
      message: 'Apakah Anda yakin ingin mengembalikan dokumen "$documentTitle" untuk revisi?',
      confirmText: 'Kembalikan',
      confirmColor: AppTheme.warningColor,
    );
  }
}
