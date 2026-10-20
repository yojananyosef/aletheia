// Diferencias por palabra de la Comparación de textos (M5).
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/panels/text_diff.dart';

void main() {
  group('compareWords', () {
    test('textos idénticos dan 0 %', () {
      final diff = compareWords('EN el principio era el Verbo.',
          'EN el principio era el Verbo.');
      expect(diff.percent, 0);
      expect(diff.changed.every((value) => !value), isTrue);
    });

    test('una palabra distinta de cuatro da 25 %', () {
      final diff = compareWords('Dios es amor eterno', 'Dios es amor fiel');
      expect(diff.percent, 25);
      expect(diff.changed.length, 4);
      expect(diff.changed.last, isTrue);
      expect(diff.changed.take(3).any((value) => value), isFalse);
    });

    test('idiomas distintos dan 100 %', () {
      final diff = compareWords(
        'EN el principio era el Verbo.',
        'In the beginning was the Word.',
      );
      expect(diff.percent, 100);
    });

    test('la puntuación no cuenta como diferencia', () {
      final diff = compareWords('Vino, vio, venció', 'Vino vio venció');
      expect(diff.percent, 0);
    });

    test('palabra añadida al final', () {
      final diff = compareWords('Dios es amor', 'Dios es amor eterno');
      expect(diff.percent, 25);
      expect(diff.changed.last, isTrue);
    });

    test('texto vacío no rompe el cálculo', () {
      expect(compareWords('', '').percent, 0);
      expect(compareWords('Dios', '').percent, 0);
    });
  });
}
