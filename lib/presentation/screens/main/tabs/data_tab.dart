import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/repositories/document_repository.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../../routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

/// Data tab with role-based dashboard
class DataTab extends StatelessWidget {
  final String? qParam;
  const DataTab({super.key, this.qParam});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.put(DashboardController(), permanent: true);
    final authController = Get.find<AuthController>();

    final qp = qParam ??
        ((Get.arguments is Map)
            ? (Get.arguments as Map)['qParam'] as String?
            : null);
    if (qp != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dashboardController.loadDocuments(
            refresh: true, search: null, dibaca: qParam);
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(qp == null ? 'Dashboard SIAP' : 'Dashboard SIAP — $qp'),
      ),
      body: Obx(
        () {
          if (dashboardController.isLoading.value &&
              dashboardController.documents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboardController.documents.isEmpty) {
            return const Center(child: Text('Belum ada berkas'));
          }

          return RefreshIndicator(
            onRefresh: dashboardController.refreshDocuments,
            child: ListView.builder(
              itemCount: dashboardController.documents.length,
              itemBuilder: (context, index) {
                final doc = dashboardController.documents[index];
                return Card(
                  child: ListTile(
                    title: Text(doc.kategoriKode == 'Rapat'
                        ? (doc.bahasanRapat ?? doc.title)
                        : (doc.kategoriKode == 'Memo' ||
                                doc.kategoriKode == 'Koordinasi')
                            ? (doc.instruksiKerja ?? doc.title)
                            : doc.title),
                    subtitle: Text(doc.documentNumber),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.getStatusColor(doc.status)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.getStatusColor(doc.status),
                            ),
                          ),
                          child: Text(
                            doc.status.displayName +
                                (doc.kategoriSurat != null
                                    ? '\n${doc.kategoriSurat!}'
                                    : ''),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.getStatusColor(doc.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            switch (value) {
                              case 'detail':
                                // qParam = '2' hanya menampilkan menu Detail; aksi sama seperti 'view'
                                try {
                                  final result = await Get.toNamed(
                                    AppRoutes.documentForm,
                                    arguments: {
                                      'no_surat': doc.documentNumber,
                                      'qParam': qp
                                    },
                                  );
                                  if (result != null) {
                                    final dashboardController =
                                        Get.find<DashboardController>();
                                    await dashboardController
                                        .refreshDocuments();
                                  }
                                } catch (e) {
                                  Get.snackbar(
                                    'Error',
                                    'Gagal membuka form edit: $e',
                                    backgroundColor: AppTheme.errorColor,
                                    colorText: Colors.white,
                                  );
                                }
                                break;
                              case 'view':
                                try {
                                  final result = await Get.toNamed(
                                    AppRoutes.documentDetail,
                                    arguments: doc,
                                  );
                                  if (result == 'deleted') {
                                    await dashboardController
                                        .refreshDocuments();
                                  }
                                } catch (e) {
                                  Get.snackbar(
                                    'Error',
                                    'Gagal membuka detail: $e',
                                    backgroundColor: AppTheme.errorColor,
                                    colorText: Colors.white,
                                  );
                                }
                                break;
                              case 'edit':
                                try {
                                  final result = await Get.toNamed(
                                    AppRoutes.documentForm,
                                    arguments: {
                                      'no_surat': doc.documentNumber,
                                      'qParam': qp
                                    },
                                  );
                                  if (result != null) {
                                    final dashboardController =
                                        Get.find<DashboardController>();
                                    await dashboardController
                                        .refreshDocuments();
                                  }
                                } catch (e) {
                                  Get.snackbar(
                                    'Error',
                                    'Gagal membuka form edit: $e',
                                    backgroundColor: AppTheme.errorColor,
                                    colorText: Colors.white,
                                  );
                                }
                                break;
                              case 'delete':
                                try {
                                  if (doc.dibaca != '1') {
                                    Get.snackbar(
                                      'Hapus berkas',
                                      'Berkas tidak dapat dihapus.',
                                      backgroundColor: AppTheme.warningColor
                                          .withOpacity(0.9),
                                      colorText: Colors.white,
                                    );
                                    break;
                                  }
                                  final repo = DocumentRepository();
                                  await repo.deleteDocument(doc.id);
                                  final dashboardController =
                                      Get.find<DashboardController>();
                                  dashboardController.documents.removeAt(index);
                                  Get.snackbar(
                                    'Berhasil',
                                    'Dokumen berhasil dihapus',
                                    backgroundColor: AppTheme.statusApproved,
                                    colorText: Colors.white,
                                  );
                                } catch (e) {
                                  Get.snackbar(
                                    'Error',
                                    'Gagal menghapus dokumen: $e',
                                    backgroundColor: AppTheme.errorColor,
                                    colorText: Colors.white,
                                  );
                                }
                                break;
                            }
                          },
                          // Menampilkan menu kondisional berdasarkan qParam
                          itemBuilder: (context) {
                            if (qp == '2') {
                              return [
                                PopupMenuItem(
                                  value: 'detail',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.info_outline),
                                      SizedBox(width: 8),
                                      Text('Detail'),
                                    ],
                                  ),
                                ),
                              ];
                            }
                            return [
                              const PopupMenuItem(
                                value: 'view',
                                child: Text('Lihat'),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      try {
                        final result = await Get.toNamed(
                          AppRoutes.documentDetail,
                          arguments: doc,
                        );
                        if (result == 'deleted') {
                          await dashboardController.refreshDocuments();
                        }
                      } catch (e) {
                        Get.snackbar(
                          'Error',
                          'Gagal membuka detail: $e',
                          backgroundColor: AppTheme.errorColor,
                          colorText: Colors.white,
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Obx(
        () {
          final user = authController.currentUser.value;
          if (user != null && user.role.canSubmitDocuments) {
            return FloatingActionButton.extended(
              onPressed: () {
                Get.toNamed(AppRoutes.documentForm)?.then((result) {
                  if (result != null) {
                    dashboardController.refreshDocuments();
                  }
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Pengajuan Berkas'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
