import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';

/// Document form screen for creating and editing documents
class DocumentFormScreen extends StatefulWidget {
  const DocumentFormScreen({super.key});

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _isLoading = false.obs;

  DocumentModel? _existingDocument;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Check if editing existing document
    if (Get.arguments != null && Get.arguments is DocumentModel) {
      _existingDocument = Get.arguments as DocumentModel;
      _isEditMode = true;
      _titleController.text = _existingDocument!.title;
      _descriptionController.text = _existingDocument!.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Dokumen' : 'Buat Dokumen Baru'),
      ),
      body: Obx(
        () => _isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Information message
                      _buildInfoMessage(),
                      const SizedBox(height: 24),

                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Dokumen',
                          hintText: 'Masukkan judul dokumen',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Judul dokumen harus diisi';
                          }
                          if (value.trim().length < 5) {
                            return 'Judul minimal 5 karakter';
                          }
                          return null;
                        },
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          hintText: 'Masukkan deskripsi dokumen (opsional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 24),

                      // User information display
                      _buildUserInfo(),
                      const SizedBox(height: 32),

                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoMessage() {
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
          Expanded(
            child: Text(
              _isEditMode
                  ? 'Anda dapat mengedit dokumen selama status masih pending dan belum disetujui.'
                  : 'Dokumen akan diajukan dengan status pending setelah disimpan.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;

    if (user == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Pengaju',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildUserInfoRow('Nama', user.namaLengkap),
            _buildUserInfoRow('Jabatan', user.jabatan),
            _buildUserInfoRow('Instansi', user.instansi),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Submit button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _handleSubmit,
            icon: Icon(_isEditMode ? Icons.save : Icons.send),
            label: Text(_isEditMode ? 'Simpan Perubahan' : 'Ajukan Dokumen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cancel button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _handleCancel,
            icon: const Icon(Icons.cancel),
            label: const Text('Batal'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    _isLoading.value = true;

    try {
      // Prepare document data
      // ignore: unused_local_variable
      final documentData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 1, // Pending status
      };

      if (_isEditMode) {
        // Update existing document
        // TODO: Call document repository update method
        await Future.delayed(const Duration(seconds: 1)); // Simulate API call

        Get.back(result: 'updated');
        Get.snackbar(
          'Berhasil',
          'Dokumen berhasil diperbarui',
          backgroundColor: AppTheme.statusApproved,
          colorText: Colors.white,
        );
      } else {
        // Create new document
        // TODO: Call document repository create method
        await Future.delayed(const Duration(seconds: 1)); // Simulate API call

        Get.back(result: 'created');
        Get.snackbar(
          'Berhasil',
          'Dokumen berhasil diajukan',
          backgroundColor: AppTheme.statusApproved,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyimpan dokumen: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> _showConfirmationDialog() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(_isEditMode ? 'Konfirmasi Perubahan' : 'Konfirmasi Pengajuan'),
        content: Text(
          _isEditMode
              ? 'Apakah Anda yakin ingin menyimpan perubahan dokumen ini?'
              : 'Apakah Anda yakin ingin mengajukan dokumen ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _handleCancel() {
    // Check if form has changes
    final hasChanges = _titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty;

    if (hasChanges) {
      Get.dialog(
        AlertDialog(
          title: const Text('Batalkan Perubahan'),
          content: const Text(
            'Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin membatalkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back(); // Close dialog
                Get.back(); // Close form screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        ),
      );
    } else {
      Get.back();
    }
  }
}
