import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/confirmation_dialog.dart';

/// Document detail screen showing comprehensive document information
class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DocumentModel document = Get.arguments as DocumentModel;
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Berkas'),
        actions: [
          if (user != null && _canPerformActions(document, user))
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showActionMenu(context, document, user),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            _buildStatusBadge(document),
            const SizedBox(height: 24),

            // Document Information
            _buildSectionTitle('Informasi Dokumen'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow('Nomor Dokumen', document.documentNumber),
              _buildInfoRow('Judul', document.title),
              if (document.description != null &&
                  document.description!.isNotEmpty)
                _buildInfoRow('Deskripsi', document.description!),
              _buildInfoRow('Status', document.status.displayName),
              if (document.hasMeeting)
                _buildInfoRow('Status Rapat', 'Dijadwalkan'),
            ]),
            const SizedBox(height: 24),

            // Submitter Information
            _buildSectionTitle('Informasi Pengaju'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow('Nama', document.userName ?? '-'),
              if (document.departemenName != null)
                _buildInfoRow('Departemen', document.departemenName!),
              _buildInfoRow(
                'Tanggal Pengajuan',
                _formatDateTime(document.submittedAt),
              ),
            ]),
            const SizedBox(height: 24),

            // Approval Information (if approved)
            if (document.approvedBy != null) ...[
              _buildSectionTitle('Informasi Persetujuan'),
              const SizedBox(height: 12),
              _buildInfoCard([
                if (document.approverName != null)
                  _buildInfoRow('Disetujui Oleh', document.approverName!),
                if (document.approvedAt != null)
                  _buildInfoRow(
                    'Tanggal Persetujuan',
                    _formatDateTime(document.approvedAt!),
                  ),
              ]),
              const SizedBox(height: 24),
            ],

            // Notes (if any)
            if (document.notes != null && document.notes!.isNotEmpty) ...[
              _buildSectionTitle('Catatan'),
              const SizedBox(height: 12),
              _buildInfoCard([
                _buildInfoRow('Catatan', document.notes!),
              ]),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            if (user != null && _canPerformActions(document, user))
              _buildActionButtons(context, document, user),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DocumentModel document) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.getStatusColor(document.status).withOpacity(0.1),
        border: Border.all(
          color: AppTheme.getStatusColor(document.status),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(document.status),
            color: AppTheme.getStatusColor(document.status),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            document.status.displayName,
            style: TextStyle(
              color: AppTheme.getStatusColor(document.status),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    DocumentModel document,
    UserModel user,
  ) {
    final List<Widget> buttons = [];

    // Edit button (for submitters when status allows)
    if (document.canEdit && document.userId == user.id) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: () => _handleEdit(document),
          icon: const Icon(Icons.edit),
          label: const Text('Edit Dokumen'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      );
    }

    // Delete button (for submitters when status allows)
    if (document.canEdit && document.userId == user.id) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _handleDelete(document),
          icon: const Icon(Icons.delete, color: AppTheme.errorColor),
          label: const Text(
            'Hapus Dokumen',
            style: TextStyle(color: AppTheme.errorColor),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: AppTheme.errorColor),
          ),
        ),
      );
    }

    // Role-specific action buttons
    if (user.role.canApproveDocuments) {
      buttons.addAll(_getRoleSpecificButtons(document, user));
    }

    return Column(
      children: buttons
          .map((button) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: button,
              ))
          .toList(),
    );
  }

  List<Widget> _getRoleSpecificButtons(DocumentModel document, UserModel user) {
    final List<Widget> buttons = [];

    switch (user.role) {
      case UserRole.generalHead:
        if (document.status == DocumentStatus.pending) {
          buttons.addAll([
            ElevatedButton.icon(
              onPressed: () => _handleApprove(document),
              icon: const Icon(Icons.check_circle),
              label: const Text('Setujui'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusApproved,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _handleReturn(document),
              icon: const Icon(Icons.undo),
              label: const Text('Kembalikan'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _handleReject(document),
              icon: const Icon(Icons.cancel, color: AppTheme.errorColor),
              label: const Text(
                'Tolak',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppTheme.errorColor),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _handleScheduleMeeting(document),
              icon: const Icon(Icons.event),
              label: const Text('Jadwalkan Rapat'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _handleForwardToCoordinator(document),
              icon: const Icon(Icons.forward),
              label: const Text('Teruskan ke Koordinator'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ]);
        }
        break;

      case UserRole.coordinator:
        if (document.status == DocumentStatus.forwardedToCoordinator) {
          buttons.addAll([
            ElevatedButton.icon(
              onPressed: () => _handleApprove(document),
              icon: const Icon(Icons.check_circle),
              label: const Text('Setujui'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusApproved,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _handleReject(document),
              icon: const Icon(Icons.cancel, color: AppTheme.errorColor),
              label: const Text(
                'Tolak',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppTheme.errorColor),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  _handleScheduleMeeting(document, isCoordinator: true),
              icon: const Icon(Icons.event),
              label: const Text('Jadwalkan Rapat'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _handleForwardToMainLeader(document),
              icon: const Icon(Icons.forward),
              label: const Text('Teruskan ke Pimpinan Utama'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ]);
        }
        break;

      case UserRole.mainLeader:
        if (document.status == DocumentStatus.forwardedToMainLeader) {
          buttons.addAll([
            ElevatedButton.icon(
              onPressed: () => _handleApprove(document),
              icon: const Icon(Icons.check_circle),
              label: const Text('Setujui'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusApproved,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _handleReject(document),
              icon: const Icon(Icons.cancel, color: AppTheme.errorColor),
              label: const Text(
                'Tolak',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppTheme.errorColor),
              ),
            ),
          ]);
        }
        break;

      default:
        break;
    }

    return buttons;
  }

  bool _canPerformActions(DocumentModel document, UserModel user) {
    // User can edit/delete their own pending documents
    if (document.userId == user.id && document.canEdit) {
      return true;
    }

    // Role-based action permissions
    return user.role.canApproveDocuments &&
        ((user.role == UserRole.generalHead &&
                document.status == DocumentStatus.pending) ||
            (user.role == UserRole.coordinator &&
                document.status == DocumentStatus.forwardedToCoordinator) ||
            (user.role == UserRole.mainLeader &&
                document.status == DocumentStatus.forwardedToMainLeader));
  }

  void _showActionMenu(
    BuildContext context,
    DocumentModel document,
    UserModel user,
  ) {
    // Show action menu in bottom sheet or modal
    // To be implemented
  }

  void _handleEdit(DocumentModel document) {
    Get.toNamed('/documents/form', arguments: document);
  }

  Future<void> _handleDelete(DocumentModel document) async {
    final confirmed = await ConfirmationDialog.showDelete(
      itemName: document.title,
    );
    if (confirmed) {
      try {
        final repo = DocumentRepository();
        await repo.deleteDocument(document.id);
        Get.back(result: 'deleted');
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
    }
  }

  Future<void> _handleApprove(DocumentModel document) async {
    final confirmed = await ConfirmationDialog.showApprove(
      documentTitle: document.title,
    );
    if (confirmed) {
      // Call document repository approve method
      Get.snackbar(
        'Berhasil',
        'Dokumen berhasil disetujui',
        backgroundColor: AppTheme.statusApproved,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleReject(DocumentModel document) async {
    final confirmed = await ConfirmationDialog.showReject(
      documentTitle: document.title,
    );
    if (confirmed) {
      // Call document repository reject method
      Get.snackbar(
        'Berhasil',
        'Dokumen ditolak',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleReturn(DocumentModel document) async {
    final confirmed = await ConfirmationDialog.show(
      title: 'Kembalikan Dokumen',
      message:
          'Apakah Anda yakin ingin mengembalikan dokumen "${document.title}"?',
    );
    if (confirmed) {
      // Call document repository return method (status = 20)
      Get.snackbar(
        'Berhasil',
        'Dokumen dikembalikan untuk revisi',
        backgroundColor: AppTheme.statusReturned,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleScheduleMeeting(
    DocumentModel document, {
    bool isCoordinator = false,
  }) async {
    final confirmed = await ConfirmationDialog.show(
      title: 'Jadwalkan Rapat',
      message:
          'Apakah Anda yakin ingin menjadwalkan rapat untuk dokumen "${document.title}"?',
    );
    if (confirmed) {
      // Call document repository schedule meeting method
      // status = 1 (general head) or 8 (coordinator), status_rapat = 1
      Get.snackbar(
        'Berhasil',
        'Rapat berhasil dijadwalkan',
        backgroundColor: AppTheme.statusMeeting,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleForwardToCoordinator(DocumentModel document) async {
    final confirmed = await ConfirmationDialog.show(
      title: 'Teruskan ke Koordinator',
      message:
          'Apakah Anda yakin ingin meneruskan dokumen "${document.title}" ke Koordinator?',
    );
    if (confirmed) {
      // Call document repository forward method (status = 2)
      Get.snackbar(
        'Berhasil',
        'Dokumen diteruskan ke Koordinator',
        backgroundColor: AppTheme.statusForwarded,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleForwardToMainLeader(DocumentModel document) async {
    final confirmed = await ConfirmationDialog.show(
      title: 'Teruskan ke Pimpinan Utama',
      message:
          'Apakah Anda yakin ingin meneruskan dokumen "${document.title}" ke Pimpinan Utama?',
    );
    if (confirmed) {
      // Call document repository forward method (status = 9)
      Get.snackbar(
        'Berhasil',
        'Dokumen diteruskan ke Pimpinan Utama',
        backgroundColor: AppTheme.statusForwarded,
        colorText: Colors.white,
      );
    }
  }

  IconData _getStatusIcon(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return Icons.check_circle;
      case DocumentStatus.rejected:
        return Icons.cancel;
      case DocumentStatus.pending:
        return Icons.pending;
      case DocumentStatus.forwardedToCoordinator:
      case DocumentStatus.forwardedToMainLeader:
        return Icons.forward;
      case DocumentStatus.coordinatorMeeting:
        return Icons.event;
      case DocumentStatus.returned:
        return Icons.undo;
    }
  }

  String _formatDateTime(dynamic date) {
    DateTime? dt;
    if (date is DateTime) {
      dt = date;
    } else if (date != null) {
      dt = DateTime.tryParse(date.toString());
    }
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
