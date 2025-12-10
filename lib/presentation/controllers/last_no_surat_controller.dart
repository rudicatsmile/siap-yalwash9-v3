import 'package:get/get.dart';
import '../../data/models/last_no_surat_response.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/api_constants.dart';

class LastNoSuratController extends GetxController {
  final _api = ApiService();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<LastNoSuratResponse?> result = Rx<LastNoSuratResponse?>(null);

  Future<void> fetch() async {
    error.value = '';
    isLoading.value = true;
    try {
      final response = await _api.get(ApiConstants.documentsLastNoSurat);
      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      final statusCode = response.statusCode ?? 0;
      final statusField = (body['status'] is int)
          ? body['status'] as int
          : int.tryParse(body['status']?.toString() ?? '') ?? statusCode;

      if (statusField == 200) {
        final parsed = LastNoSuratResponse.fromJson(body);
        if (parsed.lastNoSurat.isEmpty && parsed.nextNoSurat.isEmpty) {
          error.value = 'Format data tidak sesuai';
          result.value = null;
        } else {
          result.value = parsed;
        }
      } else {
        error.value = body['message']?.toString() ?? 'Gagal mengambil data';
        result.value = null;
      }
    } catch (e) {
      error.value = e.toString();
      result.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}
