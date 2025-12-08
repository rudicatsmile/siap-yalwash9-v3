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
  final DateTime submittedAt;
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
    return DocumentModel(
      id: json['id'] ?? 0,
      documentNumber: json['document_number'] ?? json['documentNumber'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      userId: json['user_id'] ?? json['userId'] ?? 0,
      userName: json['user_name'] ?? json['userName'],
      departemenId: json['departemen_id'] ?? json['departemenId'],
      departemenName: json['departemen_name'] ?? json['departemenName'],
      status: DocumentStatus.fromCode(json['status'] ?? 1),
      statusRapat: MeetingStatus.fromCode(json['status_rapat'] ?? json['statusRapat'] ?? 0),
      submittedAt: json['submitted_at'] != null 
          ? DateTime.parse(json['submitted_at']) 
          : json['submittedAt'] != null 
              ? DateTime.parse(json['submittedAt']) 
              : DateTime.now(),
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
      notes: json['notes'],
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
      'submitted_at': submittedAt.toIso8601String(),
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
    DateTime? submittedAt,
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
        submittedAt,
        updatedAt,
        approvedBy,
        approverName,
        approvedAt,
        notes,
        attachments,
      ];
}
