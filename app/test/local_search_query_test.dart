import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_client.dart';
import 'package:aletheia/catalog/local_search_query.dart';

void main() {
  test('convierte palabras y frases a términos FTS5 entrecomillados', () {
    expect(buildLocalFtsExpression('Verbo'), '"Verbo"');
    expect(buildLocalFtsExpression('"en el principio"'), '"en el principio"');
    expect(
      buildLocalFtsExpression('Verbo AND principio'),
      '"Verbo" AND "principio"',
    );
    expect(
      buildLocalFtsExpression('Verbo OR principio NOT Dios'),
      '"Verbo" OR "principio" NOT "Dios"',
    );
  });

  test('WITHIN se traduce a NEAR con el término de la derecha', () {
    expect(
      buildLocalFtsExpression('principio WITHIN 5 WORDS Verbo'),
      'NEAR("principio" "Verbo", 5)',
    );
    expect(
      buildLocalFtsExpression('"en el principio" within 3 words Dios'),
      'NEAR("en el principio" "Dios", 3)',
    );
  });

  test('NEAR usa 10 palabras por defecto y admite NEAR/5', () {
    expect(
      buildLocalFtsExpression('principio NEAR Verbo'),
      'NEAR("principio" "Verbo", 10)',
    );
    expect(
      buildLocalFtsExpression('principio NEAR/5 Verbo'),
      'NEAR("principio" "Verbo", 5)',
    );
    expect(
      buildLocalFtsExpression('"en el principio" NEAR Dios'),
      'NEAR("en el principio" "Dios", 10)',
    );
  });

  test('separa campos conocidos y conserva las frases entre comillas', () {
    final passage = parseLocalSearchQuery('bible:"Jn 3" Verbo');
    expect(passage.text, 'Verbo');
    expect(passage.expression, '"Verbo"');
    expect(passage.bible?.bookCode, 'JHN');
    expect(passage.bible?.chapter, 3);

    final filtered = parseLocalSearchQuery(
      'type:factbook language:es book:JHN gracia',
    );
    expect(filtered.type, 'factbook');
    expect(filtered.language, 'es');
    expect(filtered.book, 'JHN');
    expect(filtered.expression, '"gracia"');

    final quoted = parseLocalSearchQuery('"type:amor" Dios');
    expect(quoted.type, isNull);
    expect(quoted.expression, '"type:amor" "Dios"');
  });

  test('una consulta solo de filtros no genera expresión FTS', () {
    final query = parseLocalSearchQuery('bible:"Jn 3"');
    expect(query.expression, isNull);
    expect(query.hasFilters, isTrue);

    expect(() => parseLocalSearchQuery('type:factbook'), returnsNormally);
    expect(
      () => parseLocalSearchQuery('bible:"Libro inventado 3"'),
      throwsA(
        isA<CatalogException>().having(
          (error) => error.message,
          'mensaje',
          contains('referencia bíblica no válida'),
        ),
      ),
    );
    expect(
      () => parseLocalSearchQuery('book:NoExiste'),
      throwsA(
        isA<CatalogException>().having(
          (error) => error.message,
          'mensaje',
          contains('libro no encontrado'),
        ),
      ),
    );
  });

  test('los números y la puntuación quedan como términos citados', () {
    expect(buildLocalFtsExpression('3'), '"3"');
    expect(buildLocalFtsExpression('amor,'), '"amor,"');
  });

  test('rechaza consultas incompletas como el servicio', () {
    final cases = <String, String>{
      '': 'consulta vacía',
      '   ': 'consulta vacía',
      '"sin cerrar': 'comilla sin cerrar',
      'AND Dios': 'no puede ir al principio',
      'Dios AND': 'no puede terminar en operador',
      'WITHIN 3 WORDS Dios': 'WITHIN necesita un término delante',
      'Dios WITHIN 3 Dios': 'WITHIN necesita «WITHIN n WORDS término»',
      'Dios WORDS 3': 'palabra clave inesperada',
    };
    for (final entry in cases.entries) {
      expect(
        () => buildLocalFtsExpression(entry.key),
        throwsA(
          isA<CatalogException>().having(
            (error) => error.message,
            'mensaje',
            contains(entry.value),
          ),
        ),
        reason: 'consulta «${entry.key}»',
      );
    }
  });
}
