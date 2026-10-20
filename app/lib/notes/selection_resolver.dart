/// Resolución de una selección de texto del lector a un anclaje de nota (M4).
///
/// La UI entrega el texto seleccionado y los versículos visibles (texto plano);
/// aquí se decide a qué versículo pertenece y, si se puede, el rango exacto
/// dentro de su texto plano. Puro y testeable.
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
  });

  final String bookCode;
  final int chapter;
  final int verse;

  /// Rango dentro del texto plano del versículo.
  final int start;
  final int end;

  /// Texto citado (normalizado).
  final String quote;

  /// `false` cuando la coincidencia es parcial (la selección cruzaba
  /// versículos o incluía indicadores).
  final bool exact;
}

/// Devuelve el anclaje del versículo que contiene [selection], o `null` si no
/// hay coincidencia razonable (la UI cae entonces al anclaje por referencia).
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

  // 2) La selección pudo cruzar versículos o incluir el número de versículo:
  //    probamos con fragmentos iniciales cada vez más cortos.
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

  // 3) Último recurso: la primera palabra significativa.
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
