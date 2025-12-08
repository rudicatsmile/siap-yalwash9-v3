import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// Document status history model
class DocumentStatusHistoryModel extends Equatable {
  final int id;
  final int documentId;
  final DocumentStatus? previousStatus;
  final DocumentStatus newStatus;
  final int changedBy;
  final String? changedByName;
  final DateTime changedAt;
  final String? notes;

  const DocumentStatusHistoryModel({
    required this.id,
    required this.documentId,
    this.previousStatus,
    required this.newStatus,
    required this.changedBy,
    this.changedByName,
    required this.changedAt,
    this.notes,
  });

  /// Create DocumentStatusHistoryModel from JSON
  factory DocumentStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return DocumentStatusHistoryModel(
      id: json['id'] ?? 0,
      documentId: json['document_id'] ?? json['documentId'] ?? 0,
      previousStatus: json['previous_status'] != null 
          ? DocumentStatus.fromCode(json['previous_status']) 
          : json['previousStatus'] != null 
              ? DocumentStatus.fromCode(json['previousStatus']) 
              : null,
      newStatus: DocumentStatus.fromCode(
        json['new_status'] ?? json['newStatus'] ?? 1,
      ),
      changedBy: json['changed_by'] ?? json['changedBy'] ?? 0,
      changedByName: json['changed_by_name'] ?? json['changedByName'],
      changedAt: json['changed_at'] != null 
          ? DateTime.parse(json['changed_at']) 
          : json['changedAt'] != null 
              ? DateTime.parse(json['changedAt']) 
              : DateTime.now(),
      notes: json['notes'],
    );
  }

  /// Convert DocumentStatusHistoryModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'previous_status': previousStatus?.code,
      'new_status': newStatus.code,
      'changed_by': changedBy,
      'changed_by_name': changedByName,
      'changed_at': changedAt.toIso8601String(),
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        documentId,
        previousStatus,
        newStatus,
        changedBy,
        changedByName,
        changedAt,
        notes,
      ];
}

/// Department model
class DepartmentModel extends Equatable {
  final int id;
  final String name;
  final String code;
  final String? description;

  const DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
  });

  /// Create DepartmentModel from JSON
  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
    );
  }

  /// Convert DepartmentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, name, code, description];
}
