import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../data/repositories/document_repository.dart';
import '../../core/constants/app_constants.dart';
import 'auth_controller.dart';

/// Controller for dashboard operations
class DashboardController extends GetxController {
  final _documentRepository = DocumentRepository();
  final _authController = Get.find<AuthController>();

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
  Future<void> loadDocuments({bool refresh = false}) async {
    try {
      if (refresh) {
        isRefreshing.value = true;
        currentPage.value = 1;
        documents.clear();
      } else {
        isLoading.value = true;
      }

      final user = _authController.currentUser.value;
      if (user == null) return;

      List<DocumentModel> newDocuments = [];

      // Load documents based on role
      switch (user.role) {
        case UserRole.user:
          // User sees only their own documents
          newDocuments = await _documentRepository.getDocuments(
            userId: user.id,
            page: currentPage.value,
          );
          break;

        case UserRole.deptHead:
        case UserRole.protocolHead:
          // Department head and protocol head see department documents
          newDocuments = await _documentRepository.getDocuments(
            departemenId: user.departemenId,
            page: currentPage.value,
          );
          break;

        case UserRole.generalHead:
          // General head sees all submitted documents (status = 1)
          newDocuments = await _documentRepository.getDocuments(
            status: DocumentStatus.pending.code,
            page: currentPage.value,
          );
          break;

        case UserRole.coordinator:
          // Coordinator sees forwarded documents (status = 2)
          newDocuments = await _documentRepository.getDocuments(
            status: DocumentStatus.forwardedToCoordinator.code,
            page: currentPage.value,
          );
          break;

        case UserRole.mainLeader:
          // Main leader sees escalated documents (status = 9)
          newDocuments = await _documentRepository.getDocuments(
            status: DocumentStatus.forwardedToMainLeader.code,
            page: currentPage.value,
          );
          break;
      }

      if (newDocuments.length < AppConstants.documentsPerPage) {
        hasMoreData.value = false;
      }

      documents.addAll(newDocuments);
      currentPage.value++;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat dokumen. Silakan coba lagi.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      debugPrint('Failed to load documents: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Refresh documents
  Future<void> refreshDocuments() async {
    hasMoreData.value = true;
    await loadDocuments(refresh: true);
  }

  /// Load more documents (pagination)
  Future<void> loadMore() async {
    if (!hasMoreData.value || isLoading.value) return;
    await loadDocuments();
  }

  /// Get meeting count for general head and protocol head
  int get meetingCount {
    return documents.where((doc) => doc.hasMeeting).length;
  }
}
