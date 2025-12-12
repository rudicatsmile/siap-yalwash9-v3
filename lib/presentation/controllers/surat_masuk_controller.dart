import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../data/services/api_service.dart';
import '../../core/constants/api_constants.dart';

class SuratMasukController extends GetxController {
  final isSubmitting = false.obs;
  final error = ''.obs;
  final _api = ApiService();

  Future<dio.Response> submit(Map<String, dynamic> payload) async {
    try {
      isSubmitting.value = true;
      error.value = '';
      final res = await _api.post(
        ApiConstants.suratMasuk,
        data: payload,
      );
      return res;
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isSubmitting.value = false;
    }
  }
}
