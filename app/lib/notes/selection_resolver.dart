/// Resolución de una selección de texto del lector a un anclaje de nota (M4).
///
/// La UI entrega el texto seleccionado y los versículos visibles (texto plano);
/// aquí se decide a qué versículo —o tramo de versículos— pertenece y, si se
/// puede, el rango exacto dentro del texto plano. Puro y testeable.
///
/// Las selecciones que cruzan versículos se resuelven por *palabras*: el texto
/// seleccionado puede incluir los números de versículo del render (que aquí
/// no existen en el texto plano), y los saltos de línea del párrafo introducen
/// espacios adicionales; comparar tokens normalizados hace robustas ambas cosas.
library;

class SelectionVerse {
  const SelectionVerse({
    required this.bookCode,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  final String bookCode;
  final int chapter;
  final int verse;
  final String text;
}

class SelectionMatch {
  const SelectionMatch({
    required this.bookCode,
    required this.chapter,
    required this.verse,
    required this.start,
    required this.end,
    required this.quote,
    required this.exact,
    this.verseEnd,
  });

  final String bookCode;
  final int chapter;

  /// Primer versículo de la selección.
  final int verse;

  /// Último versículo de la selección cuando cruza varios (`null` si es un
  /// tramo de un solo versículo).
  final int? verseEnd;

  /// Rango dentro del texto plano del [verse] (inicio).
  final int start;

  /// Fin del rango: si [verseEnd] es nulo, dentro de [verse]; si no, dentro
  /// del texto plano del último versículo.
  final int end;

  /// Texto citado (normalizado).
  final String quote;

  /// `false` cuando la coincidencia es parcial (la selección cruzaba
  /// versículos o incluía indicadores).
  final bool exact;

  bool get isMultiVerse => verseEnd != null && verseEnd! > verse;
}

/// Devuelve el anclaje de la selección, o `null` si no hay coincidencia
/// razonable (la UI cae entonces al anclaje por referencia).
SelectionMatch? resolveSelection({
  required String selection,
  required Iterable<SelectionVerse> verses,
}) {
  final needle = selection.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (needle.isEmpty) return null;

  // 1) Coincidencia literal dentro de un versículo.
  for (final verse in verses) {
    final index = verse.text.indexOf(needle);
    if (index >= 0) {
      return SelectionMatch(
        bookCode: verse.bookCode,
        chapter: verse.chapter,
        verse: verse.verse,
        start: index,
        end: index + needle.length,
        quote: needle,
        exact: true,
      );
    }
  }

  // 2) Selección que cruza versículos o que intercala los números del render:
  //    comparación por palabras sobre la tira de tokens del capítulo.
  final match = _resolveByTokens(
    verses: verses,
    needle: needle,
    tokens: _tokensOf(verses),
  );
  if (match != null) return match;

  // 3) La selección pudo cruzar versículos o incluir indicadores: probamos con
  //    fragmentos iniciales cada vez más cortos.
  final words = needle.split(' ').where((w) => w.isNotEmpty).toList();
  for (final length in const [12, 8, 5, 3, 2]) {
    if (words.length < length) continue;
    final candidate = words.take(length).join(' ');
    for (final verse in verses) {
      final index = verse.text.indexOf(candidate);
      if (index >= 0) {
        return SelectionMatch(
          bookCode: verse.bookCode,
          chapter: verse.chapter,
          verse: verse.verse,
          start: index,
          end: index + candidate.length,
          quote: needle,
          exact: false,
        );
      }
    }
  }

  // 4) Último recurso: la primera palabra significativa.
  if (words.isNotEmpty && words.first.length >= 4) {
    final word = words.first;
    for (final verse in verses) {
      final index = verse.text.indexOf(word);
      if (index >= 0) {
        return SelectionMatch(
          bookCode: verse.bookCode,
          chapter: verse.chapter,
          verse: verse.verse,
          start: index,
          end: index + word.length,
          quote: needle,
          exact: false,
        );
      }
    }
  }
  return null;
}

SelectionMatch? _resolveByTokens({
  required Iterable<SelectionVerse> verses,
  required String needle,
  required List<_Token> tokens,
}) {
  // Palabras de la selección, sin los números de versículo del render.
  final wanted = <String>[];
  for (final word in needle.split(' ')) {
    if (word.isEmpty) continue;
    final norm = _normWord(word);
    if (norm.isEmpty || _pureDigits.hasMatch(norm)) continue;
    wanted.add(norm);
  }
  if (wanted.length < 2) return null; // los cortos ya los resolvió el paso 1.

  for (var i = 0; i < tokens.length; i++) {
    var t = i;
    var ok = true;
    for (final want in wanted) {
      // Salta los tokens numéricos insertados por el render del capítulo
      // (números de versículo dentro de la selección).
      while (t < tokens.length && tokens[t].isNumber) {
        t++;
      }
      if (t >= tokens.length || tokens[t].norm != want) {
        ok = false;
        break;
      }
      t++;
    }
    if (!ok) continue;

    final first = tokens[i];
    final last = tokens[t - 1];
    final startVerse = verses.elementAt(first.verseIndex);
    final endVerse = verses.elementAt(last.verseIndex);
    final multiVerse = endVerse.verse != startVerse.verse;
    // Coherencia: la tira de tokens es de un capítulo; mezclar libros no ocurre.
    if (startVerse.bookCode != endVerse.bookCode ||
        startVerse.chapter != endVerse.chapter) {
      continue;
    }
    return SelectionMatch(
      bookCode: startVerse.bookCode,
      chapter: startVerse.chapter,
      verse: startVerse.verse,
      verseEnd: multiVerse ? endVerse.verse : null,
      start: first.start,
      end: last.end,
      quote: needle,
      exact: true,
    );
  }
  return null;
}

final RegExp _pureDigits = RegExp(r'^\d+$');

/// Palabra para comparar: minúsculas y sin puntuación de borde (con semántica
/// unicode para no morder acentos: `amó` → `amó`, no `am`).
String _normWord(String word) => word
    .toLowerCase()
    .replaceAll(_edgePunctuation, '');

final RegExp _edgePunctuation = RegExp(
  r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$',
  unicode: true,
);

class _Token {
  const _Token({
    required this.verseIndex,
    required this.norm,
    required this.start,
    required this.end,
    required this.isNumber,
  });

  final int verseIndex;

  /// Palabra normalizada (minúsculas, sin puntuación de borde).
  final String norm;

  /// Rango dentro del texto plano del versículo.
  final int start;
  final int end;
  final bool isNumber;
}

/// Tira de tokens de todos los versículos (por orden), con su rango dentro del
/// texto plano del versículo de origen.
List<_Token> _tokensOf(Iterable<SelectionVerse> verses) {
  final tokens = <_Token>[];
  var verseIndex = 0;
  for (final verse in verses) {
    for (final match in RegExp(r'\S+').allMatches(verse.text)) {
      final raw = match.group(0) ?? '';
      final norm = _normWord(raw);
      if (norm.isEmpty) continue;
      tokens.add(
        _Token(
          verseIndex: verseIndex,
          norm: norm,
          start: match.start,
          end: match.end,
          isNumber: _pureDigits.hasMatch(norm),
        ),
      );
    }
    verseIndex++;
  }
  return tokens;
}
