import 'package:flutter_test/flutter_test.dart';
import 'package:siap/presentation/utils/doc_number_logic.dart';

void main() {
  group('DocNumberPart2 Logic', () {
    test('Rapat sets static RPT and readOnly', () {
      final res = decideDocNumberPart2('Rapat');
      expect(res.value, 'RPT');
      expect(res.readOnly, true);
    });
    test('Undangan sets static UND and readOnly', () {
      final res = decideDocNumberPart2('Undangan');
      expect(res.value, 'UND');
      expect(res.readOnly, true);
    });

    test('Dokumen uses jenis kode when available', () {
      final res = decideDocNumberPart2('Dokumen', jenisKode: 'JD01');
      expect(res.value, 'JD01');
      expect(res.readOnly, false);
    });

    test('Dokumen empty jenis returns empty and editable', () {
      final res = decideDocNumberPart2('Dokumen', jenisKode: '');
      expect(res.value, '');
      expect(res.readOnly, false);
    });

    test('Laporan uses kategori laporan kode when available', () {
      final res = decideDocNumberPart2('Laporan', laporanKode: 'KL09');
      expect(res.value, 'KL09');
      expect(res.readOnly, false);
    });

    test('Laporan empty kategori returns empty and editable', () {
      final res = decideDocNumberPart2('Laporan', laporanKode: '');
      expect(res.value, '');
      expect(res.readOnly, false);
    });

    test('Unknown category returns empty and editable', () {
      final res = decideDocNumberPart2('Lainnya');
      expect(res.value, '');
      expect(res.readOnly, false);
    });
  });
}
