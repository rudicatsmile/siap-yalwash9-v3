import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/document_repository.dart';
import '../../controllers/auth_controller.dart';
import '../../../data/services/api_service.dart';
import '../../controllers/dropdown_controller.dart';
import '../../controllers/last_no_surat_controller.dart';
import '../../widgets/form/api_dropdown_field.dart';
import '../../widgets/form/api_multi_select_field.dart';
import 'package:siap/presentation/utils/doc_number_logic.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../../core/constants/api_constants.dart';
import 'dart:typed_data';
import 'dart:async';
import '../../controllers/surat_masuk_controller.dart';
import 'package:logger/logger.dart';

/// Mem-parsing field `doc.ditujukan` menjadi daftar kode tujuan disposisi
/// - Memisahkan berdasarkan tag `<br>` (case-insensitive, dengan optional closing `/`)
/// - Melakukan trim pada tiap elemen dan menghapus elemen kosong
/// - Melakukan pemetaan dari deskripsi ke `kode` menggunakan `_tujuanDisposisiController.items`
/// - Mengembalikan `List<String>` berisi kode tujuan disposisi
List<String> getDataFromDocDitujukan({
  required String? raw,
  required List<DropdownItem> items,
  Logger? logger,
}) {
  try {
    if (raw == null) return [];
    final s = raw.trim();
    if (s.isEmpty) return [];

    // Pisah berdasarkan <br>, dukung variasi <br>, <br/>, <br /> dan case-insensitive
    final parts = s
        .split(RegExp(r'<br\s*/?>', caseSensitive: false))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      throw FormatException(
          'Ditujukan kosong setelah parsing. Format tidak sesuai ekspektasi.');
    }

    if (items.isEmpty) {
      // Data belum siap; tidak critical, kembalikan kosong agar diproses setelah load
      logger
          ?.w('Items tujuan disposisi belum ter-load, skip mapping sementara');
      return [];
    }

    final codes = <String>[];
    for (final p in parts) {
      final match = items.firstWhere(
        (it) => it.deskripsi.trim().toLowerCase() == p.toLowerCase(),
        orElse: () => DropdownItem(kode: '', deskripsi: ''),
      );
      if (match.kode.isNotEmpty) {
        codes.add(match.kode.trim());
      } else {
        // Jika tidak ditemukan, log dan lanjut (non-critical)
        logger?.w('Tujuan tidak dikenali, lewati: "$p"');
      }
    }

    if (codes.isEmpty) {
      throw FormatException(
          'Tidak ada tujuan yang cocok dengan daftar dropdown (mapping gagal).');
    }

    return codes;
  } catch (e) {
    logger?.e('Gagal parse doc.ditujukan: $e');
    return [];
  }
}

String? getKodeFromDocPimpinanRapat({
  required String? raw,
  required List<DropdownItem> items,
  Logger? logger,
}) {
  try {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    if (items.isEmpty) {
      logger?.w('Items pimpinan rapat belum ter-load, skip mapping sementara');
      return null;
    }
    final match = items.firstWhere(
      (it) => it.deskripsi.trim().toLowerCase() == s.toLowerCase(),
      orElse: () => DropdownItem(kode: '', deskripsi: ''),
    );
    if (match.kode.isEmpty) {
      logger?.w('Pimpinan rapat tidak dikenali, lewati: "$s"');
      return null;
    }
    return match.kode.trim();
  } catch (e) {
    logger?.e('Gagal parse doc.pimpinanRapat: $e');
    return null;
  }
}
// (fungsi getDataFromDocPesertaRapat dihapus; gunakan getDataFromDocDitujukan untuk input String)

String? getKodeFromDocRuangRapat({
  required String? raw,
  required List<DropdownItem> items,
  Logger? logger,
}) {
  try {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    if (items.isEmpty) {
      logger?.w('Items ruang rapat belum ter-load, skip mapping sementara');
      return null;
    }
    final match = items.firstWhere(
      (it) => it.deskripsi.trim().toLowerCase() == s.toLowerCase(),
      orElse: () => DropdownItem(kode: '', deskripsi: ''),
    );
    if (match.kode.isEmpty) {
      logger?.w('Ruang rapat tidak dikenali, lewati: "$s"');
      return null;
    }
    return match.kode.trim();
  } catch (e) {
    logger?.e('Gagal parse doc.ruangRapat: $e');
    return null;
  }
}

/// Document form screen for creating and editing documents
class DocumentFormScreen extends StatefulWidget {
  final String? noSurat;
  const DocumentFormScreen({super.key, this.noSurat});

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
  final _pokokBahasanController = TextEditingController();
  final _meetingDateController = TextEditingController();
  final _meetingTimeController = TextEditingController();
  DateTime? _selectedMeetingDate;
  final _kategoriKodeController = TextEditingController();
  bool _showGroupIdentitasDokumen = true;
  bool _showNomorDokumen = true;
  bool _showTanggalBuat = true;
  bool _showPengirim = true;
  bool _showGroupRapat = false;
  bool _showWaktuRapat = false;
  bool _showRuangRapat = false;
  bool _showPesertaRapat = false;
  bool _showPimpinanRapat = false;
  bool _showPokokBahasanRapat = false;
  bool _showGroupLampirandanRingkasan = false;
  bool _showGroupDitujukan = false;
  bool _showJenisDokumen = false;
  bool _showKategoriLaporan = false;
  bool _showUndanganKepada = false;
  bool _showGroupUploadImages = true;
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
  int? _editingDocumentId;
  bool _hasUnsavedChanges = false;
  late final DropdownController _kategoriController;
  late final DropdownController _jenisController;
  late final DropdownController _kategoriLaporanController;
  late final DropdownController _tujuanDisposisiController;
  late final DropdownController _ruangRapatController;
  late final DropdownController _pesertaRapatController;
  late final DropdownController _pimpinanRapatController;
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
  final List<String> _selectedTujuanDisposisi = <String>[];
  final List<String> _selectedPesertaRapat = <String>[];

  final ImagePicker _imagePicker = ImagePicker();
  final ApiService _api = ApiService();
  final List<_UploadItem> _uploadItems = <_UploadItem>[];
  String? _uploadValidationError;
  final _logger = Logger();
  final Set<String> _deletedLampiranIds = <String>{};

  /// Helper untuk memetakan lampirans DocumentModel ke bentuk sederhana untuk display/testing
  List<Map<String, dynamic>> mapLampiransForDisplay(
      List<LampiranModel> lampirans) {
    return lampirans
        .map((l) => {
              'id_lampiran': l.idLampiran,
              'no_surat': l.noSurat,
              'nama_berkas': l.namaBerkas,
              'ukuran': l.ukuran,
              'token_lampiran': l.tokenLampiran,
            })
        .toList(growable: false);
  }

  Future<void> _pickImagesFromGallery() async {
    final images = await _imagePicker.pickMultiImage();
    if (images == null || images.isEmpty) return;
    for (final x in images) {
      final name = x.name.toLowerCase();
      final size = await x.length();
      final bytes = await x.readAsBytes();
      final path = x.path;
      if (!_isSupportedFile(name)) {
        Get.snackbar('Error', 'Format gambar tidak didukung: $name',
            backgroundColor: AppTheme.errorColor, colorText: Colors.white);
        continue;
      }
      if (size > 10 * 1024 * 1024) {
        Get.snackbar('Error', 'Ukuran berkas melebihi 10MB: $name',
            backgroundColor: AppTheme.errorColor, colorText: Colors.white);
        continue;
      }
      final item = _UploadItem(
        name: x.name,
        size: size,
        bytes: bytes,
        path: path,
      );
      setState(() => _uploadItems.add(item));
      unawaited(_startUpload(item));
    }
  }

  Future<void> _takePhotoWithCamera() async {
    final x = await _imagePicker.pickImage(source: ImageSource.camera);
    if (x == null) return;
    final name = x.name.toLowerCase();
    final size = await x.length();
    final bytes = await x.readAsBytes();
    if (!_isSupportedFile(name)) {
      Get.snackbar('Error', 'Format gambar tidak didukung: $name',
          backgroundColor: AppTheme.errorColor, colorText: Colors.white);
      return;
    }
    if (size > 10 * 1024 * 1024) {
      Get.snackbar('Error', 'Ukuran berkas melebihi 10MB',
          backgroundColor: AppTheme.errorColor, colorText: Colors.white);
      return;
    }
    final item = _UploadItem(
      name: x.name,
      size: size,
      bytes: bytes,
      path: x.path,
    );
    setState(() => _uploadItems.add(item));
    unawaited(_startUpload(item));
  }

  bool _isSupportedFile(String filename) {
    final f = filename.toLowerCase();
    return f.endsWith('.jpg') ||
        f.endsWith('.jpeg') ||
        f.endsWith('.png') ||
        f.endsWith('.webp') ||
        f.endsWith('.pdf') ||
        f.endsWith('.doc') ||
        f.endsWith('.docx') ||
        f.endsWith('.xls') ||
        f.endsWith('.xlsx');
  }

  bool _isImageFile(String filename) {
    final f = filename.toLowerCase();
    return f.endsWith('.jpg') ||
        f.endsWith('.jpeg') ||
        f.endsWith('.png') ||
        f.endsWith('.webp');
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      withData: true,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
    );
    if (result == null || result.files.isEmpty) return;
    for (final f in result.files) {
      final name = (f.name).toLowerCase();
      final size = f.size;
      final bytes = f.bytes;
      final path = f.path;
      if (!_isSupportedFile(name)) {
        Get.snackbar('Error', 'Format berkas tidak didukung: $name',
            backgroundColor: AppTheme.errorColor, colorText: Colors.white);
        continue;
      }
      if (size > 10 * 1024 * 1024) {
        Get.snackbar('Error', 'Ukuran berkas melebihi 10MB: $name',
            backgroundColor: AppTheme.errorColor, colorText: Colors.white);
        continue;
      }
      final item = _UploadItem(
        name: f.name,
        size: size,
        bytes: bytes,
        path: path,
      );
      setState(() => _uploadItems.add(item));
      unawaited(_startUpload(item));
    }
  }

  Future<void> _startUpload(_UploadItem item) async {
    item.uploading = true;
    item.error = null;
    item.cancelToken = dio.CancelToken();
    setState(() {});
    try {
      final form = dio.FormData.fromMap({});
      if (item.bytes != null) {
        form.files.add(
          MapEntry(
            'file',
            dio.MultipartFile.fromBytes(item.bytes!, filename: item.name),
          ),
        );
      } else if (item.path != null) {
        form.files.add(
          MapEntry(
            'file',
            await dio.MultipartFile.fromFile(item.path!, filename: item.name),
          ),
        );
      } else {
        throw Exception('File tidak ditemukan');
      }
      final res = await _api.post(
        ApiConstants.uploads,
        data: form,
        options: dio.Options(headers: {
          'Content-Type': 'multipart/form-data',
        }),
        cancelToken: item.cancelToken,
        onSendProgress: (sent, total) {
          item.progress = total == 0 ? 0 : sent / total;
          setState(() {});
        },
      );
      final data = res.data is Map<String, dynamic>
          ? (res.data as Map<String, dynamic>)
          : <String, dynamic>{};
      item.success = true;
      item.uploading = false;
      item.tempId = (data['data'] is Map<String, dynamic>)
          ? (data['data']['id']?.toString())
          : null;
      item.tempUrl = (data['data'] is Map<String, dynamic>)
          ? (data['data']['url'] as String?)
          : null;
      setState(() {});
    } on dio.DioException catch (e) {
      item.uploading = false;
      item.success = false;
      if (dio.CancelToken.isCancel(e)) {
        item.error = 'Dibatalkan';
      } else {
        item.error = e.message ?? e.toString();
      }
      setState(() {});
    } catch (e) {
      item.uploading = false;
      item.success = false;
      item.error = e.toString();
      setState(() {});
    }
  }

  void _cancelUpload(_UploadItem item) {
    if (item.cancelToken != null && !item.cancelToken!.isCancelled) {
      item.cancelToken!.cancel('User canceled');
    }
  }

  void _cancelAllUploads() {
    for (final it in _uploadItems) {
      if (it.uploading) {
        _cancelUpload(it);
      }
    }
  }

  void _removeUpload(_UploadItem item) {
    if (item.uploading) {
      _cancelUpload(item);
    }
    if (item.tempId != null) {
      _deletedLampiranIds.add(item.tempId!);
    }
    setState(() => _uploadItems.remove(item));
  }

  void _viewUpload(_UploadItem item) {
    final name = item.name.toLowerCase();
    if (_isImageFile(name)) {
      if (item.bytes != null) {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: Image.memory(item.bytes!, fit: BoxFit.contain),
          ),
        );
        return;
      }
      if (item.tempUrl != null) {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: Image.network(
              item.tempUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 120,
                child: Center(child: Icon(Icons.broken_image, size: 48)),
              ),
            ),
          ),
        );
        return;
      }
    }
    Get.snackbar(
      'Info',
      'Pratinjau tidak tersedia untuk berkas ini',
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      colorText: AppTheme.primaryColor,
    );
  }

  // Mendapatkan deskripsi item terpilih dari DropdownController.
  // Digunakan untuk membedakan kategori: Dokumen, Undangan, Laporan.
  String? _getSelectedDeskripsi(DropdownController ctrl) {
    final kode = ctrl.selectedKode.value;
    final match = ctrl.items.where((it) => it.kode == kode);
    if (match.isEmpty) return null;
    return match.first.deskripsi;
  }

  List<String> _getSelectedDescriptions(
    DropdownController ctrl,
    List<String> selected,
  ) {
    final set = selected.toSet();
    return ctrl.items
        .where((it) => set.contains(it.kode))
        .map((it) => it.deskripsi)
        .toList();
  }

  //create function _getSelectedKode(DropdownController ctrl)
  // Mendapatkan kode item terpilih dari DropdownController.
  // Digunakan untuk membedakan kategori: Dokumen, Undangan, Laporan.
  String? _getSelectedKode(DropdownController ctrl) {
    return ctrl.selectedKode.value;
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
    final kategoriKode = _getSelectedKode(_kategoriController);
    final kategoriDesc =
        _getSelectedDeskripsi(_kategoriController)?.toLowerCase().trim() ?? '';
    _resetDocNumberPart2();
    _kategoriKodeController.text = kategoriKode ?? '';

    // print('kategoriKode: $kategoriKode');
    // print('kategoriDesc: $kategoriDesc');

    if (kategoriKode == 'Undangan') {
      _isDocNumberPart2ReadOnly = true;
      _docNumberPart2Controller.text = 'UND';

      setState(() {
        _showJenisDokumen = false;
        _showKategoriLaporan = false;
        _showUndanganKepada = true;
        _showGroupLampirandanRingkasan = true;
        _showGroupDitujukan = false;
        _showGroupRapat = false;
        _showGroupUploadImages = true;
      });
    } else if (kategoriKode == 'Rapat') {
      _isDocNumberPart2ReadOnly = true;
      _docNumberPart2Controller.text = 'RPT';
      setState(() {
        _showJenisDokumen = false;
        _showKategoriLaporan = false;
        _showUndanganKepada = false;
        _showGroupLampirandanRingkasan = false;
        _showGroupDitujukan = false;
        _showGroupRapat = true;
        _showWaktuRapat = true;
        _showRuangRapat = true;
        _showPesertaRapat = true;
        _showPimpinanRapat = true;
        _showPokokBahasanRapat = true;
        _showGroupUploadImages = false;
      });
    } else if (kategoriKode == 'Dokumen') {
      _isDocNumberPart2ReadOnly = false;
      final jenisKode = _jenisController.selectedKode.value;
      if (jenisKode.isEmpty) {
        // Get.snackbar(
        //   'Error',
        //   'Jenis dokumen harus dipilih untuk menentukan nomor dokumen',
        //   backgroundColor: AppTheme.errorColor,
        //   colorText: Colors.white,
        //   snackPosition: SnackPosition.TOP,
        // );
      } else {
        _docNumberPart2Controller.text = jenisKode;
      }

      setState(() {
        _showJenisDokumen = true;
        _showKategoriLaporan = false;
        _showUndanganKepada = false;
        _showGroupLampirandanRingkasan = true;
        _showGroupDitujukan = false;
        _showGroupRapat = false;
        _showGroupUploadImages = true;
      });
    } else if (kategoriKode == 'Laporan') {
      _isDocNumberPart2ReadOnly = false;
      final laporanKode = _kategoriLaporanController.selectedKode.value;
      if (laporanKode.isEmpty) {
        // Get.snackbar(
        //   'Error',
        //   'Kategori laporan harus dipilih untuk menentukan nomor dokumen',
        //   backgroundColor: AppTheme.errorColor,
        //   colorText: Colors.white,
        //   snackPosition: SnackPosition.TOP,
        // );
      } else {
        _docNumberPart2Controller.text = laporanKode;
      }

      setState(() {
        _showJenisDokumen = false;
        _showKategoriLaporan = true;
        _showUndanganKepada = false;
        _showGroupLampirandanRingkasan = true;
        _showGroupDitujukan = true;
        _showGroupRapat = false;
        _showGroupUploadImages = true;
      });
    } else {
      _isDocNumberPart2ReadOnly = false;
    }
    // setState(() {});
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
    _pengirimController.text = user?.instansiName ?? '';

    _kategoriController = Get.put(DropdownController(), tag: 'kategori');
    _jenisController = Get.put(DropdownController(), tag: 'jenis');
    _kategoriLaporanController =
        Get.put(DropdownController(), tag: 'kategori_laporan');
    _tujuanDisposisiController =
        Get.put(DropdownController(), tag: 'tujuan_disposisi');
    _ruangRapatController = Get.put(DropdownController(), tag: 'ruang_rapat');
    _pesertaRapatController =
        Get.put(DropdownController(), tag: 'peserta_rapat');
    _pimpinanRapatController =
        Get.put(DropdownController(), tag: 'pimpinan_rapat');
    _usersDropdownController =
        Get.put(_UsersDropdownController(), tag: 'users_dropdown');

    _lastNoSuratController =
        Get.put(LastNoSuratController(), tag: 'last_no_surat');

    _initializeForm();
    if (widget.noSurat != null && widget.noSurat!.trim().isNotEmpty) {
      _docNumberPart1Controller.text = widget.noSurat!.trim();
      _isEditMode = true;
      _loadExistingDocumentByNoSurat(widget.noSurat!.trim());
    }
    Get.put(SuratMasukController(), permanent: true);
    _kategoriController.loadTable('m_kategori_formulir');
    _jenisController.loadTable('m_jenis_dokumen');
    _kategoriLaporanController.loadTable('m_kategori_laporan');
    _tujuanDisposisiController.loadTable('m_tujuan_disposisi');
    _ruangRapatController.loadTable('m_ruang_rapat');
    _pesertaRapatController.loadTable('m_tujuan_disposisi');
    _pimpinanRapatController.loadTable('m_tujuan_disposisi');
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
    _selectedMeetingDate = now;
    _meetingDateController.text = DateFormat('dd/MM/yyyy').format(now);
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
    _pokokBahasanController.dispose();
    _meetingDateController.dispose();
    _meetingTimeController.dispose();
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

  /// Mengontrol visibilitas seluruh kelompok "Identitas Dokumen"
  void setShowIdentitasDokumen(bool visible) {
    setState(() => _showGroupIdentitasDokumen = visible);
  }

  /// Mengontrol visibilitas bagian "Nomor Dokumen"
  void setShowNomorDokumen(bool visible) {
    setState(() => _showNomorDokumen = visible);
  }

  /// Mengontrol visibilitas bagian "Tanggal Buat"
  void setShowTanggalBuat(bool visible) {
    setState(() => _showTanggalBuat = visible);
  }

  /// Mengontrol visibilitas bagian "Pengirim"
  void setShowPengirim(bool visible) {
    setState(() => _showPengirim = visible);
  }

  void setShowGroupRapat(bool visible) {
    setState(() => _showGroupRapat = visible);
  }

  void setShowGroupUploadImages(bool visible) {
    setState(() => _showGroupUploadImages = visible);
  }

  bool _isUploadRequiredForSelectedCategory() {
    final kode = _getSelectedKode(_kategoriController);
    return kode == 'Dokumen' || kode == 'Undangan' || kode == 'Laporan';
  }

  bool _validateUploadRequirement() {
    if (_isUploadRequiredForSelectedCategory() && _uploadItems.isEmpty) {
      _uploadValidationError =
          'Lampiran gambar wajib diunggah untuk kategori yang dipilih';
      setState(() {});
      Get.snackbar(
        'Error',
        _uploadValidationError!,
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
      return false;
    }
    _uploadValidationError = null;
    setState(() {});
    return true;
  }

  void setShowWaktuRapat(bool visible) {
    setState(() => _showWaktuRapat = visible);
  }

  void setShowRuangRapat(bool visible) {
    setState(() => _showRuangRapat = visible);
  }

  void setShowPesertaRapat(bool visible) {
    setState(() => _showPesertaRapat = visible);
  }

  void setShowPimpinanRapat(bool visible) {
    setState(() => _showPimpinanRapat = visible);
  }

  void setShowPokokBahasanRapat(bool visible) {
    setState(() => _showPokokBahasanRapat = visible);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmLeaveIfDirty,
      child: Scaffold(
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
                    onChanged: () {
                      _hasUnsavedChanges = true;
                    },
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
                        const SizedBox(height: 16),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              SizeTransition(sizeFactor: anim, child: child),
                          child: _showKategoriLaporan
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              SizeTransition(sizeFactor: anim, child: child),
                          child: _showJenisDokumen
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                    const SizedBox(height: 16),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              SizeTransition(sizeFactor: anim, child: child),
                          child: _showUndanganKepada
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Undangan kepada',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Obx(() {
                                      if (_usersDropdownController
                                              .isLoading.value &&
                                          _usersDropdownController
                                              .items.isEmpty) {
                                        return const SizedBox(
                                          height: 56,
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        );
                                      }
                                      if (_usersDropdownController
                                          .error.isNotEmpty) {
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.errorColor
                                                .withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppTheme.errorColor
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            _usersDropdownController
                                                .error.value,
                                            style: const TextStyle(
                                                color: AppTheme.errorColor),
                                          ),
                                        );
                                      }
                                      return DropdownButtonFormField<String>(
                                        value: _usersDropdownController
                                                .selectedUserId.value.isEmpty
                                            ? null
                                            : _usersDropdownController
                                                .selectedUserId.value,
                                        items: _usersDropdownController.items
                                            .map(
                                              (u) => DropdownMenuItem<String>(
                                                value: u.id,
                                                child: Text(u.namaLengkap),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) =>
                                            _usersDropdownController
                                                .select(val),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'User harus dipilih';
                                          }
                                          return null;
                                        },
                                        decoration: const InputDecoration(
                                          hintText: 'Pilih undangan kepada',
                                          border: OutlineInputBorder(),
                                          prefixIcon:
                                              Icon(Icons.person_outline),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 16),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
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
                        // Wrap(
                        //   spacing: 8,
                        //   runSpacing: 8,
                        //   children: [
                        //     FilterChip(
                        //       label: const Text('Identitas Dokumen'),
                        //       selected: _showGroupIdentitasDokumen,
                        //       onSelected: (v) {
                        //         setState(() => _showGroupIdentitasDokumen = v);
                        //       },
                        //     ),
                        //     FilterChip(
                        //       label: const Text('Nomor Dokumen'),
                        //       selected: _showNomorDokumen,
                        //       onSelected: (v) {
                        //         setState(() => _showNomorDokumen = v);
                        //       },
                        //     ),
                        //     FilterChip(
                        //       label: const Text('Tanggal Buat'),
                        //       selected: _showTanggalBuat,
                        //       onSelected: (v) {
                        //         setState(() => _showTanggalBuat = v);
                        //       },
                        //     ),
                        //     FilterChip(
                        //       label: const Text('Pengirim'),
                        //       selected: _showPengirim,
                        //       onSelected: (v) {
                        //         setState(() => _showPengirim = v);
                        //       },
                        //     ),
                        //   ],
                        // ),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              SizeTransition(sizeFactor: anim, child: child),
                          child: _showGroupIdentitasDokumen
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      transitionBuilder: (child, anim) =>
                                          SizeTransition(
                                        sizeFactor: anim,
                                        child: child,
                                      ),
                                      child: _showNomorDokumen
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Nomor dokumen',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 6,
                                                      child: TextFormField(
                                                        controller:
                                                            _docNumberPart1Controller,
                                                        readOnly: true,
                                                        decoration:
                                                            const InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          prefixIcon: Icon(Icons
                                                              .confirmation_number_outlined),
                                                        ),
                                                        validator: (value) {
                                                          final v =
                                                              (value ?? '')
                                                                  .trim();
                                                          if (v.isEmpty) {
                                                            return 'Nomor dokumen harus diisi';
                                                          }
                                                          final isDigits =
                                                              RegExp(r'^\d+$')
                                                                  .hasMatch(v);
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
                                                        readOnly: true,
                                                        controller:
                                                            _docNumberPart2Controller,
                                                        decoration:
                                                            const InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          prefixIcon: Icon(Icons
                                                              .tag_outlined),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      transitionBuilder: (child, anim) =>
                                          SizeTransition(
                                        sizeFactor: anim,
                                        child: child,
                                      ),
                                      child: _showTanggalBuat
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Tanggal buat',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                TextFormField(
                                                  controller:
                                                      _todayDateController,
                                                  readOnly: true,
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText: 'dd-mm-yyyy',
                                                    border:
                                                        OutlineInputBorder(),
                                                    prefixIcon: Icon(Icons
                                                        .calendar_today_outlined),
                                                  ),
                                                  onChanged:
                                                      _handleTodayDateChanged,
                                                ),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      transitionBuilder: (child, anim) =>
                                          SizeTransition(
                                        sizeFactor: anim,
                                        child: child,
                                      ),
                                      child: _showPengirim
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Pengirim',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                TextFormField(
                                                  controller:
                                                      _pengirimController,
                                                  readOnly: true,
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText:
                                                        'Masukkan nama pengirim berkas',
                                                    border:
                                                        OutlineInputBorder(),
                                                    prefixIcon: Icon(
                                                        Icons.person_outlined),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Wrap(
                        //   spacing: 8,
                        //   runSpacing: 8,
                        //   children: [
                        //     FilterChip(
                        //       label: const Text('Jenis Dokumen'),
                        //       selected: _showJenisDokumen,
                        //       onSelected: (v) {
                        //         setState(() => _showJenisDokumen = v);
                        //       },
                        //     ),
                        //   ],
                        // ),

                        // Wrap(
                        //   spacing: 8,
                        //   runSpacing: 8,
                        //   children: [
                        //     FilterChip(
                        //       label: const Text('Kategori Laporan'),
                        //       selected: _showKategoriLaporan,
                        //       onSelected: (v) {
                        //         setState(() => _showKategoriLaporan = v);
                        //       },
                        //     ),
                        //   ],
                        // ),

                        // Dropdown User Undangan (sumber data dari /api/users/dropdown dengan parameter kode_user=YS)
                        // Wrap(
                        //   spacing: 8,
                        //   runSpacing: 8,
                        //   children: [
                        //     FilterChip(
                        //       label: const Text('Undangan Kepada'),
                        //       selected: _showUndanganKepada,
                        //       onSelected: (v) {
                        //         setState(() => _showUndanganKepada = v);
                        //       },
                        //     ),
                        //   ],
                        // ),

                        //Tanggal Surat
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
                            final initial =
                                _selectedLetterDate ?? DateTime.now();
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
                              _handleTodayDateChanged(
                                  _letterDateController.text);
                            }
                          },
                          onChanged: (v) {
                            try {
                              _selectedLetterDate = DateFormat('dd-MM-yyyy')
                                  .parseStrict(v.trim());
                            } catch (_) {
                              _selectedLetterDate = null;
                            }
                            _handleTodayDateChanged(v);
                          },
                        ),
                        const SizedBox(height: 16),

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
                        // Text(
                        //   'Kategori Kode',
                        //   style: const TextStyle(fontWeight: FontWeight.bold),
                        // ),
                        // TextFormField(
                        //   controller: _kategoriKodeController,
                        //   readOnly: true,
                        //   decoration: const InputDecoration(
                        //     hintText: 'Kode kategori terpilih',
                        //     border: OutlineInputBorder(),
                        //     prefixIcon: Icon(Icons.category_outlined),
                        //   ),
                        //   validator: (value) {
                        //     final v = (value ?? '').trim();
                        //     if (v.isEmpty) {
                        //       return 'Kategori kode harus dipilih';
                        //     }
                        //     return null;
                        //   },
                        // ),
                        // const SizedBox(height: 16),

                        // Wrap(
                        //   spacing: 8,
                        //   runSpacing: 8,
                        //   children: [
                        //     FilterChip(
                        //       label: const Text('Lampiran & Ringkasan'),
                        //       selected: _showGroupLampirandanRingkasan,
                        //       onSelected: (v) {
                        //         setState(
                        //             () => _showGroupLampirandanRingkasan = v);
                        //       },
                        //     ),
                        //   ],
                        // ),

                        //Group Lampiran & Ringkasan
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              SizeTransition(sizeFactor: anim, child: child),
                          child: _showGroupLampirandanRingkasan
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Perihal',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextFormField(
                                      controller: _perihalController,
                                      decoration: const InputDecoration(
                                        hintText: 'Masukkan perihal surat',
                                        border: OutlineInputBorder(),
                                        prefixIcon:
                                            Icon(Icons.subject_outlined),
                                      ),
                                      validator: (value) {
                                        final v = (value ?? '').trim();
                                        if (v.length < 5) {
                                          return 'Perihal minimal 5 karakter';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Ringkasan',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextFormField(
                                      controller: _ringkasanController,
                                      decoration: const InputDecoration(
                                        hintText: 'Masukkan ringkasan',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.notes_outlined),
                                        alignLabelWithHint: true,
                                      ),
                                      validator: (value) {
                                        final v = (value ?? '').trim();
                                        if (v.length < 5) {
                                          return 'Ringkasan minimal 5 karakter';
                                        }
                                        return null;
                                      },
                                      maxLines: 4,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Wrap(
                        //   spacing: 8,
                        //   runSpacing: 8,
                        //   children: [
                        //     FilterChip(
                        //       label: const Text('Ditujukan'),
                        //       selected: _showGroupDitujukan,
                        //       onSelected: (v) {
                        //         setState(() => _showGroupDitujukan = v);
                        //       },
                        //     ),
                        //   ],
                        // ),

                        //Group Ditujukan
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              SizeTransition(sizeFactor: anim, child: child),
                          child: _showGroupDitujukan
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ApiMultiSelectField(
                                      label: 'Di tujukan',
                                      placeholder: 'Pilih tujuan disposisi',
                                      tableName: 'm_tujuan_disposisi',
                                      controller: _tujuanDisposisiController,
                                      selectedValues: _selectedTujuanDisposisi,
                                      itemTextBuilder: (it) => it.deskripsi,
                                      validator: (values) {
                                        if (values == null || values.isEmpty) {
                                          return 'Minimal pilih 1 tujuan disposisi';
                                        }
                                        return null;
                                      },
                                      onChanged: (vals) {
                                        _selectedTujuanDisposisi
                                          ..clear()
                                          ..addAll(vals);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Wrap(
                        //   spacing: 8,
                        //   runSpacing: 8,
                        //   children: [
                        //     FilterChip(
                        //       label: const Text('Rapat'),
                        //       selected: _showGroupRapat,
                        //       onSelected: (v) {
                        //         setState(() => _showGroupRapat = v);
                        //       },
                        //     ),
                        //     FilterChip(
                        //       label: const Text('Waktu Rapat'),
                        //       selected: _showWaktuRapat,
                        //       onSelected: (v) {
                        //         setState(() => _showWaktuRapat = v);
                        //       },
                        //     ),
                        //     FilterChip(
                        //       label: const Text('Ruang Rapat'),
                        //       selected: _showRuangRapat,
                        //       onSelected: (v) {
                        //         setState(() => _showRuangRapat = v);
                        //       },
                        //     ),
                        //     FilterChip(
                        //       label: const Text('Peserta Rapat'),
                        //       selected: _showPesertaRapat,
                        //       onSelected: (v) {
                        //         setState(() => _showPesertaRapat = v);
                        //       },
                        //     ),
                        //     FilterChip(
                        //       label: const Text('Pimpinan Rapat'),
                        //       selected: _showPimpinanRapat,
                        //       onSelected: (v) {
                        //         setState(() => _showPimpinanRapat = v);
                        //       },
                        //     ),
                        //     FilterChip(
                        //       label: const Text('Pokok Bahasan'),
                        //       selected: _showPokokBahasanRapat,
                        //       onSelected: (v) {
                        //         setState(() => _showPokokBahasanRapat = v);
                        //       },
                        //     ),
                        //   ],
                        // ),

                        //Group Rapat
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              SizeTransition(sizeFactor: anim, child: child),
                          child: _showGroupRapat
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      transitionBuilder: (child, anim) =>
                                          SizeTransition(
                                        sizeFactor: anim,
                                        child: child,
                                      ),
                                      child: _showWaktuRapat
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Waktu Rapat',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 5,
                                                      child: TextFormField(
                                                        controller:
                                                            _meetingDateController,
                                                        decoration:
                                                            const InputDecoration(
                                                          hintText:
                                                              'DD/MM/YYYY',
                                                          border:
                                                              OutlineInputBorder(),
                                                          prefixIcon: Icon(Icons
                                                              .calendar_today_outlined),
                                                        ),
                                                        validator: (value) {
                                                          final v =
                                                              (value ?? '')
                                                                  .trim();
                                                          if (v.isEmpty) {
                                                            return 'Tanggal rapat harus diisi';
                                                          }
                                                          try {
                                                            DateFormat(
                                                                    'dd/MM/yyyy')
                                                                .parseStrict(v);
                                                          } catch (_) {
                                                            return 'Format tanggal tidak valid (DD/MM/YYYY)';
                                                          }
                                                          return null;
                                                        },
                                                        onTap: () async {
                                                          final initial =
                                                              _selectedMeetingDate ??
                                                                  DateTime
                                                                      .now();
                                                          final picked =
                                                              await showDatePicker(
                                                            context: context,
                                                            initialDate:
                                                                initial,
                                                            firstDate: DateTime(
                                                                2000, 1, 1),
                                                            lastDate: DateTime(
                                                                2100, 12, 31),
                                                          );
                                                          if (picked != null) {
                                                            _selectedMeetingDate =
                                                                picked;
                                                            _meetingDateController
                                                                .text = DateFormat(
                                                                    'dd/MM/yyyy')
                                                                .format(picked);
                                                            setState(() {});
                                                          }
                                                        },
                                                        onChanged: (v) {
                                                          try {
                                                            _selectedMeetingDate =
                                                                DateFormat(
                                                                        'dd/MM/yyyy')
                                                                    .parseStrict(
                                                                        v.trim());
                                                          } catch (_) {
                                                            _selectedMeetingDate =
                                                                null;
                                                          }
                                                          setState(() {});
                                                        },
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      flex: 5,
                                                      child: TextFormField(
                                                        controller:
                                                            _meetingTimeController,
                                                        decoration:
                                                            const InputDecoration(
                                                          hintText:
                                                              'waktu rapat',
                                                          border:
                                                              OutlineInputBorder(),
                                                          prefixIcon: Icon(Icons
                                                              .access_time_outlined),
                                                        ),
                                                        validator: (value) {
                                                          final v =
                                                              (value ?? '')
                                                                  .trim();
                                                          if (v.isEmpty) {
                                                            return 'Waktu rapat harus diisi';
                                                          }
                                                          return null;
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      transitionBuilder: (child, anim) =>
                                          SizeTransition(
                                        sizeFactor: anim,
                                        child: child,
                                      ),
                                      child: _showRuangRapat
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ApiDropdownField(
                                                  label: 'Ruang Rapat',
                                                  placeholder:
                                                      'Pilih Ruang Rapat',
                                                  tableName: 'm_ruang_rapat',
                                                  controller:
                                                      _ruangRapatController,
                                                  itemTextBuilder: (it) =>
                                                      it.deskripsi,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Ruang rapat harus dipilih';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      transitionBuilder: (child, anim) =>
                                          SizeTransition(
                                        sizeFactor: anim,
                                        child: child,
                                      ),
                                      child: _showPesertaRapat
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ApiMultiSelectField(
                                                  label: 'Peserta Rapat',
                                                  placeholder:
                                                      'Pilih Peserta rapat',
                                                  tableName:
                                                      'm_tujuan_disposisi',
                                                  controller:
                                                      _pesertaRapatController,
                                                  selectedValues:
                                                      _selectedPesertaRapat,
                                                  itemTextBuilder: (it) =>
                                                      it.deskripsi,
                                                  validator: (values) {
                                                    if (values == null ||
                                                        values.isEmpty) {
                                                      return 'Minimal pilih 1 Peserta rapat';
                                                    }
                                                    return null;
                                                  },
                                                  onChanged: (vals) {
                                                    _selectedPesertaRapat
                                                      ..clear()
                                                      ..addAll(vals);
                                                    setState(() {});
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      transitionBuilder: (child, anim) =>
                                          SizeTransition(
                                        sizeFactor: anim,
                                        child: child,
                                      ),
                                      child: _showPimpinanRapat
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ApiDropdownField(
                                                  label: 'Pimpinan',
                                                  placeholder:
                                                      'Pilih Piminan rapat',
                                                  tableName:
                                                      'm_tujuan_disposisi',
                                                  controller:
                                                      _pimpinanRapatController,
                                                  itemTextBuilder: (it) =>
                                                      it.deskripsi,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Pimpinan rapat harus dipilih';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      transitionBuilder: (child, anim) =>
                                          SizeTransition(
                                        sizeFactor: anim,
                                        child: child,
                                      ),
                                      child: _showPokokBahasanRapat
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Pokok Bahasan Rapat',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                TextFormField(
                                                  controller:
                                                      _pokokBahasanController,
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText:
                                                        'Masukkan pokok bahasan rapat',
                                                    border:
                                                        OutlineInputBorder(),
                                                    prefixIcon: Icon(
                                                        Icons.topic_outlined),
                                                    alignLabelWithHint: true,
                                                  ),
                                                  maxLines: 4,
                                                  textCapitalization:
                                                      TextCapitalization
                                                          .sentences,
                                                  validator: (value) {
                                                    final v =
                                                        (value ?? '').trim();
                                                    if (v.isEmpty) {
                                                      return 'Pokok bahasan rapat harus diisi';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 12),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Upload gambar (multi-file, preview, progress, cancel)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              SizeTransition(sizeFactor: anim, child: child),
                          child: _showGroupUploadImages
                              ? Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            const Text(
                                              'Lampiran Berkas',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                TextButton.icon(
                                                  onPressed:
                                                      _pickImagesFromGallery,
                                                  icon: const Icon(Icons
                                                      .photo_library_outlined),
                                                  label: const Text('Galeri'),
                                                ),
                                                TextButton.icon(
                                                  onPressed:
                                                      _takePhotoWithCamera,
                                                  icon: const Icon(Icons
                                                      .photo_camera_outlined),
                                                  label: const Text('Kamera'),
                                                ),
                                                TextButton.icon(
                                                  onPressed: _pickDocuments,
                                                  icon: const Icon(
                                                      Icons.attach_file),
                                                  label: const Text('Dokumen'),
                                                ),
                                                if (_uploadItems
                                                    .any((it) => it.uploading))
                                                  TextButton.icon(
                                                    onPressed:
                                                        _cancelAllUploads,
                                                    icon: const Icon(Icons
                                                        .pause_circle_outline),
                                                    label: const Text(
                                                        'Batalkan semua'),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (_uploadValidationError != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                              _uploadValidationError!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.errorColor,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 12),
                                        // Content and Preview gambar
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final width = constraints.maxWidth;
                                            final crossAxisCount = width >= 1000
                                                ? 5
                                                : width >= 800
                                                    ? 4
                                                    : width >= 600
                                                        ? 3
                                                        : 2;
                                            return GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: crossAxisCount,
                                                crossAxisSpacing: 8,
                                                mainAxisSpacing: 8,
                                                childAspectRatio: 1,
                                              ),
                                              itemCount: _uploadItems.length,
                                              itemBuilder: (context, index) {
                                                final it = _uploadItems[index];
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: it.success
                                                          ? Colors.green
                                                              .withOpacity(0.5)
                                                          : it.uploading
                                                              ? AppTheme
                                                                  .primaryColor
                                                                  .withOpacity(
                                                                      0.5)
                                                              : AppTheme
                                                                  .errorColor
                                                                  .withOpacity(
                                                                      0.5),
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Expanded(
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    8),
                                                            topRight:
                                                                Radius.circular(
                                                                    8),
                                                          ),
                                                          child: (() {
                                                            final name = it.name
                                                                .toLowerCase();
                                                            if (it.bytes !=
                                                                null) {
                                                              if (_isImageFile(
                                                                  name)) {
                                                                return Image
                                                                    .memory(
                                                                  it.bytes!,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  width: double
                                                                      .infinity,
                                                                );
                                                              } else {
                                                                return Center(
                                                                  child: Icon(
                                                                    name.endsWith(
                                                                            '.pdf')
                                                                        ? Icons
                                                                            .picture_as_pdf
                                                                        : Icons
                                                                            .description_outlined,
                                                                    size: 48,
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                            if (_isImageFile(
                                                                    name) &&
                                                                it.tempUrl !=
                                                                    null) {
                                                              return Image
                                                                  .network(
                                                                it.tempUrl!,
                                                                fit: BoxFit
                                                                    .cover,
                                                                width: double
                                                                    .infinity,
                                                                errorBuilder: (_,
                                                                        __,
                                                                        ___) =>
                                                                    const Center(
                                                                  child: Icon(
                                                                      Icons
                                                                          .broken_image,
                                                                      size: 48),
                                                                ),
                                                              );
                                                            }
                                                            return Center(
                                                              child: Icon(
                                                                name.endsWith(
                                                                        '.pdf')
                                                                    ? Icons
                                                                        .picture_as_pdf
                                                                    : Icons
                                                                        .description_outlined,
                                                                size: 48,
                                                              ),
                                                            );
                                                          }()),
                                                        ),
                                                      ),
                                                      Flexible(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8),
                                                          child:
                                                              SingleChildScrollView(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  it.name,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                                Text(
                                                                    '${(it.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .grey)),
                                                                const SizedBox(
                                                                    height: 6),
                                                                if (it
                                                                    .uploading)
                                                                  LinearProgressIndicator(
                                                                      value: it
                                                                          .progress),
                                                                if (it.error !=
                                                                    null)
                                                                  Text(
                                                                    it.error!,
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: AppTheme
                                                                            .errorColor),
                                                                  ),
                                                                if (it.success &&
                                                                    it.tempUrl !=
                                                                        null)
                                                                  Text(
                                                                    'Terupload',
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .green),
                                                                  ),
                                                                const SizedBox(
                                                                    height: 6),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .end,
                                                                  children: [
                                                                    if (it
                                                                        .uploading)
                                                                      IconButton(
                                                                        icon: const Icon(
                                                                            Icons.pause_circle_outline),
                                                                        tooltip:
                                                                            'Batalkan',
                                                                        onPressed:
                                                                            () =>
                                                                                _cancelUpload(it),
                                                                      ),
                                                                    IconButton(
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .visibility_outlined),
                                                                      tooltip:
                                                                          'Lihat',
                                                                      onPressed:
                                                                          () =>
                                                                              _viewUpload(it),
                                                                    ),
                                                                    IconButton(
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .delete_outline),
                                                                      tooltip:
                                                                          'Hapus',
                                                                      onPressed:
                                                                          () =>
                                                                              _removeUpload(it),
                                                                    ),
                                                                    if (it.error !=
                                                                            null &&
                                                                        !it.uploading)
                                                                      IconButton(
                                                                        icon: const Icon(
                                                                            Icons.refresh),
                                                                        tooltip:
                                                                            'Ulangi',
                                                                        onPressed:
                                                                            () =>
                                                                                _startUpload(it),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // User information display
                        //_buildUserInfo(),
                        const SizedBox(height: 32),

                        // Action buttons
                        _buildActionButtons(),
                      ],
                    ),
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
                  ? 'Anda dapat mengedit pengajuan berkas selama status belum di proses kepala bagian umum.'
                  : 'Pengajuan berkas akan diajukan ke kepala bagian umum setelah disimpan.',
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

    if (_isEditMode && _docNumberPart1Controller.text.trim().isEmpty) {
      Get.snackbar(
        'Validasi',
        'Nomor dokumen (no_surat) wajib diisi untuk mode edit.',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
      return;
    }

    if (!_validateUploadRequirement()) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    _isLoading.value = true;

    try {
      final kategoriKode = _getSelectedKode(_kategoriController) ?? 'Dokumen';
      DateTime tgl;
      try {
        tgl = DateFormat('dd-MM-yyyy')
            .parseStrict(_letterDateController.text.trim());
      } catch (_) {
        tgl = DateTime.now();
      }
      final dmy = DateFormat('dd-MM-yyyy').format(tgl);
      final ymd = DateFormat('yyyy-MM-dd').format(tgl);
      final penerima = _selectedTujuanDisposisi.join(',');
      final lampiranUrls = _uploadItems
          .where((it) => it.success && it.tempUrl != null)
          .map((it) => it.tempUrl!)
          .toList();
      final lampiranIds = _uploadItems
          .where((it) => it.success && it.tempId != null)
          .map((it) => it.tempId!)
          .toList();

      final statusValue = (kategoriKode == 'Rapat') ? 'Rapat' : 'Dokumen';

      final user = authController.currentUser.value;

      //tulis ke log user?.id dan user?.kodeUser
      // _logger.i('user?.id: ${user?.id}');
      // _logger.i('user?.kodeUser: ${user?.kodeUser}');

      final penerimaText = _perihalController.text.trim();
      final penerimaValue = penerimaText.isEmpty ? '-----' : penerimaText;
      final ringkasanText = _ringkasanController.text.trim();
      final ringkasanValue = ringkasanText.isEmpty ? '-----' : ringkasanText;

      //tulis ke log kategoriKode
      final payload = <String, dynamic>{
        'no_asal':
            '${_letterNumberPart1Controller.text.trim()}/${_letterNumberPart2Controller.text.trim()}',
        'tgl_no_asal': ymd,
        'tgl_no_asal2': ymd,
        'tgl_surat': ymd,
        'pengirim': _pengirimController.text.trim(),
        'penerima': penerimaValue,
        'perihal': ringkasanValue,
        'status': statusValue,
        'sifat': 'Biasa',
        'dibaca_pimpinan': (kategoriKode == 'Nota Dinas') ? '8' : '0',
        'dibaca': (kategoriKode == 'Nota Dinas')
            ? '2'
            : (kategoriKode == 'Memo' ? '1' : '1'),
        'id_user_approved': (kategoriKode == 'Memo') ? user?.id ?? '0' : '0',
        'kode_user_approved':
            (kategoriKode == 'Memo') ? user?.kodeUser ?? '' : '',
        'instruksi_kerja': 'null',
        'disposisi_memo': 'null',
        'kategori_berkas': _docNumberPart2Controller.text.trim(),
        'kategori_surat': _docNumberPart2Controller.text.trim(),
        'kode_berkas': kategoriKode,
        'kategori_kode': _getSelectedKode(_kategoriController) ?? '',
        'klasifikasi_surat': _letterNumberPart2Controller.text.trim(),
      };

      if (kategoriKode == 'Rapat') {
        payload['tgl_agenda_rapat'] = DateFormat('yyyy-MM-dd').format(
          DateFormat('dd/MM/yyyy')
              .parseStrict(_meetingDateController.text.trim()),
        );
        payload['jam_rapat'] = _meetingTimeController.text.trim();
        payload['ruang_rapat'] =
            _getSelectedDeskripsi(_ruangRapatController) ?? 'null';
        payload['bahasan_rapat'] = _pokokBahasanController.text.trim();
        payload['pimpinan_rapat'] =
            _getSelectedDeskripsi(_pimpinanRapatController) ?? 'null';
        payload['peserta_rapat'] = _getSelectedDescriptions(
                _pesertaRapatController, _selectedPesertaRapat)
            .join('<br>');
      }

      if (kategoriKode == 'Laporan') {
        payload['ditujukan'] = _getSelectedDescriptions(
                _tujuanDisposisiController, _selectedTujuanDisposisi)
            .join('<br>');
        payload['kategori_laporan'] =
            _getSelectedKode(_kategoriLaporanController) ?? '';
      }

      if (kategoriKode == 'Undangan') {
        payload['kategori_undangan'] =
            _usersDropdownController.selectedUserId.value;
      }

      final uploadMeta = _uploadItems
          .map((it) => {
                'name': it.name,
                'size': it.size,
                'success': it.success,
                'tempId': it.tempId,
                'tempUrl': it.tempUrl,
              })
          .toList();
      _logger.i('Submit SuratMasuk payload: $payload');
      _logger.d('Upload items: $uploadMeta');

      // Upload lampiran ke backend (tbl_lampiran)
      final noSurat = _docNumberPart1Controller.text.trim();
      await _uploadLampiranForSubmission(noSurat, ymd);

      if (_isEditMode && _editingDocumentId != null) {
        final repo = DocumentRepository();
        await repo.updateDocument(_editingDocumentId!, payload);
      } else {
        final smCtrl = Get.isRegistered<SuratMasukController>()
            ? Get.find<SuratMasukController>()
            : Get.put(SuratMasukController(), permanent: true);
        await smCtrl.submit(payload);
      }

      Get.back(result: 'created');
      Get.snackbar(
        'Berhasil',
        _isEditMode
            ? 'Perubahan berkas berhasil disimpan'
            : 'Pengajuan berkas berhasil diajukan',
        backgroundColor: AppTheme.statusApproved,
        colorText: Colors.white,
      );
      _hasUnsavedChanges = false;
    } catch (e) {
      Get.snackbar(
        'Error',
        _isEditMode
            ? 'Gagal menyimpan perubahan: $e'
            : 'Gagal menyimpan dokumen: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _uploadLampiranForSubmission(String noSurat, String ymd) async {
    for (final it in _uploadItems) {
      final nameLower = it.name.toLowerCase();
      if (!_isSupportedFile(nameLower)) {
        _logger.w('Skip lampiran (format tidak didukung): ${it.name}');
        continue;
      }
      if (it.size > 10 * 1024 * 1024) {
        _logger.w('Skip lampiran (ukuran > 10MB): ${it.name}');
        continue;
      }
      final form = dio.FormData.fromMap({
        'no_surat': noSurat,
        'tgl_surat': ymd,
        'nama_berkas': it.name,
        'ukuran': it.size,
      });
      try {
        if (it.bytes != null) {
          form.files.add(
            MapEntry(
              'file',
              dio.MultipartFile.fromBytes(it.bytes!, filename: it.name),
            ),
          );
        } else if (it.path != null) {
          form.files.add(
            MapEntry(
              'file',
              await dio.MultipartFile.fromFile(it.path!, filename: it.name),
            ),
          );
        } else {
          _logger.w('Skip lampiran (no bytes/path): ${it.name}');
          continue;
        }
        final res = await _api.post(
          ApiConstants.lampiranUpload,
          data: form,
          options: dio.Options(headers: {
            'Content-Type': 'multipart/form-data',
          }),
        );
        _logger.i('Lampiran tersimpan: ${res.data}');
      } catch (e) {
        _logger.e('Gagal menyimpan lampiran ${it.name}: $e');
      }
    }
  }

  Future<void> _loadExistingDocumentByNoSurat(String noSurat) async {
    _isLoading.value = true;
    try {
      final repo = DocumentRepository();
      final results =
          await repo.getDocuments(search: noSurat, limit: 1, page: 1);
      if (results.isNotEmpty) {
        final doc = results.first;
        _existingDocument = doc;
        _editingDocumentId = doc.id;

        // Set default kategori Formulir (edit mode) berdasarkan doc.kategoriKode
        final kk = doc.kategoriKode?.trim();
        if (kk != null && kk.isNotEmpty) {
          if (_kategoriController.items.isNotEmpty) {
            final exists = _kategoriController.items.any((it) => it.kode == kk);
            if (exists) {
              _kategoriController.select(kk);
              _handleKategoriChanged(kk);
              setState(() {});
            } else {
              _logger.w('kategori_kode tidak ditemukan di items: $kk');
            }
          } else {
            once(_kategoriController.items, (_) {
              final exists =
                  _kategoriController.items.any((it) => it.kode == kk);
              if (exists) {
                _kategoriController.select(kk);
                _handleKategoriChanged(kk);
                setState(() {});
              } else {
                _logger.w('kategori_kode tidak ditemukan (after load): $kk');
              }
            });
          }
        } else {
          _logger.w('kategori_kode kosong/null, skip preselect kategori');
        }

        // Set default Jenis dokumen (edit mode) berdasarkan doc.kategoriSurat
        final js = doc.kategoriSurat?.trim();
        if (js != null && js.isNotEmpty) {
          if (_jenisController.items.isNotEmpty) {
            final exists = _jenisController.items.any((it) => it.kode == js);
            if (exists) {
              _jenisController.select(js);
              _handleJenisDokumenChanged(js);
              setState(() {});
            } else {
              _logger.w('kategori_surat tidak ditemukan di items: $js');
            }
          } else {
            once(_jenisController.items, (_) {
              final exists = _jenisController.items.any((it) => it.kode == js);
              if (exists) {
                _jenisController.select(js);
                _handleJenisDokumenChanged(js);
                setState(() {});
              } else {
                _logger.w('kategori_surat tidak ditemukan (after load): $js');
              }
            });
          }
        } else {
          _logger.w('kategori_surat kosong/null, skip preselect jenis');
        }

        // Set default Kategori laporan (edit mode) berdasarkan doc.kategoriSurat
        final kl = doc.kategoriSurat?.trim();
        if (kl != null && kl.isNotEmpty) {
          if (_kategoriLaporanController.items.isNotEmpty) {
            final exists =
                _kategoriLaporanController.items.any((it) => it.kode == kl);
            if (exists) {
              _kategoriLaporanController.select(kl);
              _handleKategoriLaporanChanged(kl);
              setState(() {});
            } else {
              _logger.w('kategori_laporan tidak ditemukan di items: $kl');
            }
          } else {
            once(_kategoriLaporanController.items, (_) {
              final exists =
                  _kategoriLaporanController.items.any((it) => it.kode == kl);
              if (exists) {
                _kategoriLaporanController.select(kl);
                _handleKategoriLaporanChanged(kl);
                setState(() {});
              } else {
                _logger.w('kategori_laporan tidak ditemukan (after load): $kl');
              }
            });
          }
        } else {
          _logger
              .w('kategori_surat kosong/null, skip preselect kategori laporan');
        }

        //Default Undangan kepada
        final kund = doc.kategoriUndangan?.trim();
        if (kund != null && kund.isNotEmpty) {
          if (_usersDropdownController.items.isNotEmpty) {
            final exists =
                _usersDropdownController.items.any((it) => it.id == kund);
            if (exists) {
              _usersDropdownController.select(kund);
              setState(() {});
            } else {
              _logger.w('kategori_undangan tidak ditemukan di items: $kl');
            }
          } else {
            once(_usersDropdownController.items, (_) {
              final exists =
                  _usersDropdownController.items.any((it) => it.id == kund);
              if (exists) {
                _usersDropdownController.select(kund);
                setState(() {});
              } else {
                _logger
                    .w('kategori_undangan tidak ditemukan (after load): $kl');
              }
            });
          }
        } else {
          _logger.w(
              'kategori_undangan kosong/null, skip preselect kategori laporan');
        }

        //Nomor Dokumen
        _docNumberPart1Controller.text = doc.documentNumber;
        _docNumberPart2Controller.text = doc.kategoriBerkas ?? '';

        //Tanggal Buat
        final rawTglNs = doc.tglNs?.trim();
        if (rawTglNs != null && rawTglNs.isNotEmpty) {
          final dtNs = DateTime.tryParse(rawTglNs);
          _todayDateController.text =
              dtNs != null ? DateFormat('dd-MM-yyyy').format(dtNs) : rawTglNs;
        } else {
          _todayDateController.text = '17-11-2025';
        }
        _logger.i('Tanggal Ns: ${doc.tglNs}');

        //Nomor dokumen
        String noSuratBerkas = doc.noAsal ?? '';
        String noSuratPart = noSuratBerkas.split('/')[0];
        _letterNumberPart1Controller.text = noSuratPart;
        _letterNumberPart2Controller.text = doc.klasifikasiSurat ?? '';

        //Tanggal Surat
        final rawTglSurat = doc.tglSurat?.trim();
        if (rawTglSurat != null && rawTglSurat.isNotEmpty) {
          final dt = DateTime.tryParse(rawTglSurat);
          _letterDateController.text =
              dt != null ? DateFormat('dd-MM-yyyy').format(dt) : rawTglSurat;
        } else {
          _letterDateController.text = '17-11-2025';
        }
        _logger.i('Tanggal Buat: ${doc.tglSurat}');

        //Pengirim
        _pengirimController.text = doc.pengirim ?? '';

        //Perihal dan Ringkasan
        _ringkasanController.text = doc.perihal ?? '';
        _perihalController.text = doc.penerima ?? '';

        //Ditujukan - Untuk kategori Laporan {Multi-select}
        final rawDitujukan = doc.ditujukan;
        if (rawDitujukan != null && rawDitujukan.trim().isNotEmpty) {
          if (_tujuanDisposisiController.items.isNotEmpty) {
            final codes = getDataFromDocDitujukan(
              raw: rawDitujukan,
              items: _tujuanDisposisiController.items,
              logger: _logger,
            );
            if (codes.isNotEmpty) {
              _selectedTujuanDisposisi
                ..clear()
                ..addAll(codes);
              setState(() {});
            }
          } else {
            _logger.w(
                'Items tujuan disposisi belum tersedia, menunggu load untuk mapping ditujukan');
            once(_tujuanDisposisiController.items, (_) {
              final codes = getDataFromDocDitujukan(
                raw: rawDitujukan,
                items: _tujuanDisposisiController.items,
                logger: _logger,
              );
              if (codes.isNotEmpty) {
                _selectedTujuanDisposisi
                  ..clear()
                  ..addAll(codes);
                setState(() {});
              } else {
                _logger.w(
                    'Mapping ditujukan menghasilkan kosong setelah load items');
              }
            });
          }
        } else {
          _logger
              .w('doc.ditujukan kosong/null, skip preselect tujuan disposisi');
        }

        // ------------------ R A P A T --------------------

        //tanggal agenda rapat
        final rawTglAgendaRapat = doc.tglAgendaRapat?.trim();
        if (rawTglAgendaRapat != null && rawTglAgendaRapat.isNotEmpty) {
          final dt = DateTime.tryParse(rawTglAgendaRapat);
          _meetingDateController.text = dt != null
              ? DateFormat('dd-MM-yyyy').format(dt)
              : rawTglAgendaRapat;
        } else {
          _meetingDateController.text = '17-11-2025';
        }
        _logger.i('Tanggal Agenda: ${doc.tglAgendaRapat}');

        //Waktu / Jam rapat
        _meetingTimeController.text = doc.jamRapat ?? '';

        // Pimpinan Rapat (single-select)
        final rawRuangRapat = doc.ruangRapat?.trim();
        if (rawRuangRapat != null && rawRuangRapat.isNotEmpty) {
          if (_ruangRapatController.items.isNotEmpty) {
            final kode = getKodeFromDocRuangRapat(
              raw: rawRuangRapat,
              items: _ruangRapatController.items,
              logger: _logger,
            );
            if (kode != null && kode.isNotEmpty) {
              _ruangRapatController.select(kode);
              setState(() {});
            }
          } else {
            _logger.w(
                'Items ruang rapat belum tersedia, menunggu load untuk mapping');
            once(_ruangRapatController.items, (_) {
              final kode = getKodeFromDocRuangRapat(
                raw: rawRuangRapat,
                items: _ruangRapatController.items,
                logger: _logger,
              );
              if (kode != null && kode.isNotEmpty) {
                _ruangRapatController.select(kode);
                setState(() {});
              } else {
                _logger.w(
                    'Mapping ruang rapat menghasilkan kosong setelah load items');
              }
            });
          }
        } else {
          _logger.w('doc.ruangRapat kosong/null, skip preselect ruang');
        }

        //Peserta Rapat (multi-select)
        final rawPesertaRapat = doc.pesertaRapat;
        if (rawPesertaRapat != null && rawPesertaRapat.trim().isNotEmpty) {
          if (_pesertaRapatController.items.isNotEmpty) {
            final codes = getDataFromDocDitujukan(
              raw: rawPesertaRapat,
              items: _pesertaRapatController.items,
              logger: _logger,
            );
            if (codes.isNotEmpty) {
              _selectedPesertaRapat
                ..clear()
                ..addAll(codes);
              setState(() {});
            }
          } else {
            _logger.w(
                'Items peserta rapat belum tersedia, menunggu load untuk mapping');
            once(_pesertaRapatController.items, (_) {
              final codes = getDataFromDocDitujukan(
                raw: rawPesertaRapat,
                items: _pesertaRapatController.items,
                logger: _logger,
              );
              if (codes.isNotEmpty) {
                _selectedPesertaRapat
                  ..clear()
                  ..addAll(codes);
                setState(() {});
              } else {
                _logger.w(
                    'Mapping peserta rapat menghasilkan kosong setelah load');
              }
            });
          }
        } else {
          _logger.w('doc.pesertaRapat kosong/null, skip preselect peserta');
        }

        // Pimpinan Rapat (single-select)
        final rawPimpinanRapat = doc.pimpinanRapat;
        if (rawPimpinanRapat != null && rawPimpinanRapat.trim().isNotEmpty) {
          if (_pimpinanRapatController.items.isNotEmpty) {
            final kode = getKodeFromDocPimpinanRapat(
              raw: rawPimpinanRapat,
              items: _pimpinanRapatController.items,
              logger: _logger,
            );
            if (kode != null && kode.isNotEmpty) {
              _pimpinanRapatController.select(kode);
              setState(() {});
            }
          } else {
            _logger.w(
                'Items pimpinan rapat belum tersedia, menunggu load untuk mapping');
            once(_pimpinanRapatController.items, (_) {
              final kode = getKodeFromDocPimpinanRapat(
                raw: rawPimpinanRapat,
                items: _pimpinanRapatController.items,
                logger: _logger,
              );
              if (kode != null && kode.isNotEmpty) {
                _pimpinanRapatController.select(kode);
                setState(() {});
              } else {
                _logger.w(
                    'Mapping pimpinan rapat menghasilkan kosong setelah load items');
              }
            });
          }
        } else {
          _logger.w('doc.pimpinanRapat kosong/null, skip preselect pimpinan');
        }

        //Bahasan rapat
        _pokokBahasanController.text = doc.bahasanRapat ?? '';

        // Lampiran
        /*
        final String name;
        final int size;
        final Uint8List? bytes;
        final String? path;
        double progress;
        bool uploading;
        bool success;
        String? error;
        String? tempId;
        String? tempUrl;
        */
        _uploadItems.addAll(
          doc.lampirans.map((l) {
            // final url = '${ApiConstants.baseUrl}/storage/${l.tokenLampiran}/${l.namaBerkas}';
            final url =
                '${ApiConstants.baseUrl}/storage/lampiran/${l.namaBerkas}';
            _logger.d({'lampiran': l.namaBerkas, 'lokasi': url});
            return _UploadItem(
              name: l.namaBerkas,
              tempId: l.idLampiran,
              tempUrl: url,
              size: int.tryParse(l.ukuran) ?? 0,
            );
          }).toList(growable: false),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat data dokumen untuk edit: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> _confirmLeaveIfDirty() async {
    if (!_hasUnsavedChanges) return true;
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Konfirmasi'),
        content:
            const Text('Perubahan belum disimpan. Apakah Anda ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Tetap di sini'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    return result ?? false;
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

class _UploadItem {
  final String name;
  final int size;
  final Uint8List? bytes;
  final String? path;
  double progress;
  bool uploading;
  bool success;
  String? error;
  String? tempId;
  String? tempUrl;
  dio.CancelToken? cancelToken;

  _UploadItem({
    required this.name,
    required this.size,
    this.bytes,
    this.path,
    this.progress = 0,
    this.uploading = false,
    this.success = false,
    this.error,
    this.tempId,
    this.tempUrl,
    this.cancelToken,
  });
}
