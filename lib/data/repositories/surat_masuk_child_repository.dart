import 'package:dio/dio.dart' as dio;
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class SuratMasukChildRepository {
  final ApiService _api;
  SuratMasukChildRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<dio.Response> insertChild(Map<String, dynamic> payload) async {
    return _api.post(
      ApiConstants.suratMasukChild,
      data: payload,
    );
  }
}

