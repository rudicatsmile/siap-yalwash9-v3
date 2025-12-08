import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../../routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

/// Data tab with role-based dashboard
class DataTab extends StatelessWidget {
  const DataTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.put(DashboardController());
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Obx(
        () {
          if (dashboardController.isLoading.value && dashboardController.documents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboardController.documents.isEmpty) {
            return const Center(child: Text('Belum ada dokumen'));
          }

          return RefreshIndicator(
            onRefresh: dashboardController.refreshDocuments,
            child: ListView.builder(
              itemCount: dashboardController.documents.length,
              itemBuilder: (context, index) {
                final doc = dashboardController.documents[index];
                return Card(
                  child: ListTile(
                    title: Text(doc.title),
                    subtitle: Text(doc.documentNumber),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.getStatusColor(doc.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.getStatusColor(doc.status),
                        ),
                      ),
                      child: Text(
                        doc.status.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.getStatusColor(doc.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Get.toNamed(AppRoutes.documentDetail, arguments: doc);
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
              label: const Text('Buat Dokumen'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
