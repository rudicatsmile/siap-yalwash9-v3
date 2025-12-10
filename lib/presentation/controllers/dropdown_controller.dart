import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/api_constants.dart';

class DropdownItem {
  final String kode;
  final String deskripsi;
  final String? keterangan;
  DropdownItem({required this.kode, required this.deskripsi, this.keterangan});
}

class DropdownController extends GetxController {
  final _api = ApiService();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<DropdownItem> items = <DropdownItem>[].obs;
  final RxString selectedKode = ''.obs;

  static final Map<String, List<DropdownItem>> _cache = {};

  Future<void> loadTable(String tableName, {int limit = 100}) async {
    error.value = '';
    isLoading.value = true;

    try {
      if (_cache.containsKey(tableName)) {
        items.assignAll(_cache[tableName]!);
        return;
      }

      final resp = await _api.get(
        ApiConstants.generalDropdown,
        queryParameters: {
          'table_name': tableName,
          'limit': limit,
        },
      );

      final data = resp.data;
      if (data is Map && data['success'] == true && data['data'] is List) {
        final list = (data['data'] as List)
            .map((e) => DropdownItem(
                  kode: e['kode']?.toString() ?? '',
                  deskripsi: e['deskripsi']?.toString() ?? '',
                  keterangan: e['keterangan']?.toString(),
                ))
            .where((it) => it.kode.isNotEmpty && it.deskripsi.isNotEmpty)
            .toList();

        items.assignAll(list);
        _cache[tableName] = list;
      } else {
        items.clear();
        error.value = 'Data tidak tersedia';
      }
    } catch (e) {
      error.value = e.toString();
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void select(String? kode) {
    selectedKode.value = (kode ?? '').trim();
  }
}
