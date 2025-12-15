import 'package:flutter_test/flutter_test.dart';
import 'package:siap/presentation/controllers/dropdown_controller.dart';
import 'package:siap/presentation/screens/documents/document_form_screen.dart';

void main() {
  group('getKodeFromDocPimpinanRapat', () {
    late List<DropdownItem> items;

    setUp(() {
      items = [
        DropdownItem(kode: 'KP01', deskripsi: 'KA. SUBAG PROTOKOLER'),
        DropdownItem(kode: 'DM02', deskripsi: 'KA SUBAG DATA DAN MEDIA'),
        DropdownItem(
            kode: 'SK03', deskripsi: 'STAF KEPEGAWAIAN DAN KELEMBAGAAN'),
      ];
    });

    test('Normal case returns matching kode', () {
      final raw = 'KA SUBAG DATA DAN MEDIA';
      final kode = getKodeFromDocPimpinanRapat(raw: raw, items: items);
      expect(kode, 'DM02');
    });

    test('Null input returns null', () {
      final kode = getKodeFromDocPimpinanRapat(raw: null, items: items);
      expect(kode, isNull);
    });

    test('Empty string returns null', () {
      final kode = getKodeFromDocPimpinanRapat(raw: '   ', items: items);
      expect(kode, isNull);
    });

    test('Unknown name returns null', () {
      final kode = getKodeFromDocPimpinanRapat(raw: 'UNKNOWN', items: items);
      expect(kode, isNull);
    });
  });
}
