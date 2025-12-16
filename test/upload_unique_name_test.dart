import 'package:flutter_test/flutter_test.dart';
import 'package:siap/presentation/screens/documents/document_form_screen.dart';

void main() {
  group('makeUniqueName', () {
    test('Returns candidate when no conflict', () {
      final existing = ['a.jpg', 'b.png'];
      final res = makeUniqueName(existing, 'c.jpg');
      expect(res, 'c.jpg');
    });

    test('Appends (1) when one conflict', () {
      final existing = ['a.jpg', 'b.png', 'c.jpg'];
      final res = makeUniqueName(existing, 'c.jpg');
      expect(res, 'c(1).jpg');
    });

    test('Appends incrementing number for multiple conflicts', () {
      final existing = ['c.jpg', 'c(1).jpg', 'c(2).jpg'];
      final res = makeUniqueName(existing, 'c.jpg');
      expect(res, 'c(3).jpg');
    });

    test('Handles no extension names', () {
      final existing = ['file', 'file(1)'];
      final res = makeUniqueName(existing, 'file');
      expect(res, 'file(2)');
    });
  });
}
