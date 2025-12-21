import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/document_repository.dart';
import '../../core/constants/app_constants.dart';
import 'auth_controller.dart';
import 'package:logger/logger.dart';

/// Controller for dashboard operations
class DashboardController extends GetxController {
  final _documentRepository = DocumentRepository();
  final _authController = Get.find<AuthController>();
  final _logger = Logger();

  // Observable state
  final RxList<DocumentModel> documents = <DocumentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreData = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadDocuments();
  }

  /// Load documents based on user role
  Future<void> loadDocuments(
      {bool refresh = false,
      String? search,
      String? dibaca,
      int? limit}) async {
    try {
      _logger.d('Dashboard loadDocuments start : $refresh, $search, $dibaca');
      if (refresh) {
        isRefreshing.value = true;
        currentPage.value = 1;
        documents.clear();
        hasMoreData.value = true; // Reset hasMoreData on refresh
      } else {
        isLoading.value = true;
      }

      final user = _authController.currentUser.value;
      if (user == null) return;

      final int fetchLimit = limit ?? AppConstants.documentsPerPage;
      List<DocumentModel> newDocuments = [];

      // Load documents based on role
      switch (user.role) {
        case UserRole.user:
          // User sees only their own documents
          _logger.i({
            'role': 'user',
            'userId': user.id,
            'page': currentPage.value,
            'dibaca': dibaca
          });
          newDocuments = await _documentRepository.getDocuments(
            userId: user.id,
            page: currentPage.value,
            limit: fetchLimit,
            search: search,
            dibaca: dibaca,
          );
          break;

        case UserRole.deptHead:
        case UserRole.protocolHead:
          // Department head and protocol head see department documents
          _logger.i({
            'role': user.role.code,
            'departemenId': user.departemenId,
            'page': currentPage.value,
            'dibaca': dibaca,
          });
          newDocuments = await _documentRepository.getDocuments(
            departemenId: user.departemenId,
            page: currentPage.value,
            limit: fetchLimit,
            search: search,
            dibaca: dibaca,
          );
          break;

        case UserRole.generalHead:
          // General head sees all submitted documents (status = 1)
          _logger.i({
            'role': 'generalHead',
            'status': DocumentStatus.pending.code,
            'page': currentPage.value,
            'dibaca': dibaca,
          });
          newDocuments = await _documentRepository.getDocuments(
            status: DocumentStatus.pending.code,
            page: currentPage.value,
            limit: fetchLimit,
            search: search,
            dibaca: dibaca,
          );
          break;

        case UserRole.coordinator:
          // Coordinator sees forwarded documents (status = 2)
          _logger.i({
            'role': 'coordinator',
            'status': DocumentStatus.forwardedToCoordinator.code,
            'page': currentPage.value,
            'dibaca': dibaca,
          });
          newDocuments = await _documentRepository.getDocuments(
            status: DocumentStatus.forwardedToCoordinator.code,
            page: currentPage.value,
            limit: fetchLimit,
            search: search,
            dibaca: dibaca,
          );
          break;

        case UserRole.mainLeader:
          // Main leader sees escalated documents (status = 9)
          _logger.i({
            'role': 'mainLeader',
            'status': DocumentStatus.forwardedToMainLeader.code,
            'page': currentPage.value,
            'dibaca': dibaca,
          });
          newDocuments = await _documentRepository.getDocuments(
            status: DocumentStatus.forwardedToMainLeader.code,
            page: currentPage.value,
            limit: fetchLimit,
            search: search,
            dibaca: dibaca,
          );
          break;

        case UserRole.superAdmin:
          // Super admin sees all documents
          _logger.i({
            'role': 'superAdmin',
            'page': currentPage.value,
            'dibaca': dibaca,
          });
          newDocuments = await _documentRepository.getDocuments(
            page: currentPage.value,
            limit: fetchLimit,
            search: search,
            dibaca: dibaca,
          );
          break;
      }

      _logger.d({'received': newDocuments.length});

      if (newDocuments.length < fetchLimit) {
        hasMoreData.value = false;
      }

      if (refresh) {
        documents.assignAll(newDocuments);
      } else {
        documents.addAll(newDocuments);
      }

      if (newDocuments.isNotEmpty) {
        currentPage.value++;
      }
    } catch (e) {
      _logger.e('Error loading documents: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat dokumen: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Refresh documents
  ///
  /// [dibaca] Optional parameter to filter documents by read status
  Future<void> refreshDocuments({String? dibaca}) async {
    hasMoreData.value = true;
    print('Dashboard loadDocuments start controller [3] : $dibaca');

    await loadDocuments(refresh: true, dibaca: dibaca);
  }

  /// Load more documents (pagination)
  Future<void> loadMore({String? dibaca}) async {
    if (!hasMoreData.value || isLoading.value) return;
    await loadDocuments(dibaca: dibaca);
  }

  /// Get meeting count for general head and protocol head
  int get meetingCount {
    return documents.where((doc) => doc.hasMeeting).length;
  }
}
