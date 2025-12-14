import 'package:flutter_test/flutter_test.dart';
import 'package:siap/presentation/screens/documents/document_form_screen.dart';
import 'package:siap/presentation/controllers/dropdown_controller.dart';

void main() {
  group('getDataFromDocDitujukan', () {
    late List<DropdownItem> items;

    setUp(() {
      items = [
        DropdownItem(kode: 'KP01', deskripsi: 'KA. SUBAG PROTOKOLER'),
        DropdownItem(kode: 'DM02', deskripsi: 'KA SUBAG DATA DAN MEDIA'),
        DropdownItem(
            kode: 'SK03', deskripsi: 'STAF KEPEGAWAIAN DAN KELEMBAGAAN'),
      ];
    });

    test('Normal case with <br> delimiter', () {
      final raw =
          'KA. SUBAG PROTOKOLER<br>KA SUBAG DATA DAN MEDIA<br>STAF KEPEGAWAIAN DAN KELEMBAGAAN';
      final res = getDataFromDocDitujukan(
        raw: raw,
        items: items,
      );
      expect(res, ['KP01', 'DM02', 'SK03']);
    });

    test('Null input returns empty list', () {
      final res = getDataFromDocDitujukan(
        raw: null,
        items: items,
      );
      expect(res, isEmpty);
    });

    test('Empty string returns empty list', () {
      final res = getDataFromDocDitujukan(
        raw: '   ',
        items: items,
      );
      expect(res, isEmpty);
    });

    test('Invalid format (no matches) handled gracefully', () {
      final raw = 'UNKNOWN1<br>UNKNOWN2';
      final res = getDataFromDocDitujukan(
        raw: raw,
        items: items,
      );
      expect(res, isEmpty);
    });
  });
}
