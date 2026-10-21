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

  test('BEFORE exige ambos términos y conserva el orden', () {
    final query = parseLocalSearchQuery('principio BEFORE Verbo');
    expect(query.expression, '"principio" AND "Verbo"');
    expect(query.before, hasLength(1));
    expect(query.before.single.left, 'principio');
    expect(query.before.single.right, 'Verbo');

    expect(
      buildLocalFtsExpression('"en el principio" before "el Verbo"'),
      '"en el principio" AND "el Verbo"',
    );
    expect(
      buildLocalFtsExpression('principio BEFORE Verbo AND Dios'),
      '"principio" AND "Verbo" AND "Dios"',
    );
  });

  test('rechaza BEFORE sin dos términos simples', () {
    final cases = <String, String>{
      'BEFORE Verbo': 'BEFORE necesita un término delante',
      'principio BEFORE': 'BEFORE necesita un término a la derecha',
      'principio BEFORE AND Verbo': 'BEFORE necesita un término a la derecha',
      'principio NEAR Verbo BEFORE Dios':
          'BEFORE necesita un término simple a la izquierda',
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
