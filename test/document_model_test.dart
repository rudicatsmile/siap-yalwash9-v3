import 'package:flutter_test/flutter_test.dart';
import 'package:siap/data/models/document_model.dart';
import 'package:siap/core/constants/app_constants.dart';
import 'dart:convert';

void main() {
  group('DocumentModel lampirans', () {
    test('Deserialisasi dengan lampirans dari JSON', () {
      final jsonStr = '''
      {
        "id_sm": 52,
        "no_surat": "00764",
        "perihal": "R Bag 004",
        "status": "Dokumen",
        "lampirans": [
          {
            "id_lampiran": "727",
            "no_surat": "00764",
            "token_lampiran": "245c08692ece1c584c45cebc20471cda",
            "nama_berkas": "file1.jpg",
            "ukuran": "64664"
          },
          {
            "id_lampiran": "728",
            "no_surat": "00764",
            "token_lampiran": "245c08692ece1c584c45cebc20471cda",
            "nama_berkas": "file2.jpg",
            "ukuran": "12345"
          }
        ]
      }
      ''';
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final model = DocumentModel.fromJson(map);
      expect(model.documentNumber, '00764');
      expect(model.lampirans.length, 2);
      expect(model.lampirans.first.idLampiran, '727');
      expect(model.lampirans.first.namaBerkas, 'file1.jpg');
    });

    test('Serialisasi ke JSON menyertakan lampirans', () {
      final model = DocumentModel(
        id: 1,
        documentNumber: '00001',
        title: 'Judul',
        userId: 10,
        status: DocumentStatus.pending,
        statusRapat: MeetingStatus.noMeeting,
        submittedAt: DateTime.now().toIso8601String(),
        lampirans: const [
          LampiranModel(
            idLampiran: '1',
            noSurat: '00001',
            tokenLampiran: 'abc',
            namaBerkas: 'dok.pdf',
            ukuran: '100',
          ),
        ],
      );
      final jsonMap = model.toJson();
      expect(jsonMap['lampirans'], isA<List>());
      final lamp = (jsonMap['lampirans'] as List).first as Map;
      expect(lamp['id_lampiran'], '1');
      expect(lamp['nama_berkas'], 'dok.pdf');
    });

    test('Default lampirans adalah list kosong saat tidak ada di JSON', () {
      final model = DocumentModel.fromJson({
        'id_sm': 2,
        'no_surat': '00002',
        'perihal': 'Tanpa lampirans',
        'status': 'Dokumen',
      });
      expect(model.lampirans, isNotNull);
      expect(model.lampirans, isEmpty);
    });

    test('copyWith mempertahankan nilai dan dapat mengubah lampirans', () {
      final base = DocumentModel(
        id: 1,
        documentNumber: '00001',
        title: 'Judul',
        userId: 10,
        status: DocumentStatus.pending,
        statusRapat: MeetingStatus.noMeeting,
        submittedAt: DateTime.now().toIso8601String(),
      );
      final updated = base.copyWith(
        lampirans: const [
          LampiranModel(
            idLampiran: '2',
            noSurat: '00001',
            tokenLampiran: 'xyz',
            namaBerkas: 'file.png',
            ukuran: '55',
          ),
        ],
      );
      expect(updated.documentNumber, '00001');
      expect(updated.lampirans.length, 1);
      expect(updated.lampirans.first.namaBerkas, 'file.png');
    });
  });
}
