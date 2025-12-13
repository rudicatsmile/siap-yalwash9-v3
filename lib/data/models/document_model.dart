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
              : null,
      notes: json['notes'] ?? json['catatan'],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
    );
  }

  /// Convert DocumentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_number': documentNumber,
      'title': title,
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
    };
  }

  /// Create a copy with updated fields
  DocumentModel copyWith({
    int? id,
    String? documentNumber,
    String? title,
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
  }) {
    return DocumentModel(
      id: id ?? this.id,
      documentNumber: documentNumber ?? this.documentNumber,
      title: title ?? this.title,
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
      ];
}
