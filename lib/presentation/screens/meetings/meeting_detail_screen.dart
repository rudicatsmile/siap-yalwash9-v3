import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/confirmation_dialog.dart';

/// Meeting detail screen for managing meeting decisions
class MeetingDetailScreen extends StatelessWidget {
  const MeetingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DocumentModel document = Get.arguments as DocumentModel;
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Rapat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meeting indicator banner
            _buildMeetingBanner(),
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

            // Notes (if any)
            if (document.notes != null && document.notes!.isNotEmpty) ...[
              _buildSectionTitle('Catatan'),
              const SizedBox(height: 12),
              _buildInfoCard([
                _buildInfoRow('Catatan', document.notes!),
              ]),
              const SizedBox(height: 24),
            ],

            // Meeting decision section
            if (user != null && _canMakeDecision(user)) ...[
              _buildSectionTitle('Keputusan Rapat'),
              const SizedBox(height: 12),
              _buildDecisionInfo(),
              const SizedBox(height: 16),
              _buildDecisionButtons(document, user),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.statusMeeting.withOpacity(0.1),
        border: Border.all(
          color: AppTheme.statusMeeting,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Icon(
            Icons.event,
            color: AppTheme.statusMeeting,
            size: 32,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rapat Dijadwalkan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.statusMeeting,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Dokumen ini memerlukan keputusan rapat',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.statusMeeting,
                  ),
                ),
              ],
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

  Widget _buildDecisionInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pilih salah satu keputusan untuk melanjutkan proses dokumen ini',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionButtons(DocumentModel document, UserModel user) {
    return Column(
      children: [
        // Accept decision
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _handleAcceptDecision(document),
            icon: const Icon(Icons.check_circle),
            label: const Text('Setujui'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusApproved,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Continue decision (back to pending)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _handleContinueDecision(document),
            icon: const Icon(Icons.loop),
            label: const Text('Lanjutkan Proses'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Reject decision
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _handleRejectDecision(document),
            icon: const Icon(Icons.cancel, color: AppTheme.errorColor),
            label: const Text(
              'Tolak',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.errorColor),
            ),
          ),
        ),
      ],
    );
  }

  bool _canMakeDecision(UserModel user) {
    // Protocol Head and General Affairs Head can make meeting decisions
    return user.role.canManageMeetings;
  }

  Future<void> _handleAcceptDecision(DocumentModel document) async {
    final confirmed = await ConfirmationDialog.show(
      title: 'Setujui Dokumen',
      message:
          'Apakah Anda yakin ingin menyetujui dokumen "${document.title}" berdasarkan keputusan rapat?',
    );

    if (confirmed) {
      // TODO: Call document repository to update status = 3, status_rapat = 0
      Get.back(result: 'approved');
      Get.snackbar(
        'Berhasil',
        'Dokumen telah disetujui',
        backgroundColor: AppTheme.statusApproved,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleContinueDecision(DocumentModel document) async {
    final confirmed = await ConfirmationDialog.show(
      title: 'Lanjutkan Proses',
      message:
          'Apakah Anda yakin ingin melanjutkan proses dokumen "${document.title}"? Status akan kembali ke pending.',
    );

    if (confirmed) {
      // TODO: Call document repository to update status = 1, status_rapat = 0
      Get.back(result: 'continued');
      Get.snackbar(
        'Berhasil',
        'Dokumen dilanjutkan ke proses berikutnya',
        backgroundColor: AppTheme.statusPending,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleRejectDecision(DocumentModel document) async {
    final confirmed = await ConfirmationDialog.showReject(
      documentTitle: document.title,
    );

    if (confirmed) {
      // TODO: Call document repository to update status = 0, status_rapat = 0
      Get.back(result: 'rejected');
      Get.snackbar(
        'Berhasil',
        'Dokumen telah ditolak',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    }
  }

  String _formatDateTime(dynamic date) {
    return DateFormatter.formatDdMMyyyyHHmm(date);
  }
}
