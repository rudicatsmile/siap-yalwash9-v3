import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// Document model representing document data
class DocumentModel extends Equatable {
  final int id;
  final String documentNumber;
  final String title;
  final String? description;
  final int userId;
  final String? userName;
  final int? departemenId;
  final String? departemenName;
  final DocumentStatus status;
  final MeetingStatus statusRapat;
  final String? dibaca;
  final String submittedAt;
  final DateTime? updatedAt;
  final int? approvedBy;
  final String? approverName;
  final DateTime? approvedAt;
  final String? notes;
  final List<String>? attachments;
  final String? instansiId;
  final String? sifat;
  final String? kodeUser;
  final String? kodeUserApproved;
  final int? idUserApproved;
  final String? tglSurat;
  final String? tglNs;
  final String? noAsal;
  final String? pengirim;
  final String? penerima;
  final String? perihal;
  final String? kategoriBerkas;
  final String? kategoriSurat;
  final String? kategoriUndangan;
  final String? kategoriKode;
  final String? kodeBerkas;
  final String? klasifikasiSurat;
  final String? idStatusRapat;
  final String? tglAgendaRapat;
  final String? jamRapat;
  final String? ruangRapat;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  /// ID instansi yang meng-approve dokumen rapat
  final int? idInstansiApproved;

  /// ID user sebagai pimpinan disposisi (leader) untuk rapat
  final int? idUserDisposisiLeader;

  /// Catatan disposisi terkait dokumen/rapat
  final String? disposisi;

  /// Penanda tangan rapat (nama atau identitas)
  final String? penandaTanganRapat;

  /// Tembusan rapat (pihak yang mendapatkan salinan)
  final String? tembusanRapat;

  /// Bahasan rapat (topik/agenda bahasan)
  final String? bahasanRapat;

  /// Pimpinan rapat (nama pimpinan rapat)
  final String? pimpinanRapat;

  /// Peserta rapat (nama/identitas peserta digabung)
  final String? pesertaRapat;

  /// Pihak/instansi yang dituju oleh dokumen/rapat
  final String? ditujukan;

  /// Instruksi kerja yang dihasilkan dari rapat
  final String? instruksiKerja;

  /// Disposisi memo terkait rapat/dokumen
  final String? disposisiMemo;

  /// KTU Disposisi
  final String? ktuDisposisi;

  /// Daftar lampiran (tbl_lampiran) terkait dokumen, mengikuti struktur JSON backend
  /// berisi objek dengan properti:
  /// - id_lampiran (String)
  /// - no_surat (String)
  /// - token_lampiran (String)
  /// - nama_berkas (String)
  /// - ukuran (String)
  final List<LampiranModel> lampirans;

  const DocumentModel({
    required this.id,
    required this.documentNumber,
    required this.title,
    this.description,
    required this.userId,
    this.userName,
    this.departemenId,
    this.departemenName,
    required this.status,
    required this.statusRapat,
    this.dibaca,
    required this.submittedAt,
    this.updatedAt,
    this.approvedBy,
    this.approverName,
    this.approvedAt,
    this.notes,
    this.attachments,
    this.instansiId,
    this.sifat,
    this.kodeUser,
    this.kodeUserApproved,
    this.idUserApproved,
    this.tglSurat,
    this.tglNs,
    this.noAsal,
    this.pengirim,
    this.penerima,
    this.perihal,
    this.kategoriBerkas,
    this.kategoriSurat,
    this.kategoriUndangan,
    this.kategoriKode,
    this.kodeBerkas,
    this.klasifikasiSurat,
    this.idStatusRapat,
    this.tglAgendaRapat,
    this.jamRapat,
    this.ruangRapat,
    this.createdAt,
    this.deletedAt,
    this.idInstansiApproved,
    this.idUserDisposisiLeader,
    this.disposisi,
    this.penandaTanganRapat,
    this.tembusanRapat,
    this.bahasanRapat,
    this.pimpinanRapat,
    this.pesertaRapat,
    this.ditujukan,
    this.instruksiKerja,
    this.disposisiMemo,
    this.ktuDisposisi,
    this.lampirans = const <LampiranModel>[],
  });

  /// Create DocumentModel from JSON
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is String) {
        final parsed = int.tryParse(v.trim());
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    String _asString(dynamic v, {String fallback = ''}) {
      if (v is String) return v;
      if (v != null) return v.toString();
      return fallback;
    }

    int _mapStatus(dynamic v) {
      if (v is int) return v;
      final s = _asString(v).toLowerCase().trim();
      switch (s) {
        case 'ditolak':
          return DocumentStatus.rejected.code;
        case 'diajukan':
        case 'dokumen':
          return DocumentStatus.pending.code;
        case 'diteruskan ke koordinator':
          return DocumentStatus.forwardedToCoordinator.code;
        case 'disetujui':
          return DocumentStatus.approved.code;
        case 'rapat koordinator':
        case 'rapat':
          return DocumentStatus.coordinatorMeeting.code;
        case 'diteruskan ke pimpinan utama':
          return DocumentStatus.forwardedToMainLeader.code;
        case 'dikembalikan':
          return DocumentStatus.returned.code;
        default:
          return DocumentStatus.pending.code;
      }
    }

    int _mapMeetingStatus(dynamic v) {
      if (v is int) return v;
      final s = _asString(v).toLowerCase().trim();
      switch (s) {
        case 'dijadwalkan rapat':
        case 'dijadwalkan':
          return MeetingStatus.scheduled.code;
        default:
          return MeetingStatus.noMeeting.code;
      }
    }

    return DocumentModel(
      id: _asInt(json['id'] ?? json['id_sm'] ?? 0),
      documentNumber: _asString(
        json['document_number'] ?? json['documentNumber'] ?? json['no_surat'],
      ),
      title: _asString(json['title'] ?? json['perihal']),
      perihal: _asString(json['perihal'] ?? json['title']),
      description: json['description'] ?? json['catatan'],
      userId: _asInt(json['user_id'] ?? json['userId'] ?? json['id_user'] ?? 0),
      userName: json['user_name'] ??
          json['userName'] ??
          (json['user'] is Map<String, dynamic>
              ? (json['user']['nama_lengkap']?.toString())
              : null),
      departemenId: json['departemen_id'] ?? json['departemenId'],
      departemenName: json['departemen_name'] ?? json['departemenName'],
      status: DocumentStatus.fromCode(_mapStatus(json['status'])),
      statusRapat: MeetingStatus.fromCode(
          _mapMeetingStatus(json['status_rapat'] ?? json['statusRapat'])),
      dibaca: _asString(json['dibaca']),
      submittedAt: _asString(
        json['submitted_at'] ??
            json['submittedAt'] ??
            json['tgl_sm'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null,
      approvedBy: json['approved_by'] ?? json['approvedBy'],
      approverName: json['approver_name'] ?? json['approverName'],
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'])
          : json['approvedAt'] != null
              ? DateTime.tryParse(json['approvedAt'])
              : json['tgl_approved'] != null
                  ? DateTime.tryParse(json['tgl_approved'])
                  : null,
      notes: json['notes'] ?? json['catatan'],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      instansiId: _asString(json['id_instansi']),
      sifat: _asString(json['sifat']),
      kodeUser: _asString(json['kode_user']),
      kodeUserApproved: _asString(json['kode_user_approved']),
      idUserApproved: _asInt(json['id_user_approved']),
      tglSurat: _asString(json['tgl_surat']),
      tglNs: _asString(json['tgl_ns']),
      noAsal: _asString(json['no_asal']),
      pengirim: _asString(json['pengirim']),
      penerima: _asString(json['penerima']),
      kategoriBerkas: _asString(json['kategori_berkas']),
      kategoriSurat: _asString(json['kategori_surat']),
      kategoriUndangan: _asString(json['kategori_undangan']),
      kategoriKode: _asString(json['kategori_kode']),
      kodeBerkas: _asString(json['kode_berkas']),
      klasifikasiSurat: _asString(json['klasifikasi_surat']),
      idStatusRapat: _asString(json['id_status_rapat']),
      tglAgendaRapat: _asString(json['tgl_agenda_rapat']),
      jamRapat: _asString(json['jam_rapat']),
      ruangRapat: _asString(json['ruang_rapat']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
      idInstansiApproved:
          _asInt(json['id_instansi_approved'] ?? json['idInstansiApproved']),
      idUserDisposisiLeader: _asInt(
          json['id_user_disposisi_leader'] ?? json['idUserDisposisiLeader']),
      disposisi: _asString(json['disposisi']),
      penandaTanganRapat:
          _asString(json['penanda_tangan_rapat'] ?? json['penandaTanganRapat']),
      tembusanRapat: _asString(json['tembusan_rapat'] ?? json['tembusanRapat']),
      bahasanRapat: _asString(json['bahasan_rapat'] ?? json['bahasanRapat']),
      pimpinanRapat: _asString(json['pimpinan_rapat'] ?? json['pimpinanRapat']),
      // pesertaRapat: (() {
      //   final raw = json['peserta_rapat'] ?? json['pesertaRapat'];
      //   if (raw is List) {
      //     final list = raw
      //         .map((e) => e?.toString() ?? '')
      //         .map((e) => e.trim())
      //         .where((e) => e.isNotEmpty)
      //         .toList();
      //     if (list.isEmpty) return null;
      //     return list.join('<br>');
      //   } else if (raw is String) {
      //     final s = raw.trim();
      //     if (s.isEmpty) return null;
      //     return s;
      //   }
      //   return null;
      // })(),

      pesertaRapat: _asString(json['peserta_rapat'] ?? json['pesertaRapat']),
      ditujukan: _asString(json['ditujukan']),
      instruksiKerja:
          _asString(json['instruksi_kerja'] ?? json['instruksiKerja']),
      disposisiMemo: _asString(json['disposisi_memo'] ?? json['disposisiMemo']),
      ktuDisposisi: _asString(json['ktu_disposisi'] ?? json['ktuDisposisi']),
      lampirans: (() {
        final raw = json['lampirans'];
        if (raw is List) {
          return raw
              .whereType<Map<String, dynamic>>()
              .map(LampiranModel.fromJson)
              .toList(growable: false);
        }
        return const <LampiranModel>[];
      })(),
    );
  }

  /// Convert DocumentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_number': documentNumber,
      'title': title,
      'perihal': perihal ?? title,
      'description': description,
      'user_id': userId,
      'user_name': userName,
      'departemen_id': departemenId,
      'departemen_name': departemenName,
      'status': status.code,
      'status_rapat': statusRapat.code,
      'dibaca': dibaca,
      'submitted_at': submittedAt,
      'updated_at': updatedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'approver_name': approverName,
      'approved_at': approvedAt?.toIso8601String(),
      'notes': notes,
      'attachments': attachments,
      'id_instansi': instansiId,
      'sifat': sifat,
      'kode_user': kodeUser,
      'kode_user_approved': kodeUserApproved,
      'id_user_approved': idUserApproved,
      'tgl_surat': tglSurat,
      'tgl_ns': tglNs,
      'no_asal': noAsal,
      'pengirim': pengirim,
      'penerima': penerima,
      'kategori_berkas': kategoriBerkas,
      'kategori_surat': kategoriSurat,
      'kategori_undangan': kategoriUndangan,
      'kategori_kode': kategoriKode,
      'kode_berkas': kodeBerkas,
      'klasifikasi_surat': klasifikasiSurat,
      'id_status_rapat': idStatusRapat,
      'tgl_agenda_rapat': tglAgendaRapat,
      'jam_rapat': jamRapat,
      'ruang_rapat': ruangRapat,
      'created_at': createdAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'id_instansi_approved': idInstansiApproved,
      'id_user_disposisi_leader': idUserDisposisiLeader,
      'disposisi': disposisi,
      'penanda_tangan_rapat': penandaTanganRapat,
      'tembusan_rapat': tembusanRapat,
      'bahasan_rapat': bahasanRapat,
      'pimpinan_rapat': pimpinanRapat,
      'peserta_rapat': pesertaRapat,
      'ditujukan': ditujukan,
      'instruksi_kerja': instruksiKerja,
      'disposisi_memo': disposisiMemo,
      'lampirans': lampirans.map((e) => e.toJson()).toList(growable: false),
    };
  }

  /// Create a copy with updated fields
  DocumentModel copyWith({
    int? id,
    String? documentNumber,
    String? title,
    String? perihal,
    String? description,
    int? userId,
    String? userName,
    int? departemenId,
    String? departemenName,
    DocumentStatus? status,
    MeetingStatus? statusRapat,
    String? submittedAt,
    DateTime? updatedAt,
    int? approvedBy,
    String? approverName,
    DateTime? approvedAt,
    String? notes,
    List<String>? attachments,
    String? instansiId,
    String? sifat,
    String? kodeUser,
    String? kodeUserApproved,
    int? idUserApproved,
    String? tglSurat,
    String? tglNs,
    String? noAsal,
    String? pengirim,
    String? penerima,
    String? kategoriBerkas,
    String? kategoriSurat,
    String? kategoriUndangan,
    String? kategoriKode,
    String? kodeBerkas,
    String? klasifikasiSurat,
    String? idStatusRapat,
    String? tglAgendaRapat,
    String? jamRapat,
    String? ruangRapat,
    DateTime? createdAt,
    DateTime? deletedAt,
    int? idInstansiApproved,
    int? idUserDisposisiLeader,
    String? disposisi,
    String? penandaTanganRapat,
    String? tembusanRapat,
    String? bahasanRapat,
    String? pimpinanRapat,
    String? pesertaRapat,
    String? ditujukan,
    String? instruksiKerja,
    String? disposisiMemo,
    List<LampiranModel>? lampirans,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      documentNumber: documentNumber ?? this.documentNumber,
      title: title ?? this.title,
      perihal: perihal ?? this.perihal,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      departemenId: departemenId ?? this.departemenId,
      departemenName: departemenName ?? this.departemenName,
      status: status ?? this.status,
      statusRapat: statusRapat ?? this.statusRapat,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approverName: approverName ?? this.approverName,
      approvedAt: approvedAt ?? this.approvedAt,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      instansiId: instansiId ?? this.instansiId,
      sifat: sifat ?? this.sifat,
      kodeUser: kodeUser ?? this.kodeUser,
      kodeUserApproved: kodeUserApproved ?? this.kodeUserApproved,
      idUserApproved: idUserApproved ?? this.idUserApproved,
      tglSurat: tglSurat ?? this.tglSurat,
      tglNs: tglNs ?? this.tglNs,
      noAsal: noAsal ?? this.noAsal,
      pengirim: pengirim ?? this.pengirim,
      penerima: penerima ?? this.penerima,
      kategoriBerkas: kategoriBerkas ?? this.kategoriBerkas,
      kategoriSurat: kategoriSurat ?? this.kategoriSurat,
      kategoriUndangan: kategoriUndangan ?? this.kategoriUndangan,
      kategoriKode: kategoriKode ?? this.kategoriKode,
      kodeBerkas: kodeBerkas ?? this.kodeBerkas,
      klasifikasiSurat: klasifikasiSurat ?? this.klasifikasiSurat,
      idStatusRapat: idStatusRapat ?? this.idStatusRapat,
      tglAgendaRapat: tglAgendaRapat ?? this.tglAgendaRapat,
      jamRapat: jamRapat ?? this.jamRapat,
      ruangRapat: ruangRapat ?? this.ruangRapat,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      idInstansiApproved: idInstansiApproved ?? this.idInstansiApproved,
      idUserDisposisiLeader:
          idUserDisposisiLeader ?? this.idUserDisposisiLeader,
      disposisi: disposisi ?? this.disposisi,
      penandaTanganRapat: penandaTanganRapat ?? this.penandaTanganRapat,
      tembusanRapat: tembusanRapat ?? this.tembusanRapat,
      bahasanRapat: bahasanRapat ?? this.bahasanRapat,
      pimpinanRapat: pimpinanRapat ?? this.pimpinanRapat,
      pesertaRapat: pesertaRapat ?? this.pesertaRapat,
      ditujukan: ditujukan ?? this.ditujukan,
      instruksiKerja: instruksiKerja ?? this.instruksiKerja,
      disposisiMemo: disposisiMemo ?? this.disposisiMemo,
      ktuDisposisi: ktuDisposisi ?? this.ktuDisposisi,
      lampirans: lampirans ?? this.lampirans,
    );
  }

  bool get canEdit => status.canEdit;
  bool get isFinal => status.isFinal;
  bool get hasMeeting => statusRapat == MeetingStatus.scheduled;
  bool get isRead {
    final s = dibaca?.toLowerCase().trim();
    return s == '1' || s == 'true';
  }

  @override
  List<Object?> get props => [
        id,
        documentNumber,
        title,
        perihal,
        description,
        userId,
        userName,
        departemenId,
        departemenName,
        status,
        statusRapat,
        dibaca,
        submittedAt,
        updatedAt,
        approvedBy,
        approverName,
        approvedAt,
        notes,
        attachments,
        instansiId,
        sifat,
        kodeUser,
        kodeUserApproved,
        idUserApproved,
        tglSurat,
        tglNs,
        noAsal,
        pengirim,
        penerima,
        kategoriBerkas,
        kategoriSurat,
        kategoriUndangan,
        kategoriKode,
        kodeBerkas,
        klasifikasiSurat,
        idStatusRapat,
        tglAgendaRapat,
        jamRapat,
        ruangRapat,
        createdAt,
        deletedAt,
        idInstansiApproved,
        idUserDisposisiLeader,
        disposisi,
        penandaTanganRapat,
        tembusanRapat,
        bahasanRapat,
        pimpinanRapat,
        pesertaRapat,
        ditujukan,
        instruksiKerja,
        disposisiMemo,
        ktuDisposisi,
        lampirans,
      ];
}

/// Model untuk satu entri lampiran dokumen (tbl_lampiran)
class LampiranModel extends Equatable {
  /// ID lampiran (string seperti pada JSON backend)
  final String idLampiran;

  /// Nomor surat (string)
  final String noSurat;

  /// Token lampiran (string)
  final String tokenLampiran;

  /// Nama berkas asli (string)
  final String namaBerkas;

  /// Ukuran berkas (string)
  final String ukuran;

  const LampiranModel({
    required this.idLampiran,
    required this.noSurat,
    required this.tokenLampiran,
    required this.namaBerkas,
    required this.ukuran,
  });

  /// Deserialisasi dari JSON dengan kunci snake_case sesuai backend
  factory LampiranModel.fromJson(Map<String, dynamic> json) {
    String _asString(dynamic v, {String fallback = ''}) {
      if (v is String) return v;
      if (v != null) return v.toString();
      return fallback;
    }

    return LampiranModel(
      idLampiran: _asString(json['id_lampiran']),
      noSurat: _asString(json['no_surat']),
      tokenLampiran: _asString(json['token_lampiran']),
      namaBerkas: _asString(json['nama_berkas']),
      ukuran: _asString(json['ukuran']),
    );
  }

  /// Serialisasi ke JSON dengan kunci yang sama seperti backend
  Map<String, dynamic> toJson() {
    return {
      'id_lampiran': idLampiran,
      'no_surat': noSurat,
      'token_lampiran': tokenLampiran,
      'nama_berkas': namaBerkas,
      'ukuran': ukuran,
    };
  }

  @override
  List<Object?> get props => [
        idLampiran,
        noSurat,
        tokenLampiran,
        namaBerkas,
        ukuran,
      ];
}
