import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../../data/services/api_service.dart';
import '../../controllers/dropdown_controller.dart';
import '../../widgets/form/api_dropdown_field.dart';

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
  late final DropdownController _kategoriController;
  late final DropdownController _jenisController;
  late final DropdownController _kategoriLaporanController;
  late final _UsersDropdownController _usersDropdownController;

  @override
  void initState() {
    super.initState();
    _kategoriController = Get.put(DropdownController(), tag: 'kategori');
    _jenisController = Get.put(DropdownController(), tag: 'jenis');
    _kategoriLaporanController =
        Get.put(DropdownController(), tag: 'kategori_laporan');
    _usersDropdownController =
        Get.put(_UsersDropdownController(), tag: 'users_dropdown');
    _initializeForm();
    _kategoriController.loadTable('m_kategori_formulir');
    _jenisController.loadTable('m_jenis_dokumen');
    _kategoriLaporanController.loadTable('m_kategori_laporan');
    _usersDropdownController.loadUsers();
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
        title: Text(
            _isEditMode ? 'Edit Pengajuan Berkas' : 'Buat Pengajuan Berkas'),
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
                      // Kategori Formulir: tampilkan "kode - deskripsi" dari m_kategori_formulir
                      ApiDropdownField(
                        label: 'Kategori Formulir',
                        placeholder: 'Pilih Kategori Formulir',
                        tableName: 'm_kategori_formulir',
                        controller: _kategoriController,
                        itemTextBuilder: (it) => it.deskripsi,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kategori formulir harus dipilih';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ApiDropdownField(
                        label: 'Jenis Dokumen',
                        placeholder: 'Pilih Jenis Dokumen',
                        tableName: 'm_jenis_dokumen',
                        controller: _jenisController,
                        itemTextBuilder: (it) => it.deskripsi,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jenis dokumen harus dipilih';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),
                      ApiDropdownField(
                        label: 'Kategori Laporan',
                        placeholder: 'Pilih Kategori Laporan',
                        tableName: 'm_kategori_laporan',
                        controller: _kategoriLaporanController,
                        itemTextBuilder: (it) => it.deskripsi,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kategori laporan harus dipilih';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Dropdown User (sumber data dari /api/users/dropdown dengan parameter kode_user=YS)
                      Obx(() {
                        if (_usersDropdownController.isLoading.value &&
                            _usersDropdownController.items.isEmpty) {
                          return const SizedBox(
                            height: 56,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (_usersDropdownController.error.isNotEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.errorColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _usersDropdownController.error.value,
                              style:
                                  const TextStyle(color: AppTheme.errorColor),
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: _usersDropdownController
                                  .selectedUserId.value.isEmpty
                              ? null
                              : _usersDropdownController.selectedUserId.value,
                          items: _usersDropdownController.items
                              .map(
                                (u) => DropdownMenuItem<String>(
                                  value: u.id,
                                  child: Text(u.namaLengkap),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              _usersDropdownController.select(val),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'User harus dipilih';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Undangan Kepada',
                            hintText: 'Pilih undangan kepada',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Berkas',
                          hintText: 'Masukkan judul berkas',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Judul berkas harus diisi';
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
                  ? 'Anda dapat mengedit pengajuan berkas selama status masih pending dan belum disetujui.'
                  : 'Pengajuan berkas akan diajukan dengan status pending setelah disimpan.',
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
              'Informasi User',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildUserInfoRow('Nama', user.namaLengkap),
            _buildUserInfoRow('Jabatan', user.jabatan),
            _buildUserInfoRow('Instansi', user.instansi ?? '-'),
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
            label: Text(_isEditMode ? 'Simpan Perubahan' : 'Ajukan Berkas'),
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
          'Pengajuan berkas berhasil diperbarui',
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
          'Pengajuan berkas berhasil diajukan',
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
        title:
            Text(_isEditMode ? 'Konfirmasi Perubahan' : 'Konfirmasi Pengajuan'),
        content: Text(
          _isEditMode
              ? 'Apakah Anda yakin ingin menyimpan perubahan berkas ini?'
              : 'Apakah Anda yakin ingin mengajukan berkas ini?',
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

/// GetX controller untuk dropdown user yang mengambil data dari API `/api/users/dropdown`
/// - Mengelola state loading/error
/// - Menyimpan daftar user dan nilai yang dipilih
/// - Melakukan inisialisasi data saat screen dibuka dan mendukung refresh
class _UsersDropdownController extends GetxController {
  final _api = ApiService();

  // State
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<_UserOption> items = <_UserOption>[].obs;
  final RxString selectedUserId = ''.obs;

  /// Memuat data user dari API dengan filter `kode_user=YS`
  Future<void> loadUsers({bool force = false}) async {
    error.value = '';
    isLoading.value = true;

    try {
      final resp = await _api.get(
        '/api/users/dropdown',
        queryParameters: {
          'kode_user': 'YS',
          'limit': 100,
        },
      );

      final data = resp.data;
      if (data is Map && data['success'] == true && data['data'] is List) {
        final list = (data['data'] as List)
            .map((e) => _UserOption(
                  id: (e['id']?.toString() ?? '').trim(),
                  namaLengkap: (e['nama_lengkap']?.toString() ?? '').trim(),
                  username: (e['username']?.toString() ?? '').trim(),
                  jabatan: e['jabatan']?.toString(),
                ))
            .where((u) => u.id.isNotEmpty && u.namaLengkap.isNotEmpty)
            .toList();
        items.assignAll(list);
      } else {
        items.clear();
        error.value = 'Data pengguna tidak tersedia';
      }
    } catch (e) {
      error.value = e.toString();
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Menyimpan nilai user terpilih
  void select(String? id) {
    selectedUserId.value = (id ?? '').trim();
  }

  /// Melakukan refresh data dari API
  Future<void> refreshUsers() async {
    await loadUsers(force: true);
  }
}

/// Representasi opsi user untuk dropdown
class _UserOption {
  final String id;
  final String namaLengkap;
  final String username;
  final String? jabatan;
  _UserOption({
    required this.id,
    required this.namaLengkap,
    required this.username,
    this.jabatan,
  });
}
