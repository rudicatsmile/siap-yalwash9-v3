import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../../data/services/api_service.dart';
import '../../controllers/dropdown_controller.dart';
import '../../controllers/last_no_surat_controller.dart';
import '../../widgets/form/api_dropdown_field.dart';
import 'package:siap/presentation/utils/doc_number_logic.dart';
import 'package:intl/intl.dart';

/// Document form screen for creating and editing documents
class DocumentFormScreen extends StatefulWidget {
  const DocumentFormScreen({super.key});

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  final authController = Get.find<AuthController>();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _perihalController = TextEditingController();
  final _docNumberPart1Controller = TextEditingController();
  final _docNumberPart2Controller = TextEditingController();
  bool _isDocNumberPart2ReadOnly = false;
  final _todayDateController = TextEditingController();
  final _pengirimController = TextEditingController();
  final _isLoading = false.obs;
  final _letterDateController = TextEditingController();
  DateTime? _selectedLetterDate;
  final _letterNumberPart1Controller = TextEditingController();
  final _letterNumberPart2Controller = TextEditingController();
  final _ringkasanController = TextEditingController();
  static const List<String> _romanMonths = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'XI',
    'XII'
  ];

  DocumentModel? _existingDocument;
  bool _isEditMode = false;
  late final DropdownController _kategoriController;
  late final DropdownController _jenisController;
  late final DropdownController _kategoriLaporanController;
  late final DropdownController _tujuanDisposisiController;
  late final _UsersDropdownController _usersDropdownController;
  late final LastNoSuratController _lastNoSuratController;
  // Workers to observe GetX state changes for last-no-surat fetching
  late final Worker _lastNoSuratResultWorker;
  late final Worker _lastNoSuratErrorWorker;
  late final Worker _kategoriWorker;
  late final Worker _jenisWorker;
  late final Worker _kategoriLaporanWorker;
  late final Worker _kategoriItemsOnce;
  late final Worker _jenisItemsOnce;
  late final Worker _kategoriLaporanItemsOnce;
  late final Worker _part2SyncWorker;

  // Mendapatkan deskripsi item terpilih dari DropdownController.
  // Digunakan untuk membedakan kategori: Dokumen, Undangan, Laporan.
  String? _getSelectedDeskripsi(DropdownController ctrl) {
    final kode = ctrl.selectedKode.value;
    final match = ctrl.items.where((it) => it.kode == kode);
    if (match.isEmpty) return null;
    return match.first.deskripsi;
  }

  // Mereset nilai bagian kedua nomor dokumen saat kategori berganti.
  void _resetDocNumberPart2() {
    _docNumberPart2Controller.text = '';
  }

  // Mengatur nilai bagian kedua nomor dokumen berdasarkan kategori formulir.
  // - Dokumen: menggunakan kode dari dropdown Jenis Dokumen
  // - Undangan: diset statis 'UND' dan readonly
  // - Laporan: menggunakan kode dari dropdown Kategori Laporan
  void _handleKategoriChanged(String? kode) {
    final kategoriDesc =
        _getSelectedDeskripsi(_kategoriController)?.toLowerCase().trim() ?? '';
    _resetDocNumberPart2();
    if (kategoriDesc.contains('undangan')) {
      _isDocNumberPart2ReadOnly = true;
      _docNumberPart2Controller.text = 'UND';
    } else if (kode == 'Rapat') {
      _isDocNumberPart2ReadOnly = true;
      _docNumberPart2Controller.text = 'RPT';
    } else if (kategoriDesc.contains('dokumen')) {
      _isDocNumberPart2ReadOnly = false;
      final jenisKode = _jenisController.selectedKode.value;
      if (jenisKode.isEmpty) {
        Get.snackbar(
          'Error',
          'Jenis dokumen harus dipilih untuk menentukan nomor dokumen',
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        _docNumberPart2Controller.text = jenisKode;
      }
    } else if (kategoriDesc.contains('laporan')) {
      _isDocNumberPart2ReadOnly = false;
      final laporanKode = _kategoriLaporanController.selectedKode.value;
      if (laporanKode.isEmpty) {
        Get.snackbar(
          'Error',
          'Kategori laporan harus dipilih untuk menentukan nomor dokumen',
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        _docNumberPart2Controller.text = laporanKode;
      }
    } else {
      _isDocNumberPart2ReadOnly = false;
    }
    setState(() {});
  }

  // Update nilai bagian kedua saat Jenis Dokumen berubah jika kategori adalah Dokumen.
  void _handleJenisDokumenChanged(String? kode) {
    final kategoriDesc =
        _getSelectedDeskripsi(_kategoriController)?.toLowerCase().trim() ?? '';
    if (kategoriDesc.contains('dokumen')) {
      _docNumberPart2Controller.text = (kode ?? '').trim();
      setState(() {});
    }
  }

  // Update nilai bagian kedua saat Kategori Laporan berubah jika kategori adalah Laporan.
  void _handleKategoriLaporanChanged(String? kode) {
    final kategoriDesc =
        _getSelectedDeskripsi(_kategoriController)?.toLowerCase().trim() ?? '';
    if (kategoriDesc.contains('laporan')) {
      _docNumberPart2Controller.text = (kode ?? '').trim();
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    final user = authController.currentUser.value;
    _pengirimController.text = user?.instansi ?? '';

    _kategoriController = Get.put(DropdownController(), tag: 'kategori');
    _jenisController = Get.put(DropdownController(), tag: 'jenis');
    _kategoriLaporanController =
        Get.put(DropdownController(), tag: 'kategori_laporan');
    _tujuanDisposisiController =
        Get.put(DropdownController(), tag: 'tujuan_disposisi');
    _usersDropdownController =
        Get.put(_UsersDropdownController(), tag: 'users_dropdown');

    _lastNoSuratController =
        Get.put(LastNoSuratController(), tag: 'last_no_surat');

    _initializeForm();
    _kategoriController.loadTable('m_kategori_formulir');
    _jenisController.loadTable('m_jenis_dokumen');
    _kategoriLaporanController.loadTable('m_kategori_laporan');
    _tujuanDisposisiController.loadTable('m_tujuan_disposisi');
    _usersDropdownController.loadUsers();
    _lastNoSuratController.fetch();

    // Preselect defaults once data is loaded
    _kategoriItemsOnce = once(_kategoriController.items, (_) {
      if (_kategoriController.items.isNotEmpty &&
          _kategoriController.selectedKode.value.isEmpty) {
        final dok = _kategoriController.items.firstWhere(
          (it) => it.deskripsi.toLowerCase().contains('dokumen'),
          orElse: () => _kategoriController.items.first,
        );
        _kategoriController.select(dok.kode);
        _handleKategoriChanged(dok.kode);
      }
    });
    _jenisItemsOnce = once(_jenisController.items, (_) {
      final kategoriDesc =
          _getSelectedDeskripsi(_kategoriController)?.toLowerCase().trim() ??
              '';
      if (_jenisController.items.isNotEmpty &&
          _jenisController.selectedKode.value.isEmpty &&
          kategoriDesc.contains('dokumen')) {
        final first = _jenisController.items.first;
        _jenisController.select(first.kode);
        _handleJenisDokumenChanged(first.kode);
      }
    });
    _kategoriLaporanItemsOnce = once(_kategoriLaporanController.items, (_) {
      final kategoriDesc =
          _getSelectedDeskripsi(_kategoriController)?.toLowerCase().trim() ??
              '';
      if (_kategoriLaporanController.items.isNotEmpty &&
          _kategoriLaporanController.selectedKode.value.isEmpty &&
          kategoriDesc.contains('laporan')) {
        final first = _kategoriLaporanController.items.first;
        _kategoriLaporanController.select(first.kode);
        _handleKategoriLaporanChanged(first.kode);
      }
    });

    _part2SyncWorker = everAll(
      [
        _kategoriController.selectedKode,
        _jenisController.selectedKode,
        _kategoriLaporanController.selectedKode,
      ],
      (_) => _syncDocNumberPart2(),
    );

    // When API returns next_no_surat, prefill part-1 document number
    _lastNoSuratResultWorker = ever(_lastNoSuratController.result, (res) {
      if (res != null && res.nextNoSurat.isNotEmpty) {
        _docNumberPart1Controller.text = res.nextNoSurat;
      }
    });

    // Show error message when API call fails or returns invalid format
    _lastNoSuratErrorWorker = ever(_lastNoSuratController.error, (msg) {
      if (msg is String && msg.isNotEmpty) {
        Get.snackbar(
          'Error',
          msg,
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    });

    // Keep part-2 synced with selections
    _kategoriWorker = ever(_kategoriController.selectedKode, (val) {
      _handleKategoriChanged(val);
    });
    _jenisWorker = ever(_jenisController.selectedKode, (val) {
      _handleJenisDokumenChanged(val);
    });
    _kategoriLaporanWorker =
        ever(_kategoriLaporanController.selectedKode, (val) {
      _handleKategoriLaporanChanged(val);
    });

    final now = DateTime.now();
    _todayDateController.text =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    _selectedLetterDate = now;
    _letterDateController.text = DateFormat('dd-MM-yyyy').format(now);
    _computeLetterNumberPart2();
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
    _perihalController.dispose();
    _docNumberPart1Controller.dispose();
    _docNumberPart2Controller.dispose();
    _todayDateController.dispose();
    _letterDateController.dispose();
    _letterNumberPart1Controller.dispose();
    _letterNumberPart2Controller.dispose();
    _ringkasanController.dispose();
    // Dispose workers to avoid memory leaks
    _lastNoSuratResultWorker.dispose();
    _lastNoSuratErrorWorker.dispose();
    _kategoriWorker.dispose();
    _jenisWorker.dispose();
    _kategoriLaporanWorker.dispose();
    _kategoriItemsOnce.dispose();
    _jenisItemsOnce.dispose();
    _kategoriLaporanItemsOnce.dispose();
    _part2SyncWorker.dispose();
    super.dispose();
  }

  void _syncDocNumberPart2() {
    final kategoriDesc =
        _getSelectedDeskripsi(_kategoriController)?.toLowerCase().trim() ?? '';
    final jenisKode = _jenisController.selectedKode.value;
    final laporanKode = _kategoriLaporanController.selectedKode.value;
    final decision = decideDocNumberPart2(
      kategoriDesc,
      jenisKode: jenisKode,
      laporanKode: laporanKode,
    );
    _isDocNumberPart2ReadOnly = decision.readOnly;
    _docNumberPart2Controller.text = decision.value;
    setState(() {});
  }

  void _computeLetterNumberPart2() {
    DateTime date;
    try {
      date = DateFormat('dd-MM-yyyy').parseStrict(_todayDateController.text);
    } catch (_) {
      date = DateTime.now();
    }
    final roman = _romanMonths[date.month - 1];
    final yyyy = date.year.toString();
    _letterNumberPart2Controller.text = 'YALWASH-9/$roman/$yyyy';
    setState(() {});
  }

  void _handleTodayDateChanged(String v) {
    try {
      final d = DateFormat('dd-MM-yyyy').parseStrict(v.trim());
      final roman = _romanMonths[d.month - 1];
      _letterNumberPart2Controller.text = 'YALWASH-9/$roman/${d.year}';
      setState(() {});
    } catch (_) {
      // keep previous value; invalid input ignored
    }
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
                        onChanged: (val) {
                          _handleKategoriChanged(val);
                        },
                        itemTextBuilder: (it) => it.deskripsi,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kategori formulir harus dipilih';
                          }
                          return null;
                        },
                      ),

                      // const SizedBox(height: 12),
                      // Obx(() {
                      //   if (_lastNoSuratController.isLoading.value) {
                      //     return const SizedBox(
                      //       height: 56,
                      //       child: Center(child: CircularProgressIndicator()),
                      //     );
                      //   }
                      //   if (_lastNoSuratController.error.isNotEmpty) {
                      //     return Container(
                      //       padding: const EdgeInsets.all(12),
                      //       decoration: BoxDecoration(
                      //         color: AppTheme.errorColor.withOpacity(0.08),
                      //         borderRadius: BorderRadius.circular(8),
                      //         border: Border.all(
                      //           color: AppTheme.errorColor.withOpacity(0.3),
                      //         ),
                      //       ),
                      //       child: Text(
                      //         _lastNoSuratController.error.value,
                      //         style:
                      //             const TextStyle(color: AppTheme.errorColor),
                      //       ),
                      //     );
                      //   }
                      //   final data = _lastNoSuratController.result.value;
                      //   if (data == null) {
                      //     return const SizedBox.shrink();
                      //   }
                      //   return Card(
                      //     elevation: 2,
                      //     child: Padding(
                      //       padding: const EdgeInsets.all(12.0),
                      //       child: Column(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //           Row(
                      //             children: const [
                      //               Icon(Icons.info_outline, size: 18),
                      //               SizedBox(width: 8),
                      //               Text(
                      //                 'Informasi Nomor Surat',
                      //                 style: TextStyle(
                      //                     fontWeight: FontWeight.bold),
                      //               ),
                      //             ],
                      //           ),
                      //           const SizedBox(height: 8),
                      //           Text('Last No Surat: ${data.lastNoSurat}'),
                      //           Text('Next No Surat: ${data.nextNoSurat}'),
                      //           Text('Timestamp: ${data.timestamp}'),
                      //         ],
                      //       ),
                      //     ),
                      //   );
                      // }),
                      const SizedBox(height: 16),

                      Text(
                        'Nomor dokumen',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: TextFormField(
                              controller: _docNumberPart1Controller,
                              readOnly: true,
                              decoration: const InputDecoration(
                                // hintText: 'Nomor',
                                border: OutlineInputBorder(),
                                prefixIcon:
                                    Icon(Icons.confirmation_number_outlined),
                              ),
                              // Validate that auto-filled or edited number is digits-only
                              validator: (value) {
                                final v = (value ?? '').trim();
                                if (v.isEmpty) {
                                  return 'Nomor dokumen harus diisi';
                                }
                                final isDigits = RegExp(r'^\d+$').hasMatch(v);
                                if (!isDigits) {
                                  return 'Nomor dokumen berupa angka';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 7,
                            child: TextFormField(
                              readOnly: _isDocNumberPart2ReadOnly,
                              controller: _docNumberPart2Controller,
                              decoration: const InputDecoration(
                                // hintText: 'Bagian 2',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.tag_outlined),
                              ),
                              // validator: (value) {
                              //   final kategoriDesc =
                              //       _getSelectedDeskripsi(_kategoriController)
                              //               ?.toLowerCase()
                              //               .trim() ??
                              //           '';
                              //   final v = (value ?? '').trim();
                              //   if (kategoriDesc.contains('undangan')) {
                              //     if (v != 'UND') {
                              //       return 'Nomor dokumen Undangan harus bernilai UND';
                              //     }
                              //     return null;
                              //   }
                              //   if (kategoriDesc.contains('rapat')) {
                              //     if (v != 'RPT') {
                              //       return 'Nomor dokumen Rapat harus bernilai RPT';
                              //     }
                              //     return null;
                              //   }
                              //   if (kategoriDesc.contains('dokumen')) {
                              //     if (v.isEmpty) {
                              //       return 'Jenis dokumen harus dipilih';
                              //     }
                              //     return null;
                              //   }
                              //   if (kategoriDesc.contains('laporan')) {
                              //     if (v.isEmpty) {
                              //       return 'Kategori laporan harus dipilih';
                              //     }
                              //     return null;
                              //   }
                              //   // Default: allow empty or user-defined
                              //   return null;
                              // },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Text(
                        'Tanggal buat',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextFormField(
                        controller: _todayDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          // labelText: 'Tanggal Hari Ini',
                          hintText: 'dd-mm-yyyy',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        onChanged: _handleTodayDateChanged,
                      ),

                      //Tambahkan TextFormFiled untuk input Pengirim berkas
                      const SizedBox(height: 16),
                      Text(
                        'Pengirim',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextFormField(
                        controller: _pengirimController,
                        decoration: const InputDecoration(
                          // labelText: 'Pengirim Berkas',
                          hintText: 'Masukkan nama pengirim berkas',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                      ),

                      const SizedBox(height: 24),
                      ApiDropdownField(
                        label: 'Jenis Dokumen',
                        placeholder: 'Pilih Jenis Dokumen',
                        tableName: 'm_jenis_dokumen',
                        controller: _jenisController,
                        onChanged: (val) {
                          _handleJenisDokumenChanged(val);
                        },
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
                        onChanged: (val) {
                          _handleKategoriLaporanChanged(val);
                        },
                        itemTextBuilder: (it) => it.deskripsi,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kategori laporan harus dipilih';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Dropdown User Undangan (sumber data dari /api/users/dropdown dengan parameter kode_user=YS)
                      Text(
                        'Undangan kepada',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                            // labelText: 'Undangan Kepada',
                            hintText: 'Pilih undangan kepada',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        );
                      }),

                      //Tambahkan input tanggal berinama 'Tanggal Surat', dengan default tanggal hari ini. Format tanggal dd-MM-yyyy
                      Text(
                        'Tanggal Surat',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextFormField(
                        controller: _letterDateController,
                        decoration: const InputDecoration(
                          hintText: 'dd-MM-yyyy',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) {
                            return 'Tanggal surat harus diisi';
                          }
                          try {
                            DateFormat('dd-MM-yyyy').parseStrict(v);
                          } catch (_) {
                            return 'Format tanggal tidak valid (dd-MM-yyyy)';
                          }
                          return null;
                        },
                        onTap: () async {
                          final initial = _selectedLetterDate ?? DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(2000, 1, 1),
                            lastDate: DateTime(2100, 12, 31),
                          );
                          if (picked != null) {
                            _selectedLetterDate = picked;
                            _letterDateController.text =
                                DateFormat('dd-MM-yyyy').format(picked);
                            setState(() {});
                            _handleTodayDateChanged(_letterDateController.text);
                          }
                        },
                        onChanged: (v) {
                          try {
                            _selectedLetterDate =
                                DateFormat('dd-MM-yyyy').parseStrict(v.trim());
                          } catch (_) {
                            _selectedLetterDate = null;
                          }
                          _handleTodayDateChanged(v);
                        },
                      ),

                      //Tambahkan Nomor surat yang terdiri dari 2 buah textfield, yaitu bagian 1 dan bagian 2.
                      //Bagian 1: Nomor surat yang diinput oleh pengguna
                      //Bagian 2: Gabungan kata dan angka yang tergantung dari bulan controller _todayDateController
                      Text(
                        'Nomor Surat',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: _letterNumberPart1Controller,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon:
                                    Icon(Icons.confirmation_number_outlined),
                                hintText: 'Nomor',
                              ),
                              validator: (value) {
                                final v = (value ?? '').trim();
                                if (v.isEmpty) {
                                  return 'Nomor surat harus diisi';
                                }
                                final isAllowed =
                                    RegExp(r'^[0-9.]+$').hasMatch(v);
                                if (!isAllowed) {
                                  return 'Nomor harus angka atau titik';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 6,
                            child: TextFormField(
                              controller: _letterNumberPart2Controller,
                              readOnly: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                // prefixIcon: Icon(Icons.tag_outlined),
                                // hintText: 'Kode Bulan-Tahun',
                              ),
                              validator: (value) {
                                final v = (value ?? '').trim();
                                if (v.isEmpty) {
                                  return 'nomor surat  tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Perihal',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextFormField(
                        controller: _perihalController,
                        decoration: const InputDecoration(
                          // labelText: 'Perihal',
                          hintText: 'Masukkan perihal surat',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Ringkasan',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextFormField(
                        controller: _ringkasanController,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan ringkasan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes_outlined),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),

                      //Do Todo

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
        'tanggal_surat': _letterDateController.text.trim(),
        'perihal': _perihalController.text.trim(),
        'ringkasan': _ringkasanController.text.trim(),
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
