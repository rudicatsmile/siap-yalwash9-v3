import 'package:logger/logger.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';

/// Repository for document operations
class DocumentRepository {
  final _apiService = ApiService();
  final _logger = Logger();
  String _formatInsertSql(String table, Map<String, dynamic> data) {
    final cols = data.keys.join(', ');
    String _val(dynamic v) {
      if (v == null) return 'NULL';
      if (v is num || v is bool) return v.toString();
      final s = v.toString().replaceAll("'", "''");
      return "'$s'";
    }

    final vals = data.values.map(_val).join(', ');
    return 'INSERT INTO $table ($cols) VALUES ($vals);';
  }

  String _formatUpdateSql(String table, int id, Map<String, dynamic> data) {
    String _val(dynamic v) {
      if (v == null) return 'NULL';
      if (v is num || v is bool) return v.toString();
      final s = v.toString().replaceAll("'", "''");
      return "'$s'";
    }

    final sets =
        data.entries.map((e) => '${e.key} = ${_val(e.value)}').join(', ');
    return 'UPDATE $table SET $sets WHERE id_sm = $id;';
  }

  /// Get documents based on role and filters
  Future<List<DocumentModel>> getDocuments({
    UserRole? role,
    int? userId,
    int? departemenId,
    int? status,
    int? statusRapat,
    String? search,
    String? dibaca,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      _logger.d('GET /api/documents - start');

      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': limit,
        if (role != null) 'role': role.code,
        if (userId != null) 'user_id': userId,
        if (departemenId != null) 'departemen_id': departemenId,
        if (status != null) 'status': status,
        if (statusRapat != null) 'status_rapat': statusRapat,
        if (search != null && search.isNotEmpty) 'search': search,
        if (dibaca != null && dibaca.isNotEmpty) 'dibaca': dibaca,
      };
      _logger.i({'endpoint': ApiConstants.documents, 'query': queryParams});

      final response = await _apiService.get(
        ApiConstants.documents,
        queryParameters: queryParams,
      );
      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final bool ok = (body['success'] == true) ||
          ((body['status'] is int) &&
              (body['status'] >= 200 && body['status'] < 300)) ||
          ((response.statusCode ?? 0) >= 200 &&
              (response.statusCode ?? 0) < 300);
      _logger.i({'status': response.statusCode, 'ok': ok});

      final List<dynamic> data = (body['data'] is List)
          ? (body['data'] as List)
          : (response.data is List ? (response.data as List) : <dynamic>[]);
      _logger.d({'count': data.length});
      if (ok && data.isNotEmpty) {
        return data.map((json) => DocumentModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      _logger.e('Failed to fetch documents: $e');
      rethrow;
    }
  }

  /// Get document by ID
  Future<DocumentModel?> getDocumentById(int id) async {
    try {
      _logger.d('Fetching document with ID: $id');

      final response = await _apiService.get(
        ApiConstants.documentDetail(id),
      );

      if (response.data['success'] == true) {
        return DocumentModel.fromJson(response.data['data']);
      }

      return null;
    } catch (e) {
      _logger.e('Failed to fetch document $id: $e');
      rethrow;
    }
  }

  /// Create new document
  Future<DocumentModel> createDocument(Map<String, dynamic> data) async {
    try {
      _logger.d('Creating new document');
      final sql = _formatInsertSql('documents', data);
      _logger.i({'sql_insert': sql});

      final response = await _apiService.post(
        ApiConstants.documents,
        data: data,
      );

      if (response.data['success'] == true) {
        _logger.i('Document created successfully');
        return DocumentModel.fromJson(response.data['data']);
      }

      throw Exception('Failed to create document');
    } catch (e) {
      _logger.e('Failed to create document: $e');
      rethrow;
    }
  }

  /// Update document
  Future<DocumentModel> updateDocument(
      int id, Map<String, dynamic> data) async {
    final sql = _formatUpdateSql('tbl_sm', id, data);

    try {
      _logger.d('Updating document $id');
      // final sql = _formatUpdateSql('documents', id, data);
      _logger.i({'sql_update': sql});

      final response = await _apiService.put(
        ApiConstants.documentDetail(id),
        data: data,
      );

      // 'message' => 'Document updated successfully',

      // if (response.data['success'] == true) {
      if (response.data['message'] == 'Document updated successfully') {
        _logger.i('Document updated successfully');
        return DocumentModel.fromJson(response.data['data']);
      }

      _logger.e({
        'sql_update': sql,
        'update_failed': true,
        'status': response.statusCode,
        'body': response.data,
      });
      throw Exception('Failed to update document');
    } catch (e) {
      _logger.e({
        'message': 'Failed to update document',
        'error': e.toString(),
        'sql_update': _formatUpdateSql('documents', id, data),
      });
      rethrow;
    }
  }

  /// Delete document
  Future<void> deleteDocument(int id) async {
    try {
      _logger.d('Deleting document $id');

      await _apiService.delete(ApiConstants.documentDetail(id));
      _logger.i('Document deleted successfully');
    } catch (e) {
      _logger.e('Failed to delete document: $e');
      rethrow;
    }
  }

  /// Update document status
  Future<DocumentModel> updateDocumentStatus({
    required int id,
    required int status,
    int? statusRapat,
    String? notes,
  }) async {
    try {
      _logger.d('Updating document status: $id -> $status');

      final response = await _apiService.put(
        ApiConstants.updateDocumentStatus(id),
        data: {
          'status': status,
          if (statusRapat != null) 'status_rapat': statusRapat,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.data['success'] == true) {
        _logger.i('Document status updated successfully');
        return DocumentModel.fromJson(response.data['data']);
      }

      throw Exception('Failed to update document status');
    } catch (e) {
      _logger.e('Failed to update document status: $e');
      rethrow;
    }
  }

  /// Get meeting documents
  Future<List<DocumentModel>> getMeetingDocuments({
    UserRole? role,
  }) async {
    try {
      _logger.d('Fetching meeting documents');

      final queryParams = <String, dynamic>{
        if (role != null) 'role': role.code,
      };

      final response = await _apiService.get(
        ApiConstants.meetings,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => DocumentModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      _logger.e('Failed to fetch meeting documents: $e');
      rethrow;
    }
  }

  /// Make meeting decision
  Future<DocumentModel> makeMeetingDecision({
    required int id,
    required int status,
    String? notes,
  }) async {
    try {
      _logger.d('Making meeting decision for document $id');

      final response = await _apiService.post(
        ApiConstants.meetingDecision(id),
        data: {
          'status': status,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.data['success'] == true) {
        _logger.i('Meeting decision recorded successfully');
        return DocumentModel.fromJson(response.data['data']);
      }

      throw Exception('Failed to make meeting decision');
    } catch (e) {
      _logger.e('Failed to make meeting decision: $e');
      rethrow;
    }
  }

  /// Get document history
  Future<List<DocumentModel>> getHistory({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      _logger.d('Fetching document history for user $userId');

      final queryParams = <String, dynamic>{
        'user_id': userId,
        'limit': limit,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await _apiService.get(
        ApiConstants.history,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => DocumentModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      _logger.e('Failed to fetch document history: $e');
      rethrow;
    }
  }
}
