/// Consultas de Notas (M4): filtros, orden y proyecciones para el lector.
///
/// Todo es puro y testeable; la UI solo pinta el resultado.
library;

import 'notes_models.dart';

/// Orden de la lista (el original muestra «by Date Modified»).
enum NotesSort { modified, created, notebook }

/// Filtros activos del panel de Notas.
class NotesQuery {
  const NotesQuery({
    this.text = '',
    this.trash = false,
    this.kinds = const {},
    this.notebooks = const {},
    this.tags = const {},
    this.resourceId,
    this.sort = NotesSort.modified,
  });

  /// Búsqueda libre (título, cuerpo, cita, referencia, etiquetas).
  final String text;

  /// `true` = papelera.
  final bool trash;

  /// Tipos incluidos (`note`, `highlight`); vacío = todos.
  final Set<String> kinds;

  /// Cuadernos incluidos (vacío = todos).
  final Set<String> notebooks;

  /// Etiquetas incluidas (vacío = todas).
  final Set<String> tags;

  /// Limita a notas ancladas a este recurso (p. ej. el panel del lector).
  final String? resourceId;

  final NotesSort sort;

  int get activeFilterCount =>
      kinds.length +
      notebooks.length +
      tags.length +
      (resourceId != null ? 1 : 0);

  NotesQuery copyWith({
    String? text,
    bool? trash,
    Set<String>? kinds,
    Set<String>? notebooks,
    Set<String>? tags,
    String? resourceId,
    bool clearResource = false,
    NotesSort? sort,
  }) => NotesQuery(
    text: text ?? this.text,
    trash: trash ?? this.trash,
    kinds: kinds ?? this.kinds,
    notebooks: notebooks ?? this.notebooks,
    tags: tags ?? this.tags,
    resourceId: clearResource ? null : (resourceId ?? this.resourceId),
    sort: sort ?? this.sort,
  );
}

bool _matchesText(Note note, String needle) {
  if (note.title.toLowerCase().contains(needle)) return true;
  if (note.body.toLowerCase().contains(needle)) return true;
  for (final anchor in note.anchors) {
    if ((anchor.quote ?? '').toLowerCase().contains(needle)) return true;
    if ((anchor.reference ?? '').toLowerCase().contains(needle)) return true;
    if (anchor.resourceId.toLowerCase().contains(needle)) return true;
  }
  return note.tags.any((tag) => tag.toLowerCase().contains(needle));
}

/// Aplica [query] a [notes] (filtro + orden).
List<Note> applyNotesQuery(
  Iterable<Note> notes,
  NotesQuery query, {
  Map<String, String> notebookNames = const {},
}) {
  final needle = query.text.trim().toLowerCase();
  final result = <Note>[];
  for (final note in notes) {
    if (note.isTrashed != query.trash) continue;
    if (query.kinds.isNotEmpty && !query.kinds.contains(note.kind)) continue;
    if (query.notebooks.isNotEmpty &&
        !note.notebooks.any(query.notebooks.contains)) {
      continue;
    }
    if (query.tags.isNotEmpty && !note.tags.any(query.tags.contains)) continue;
    if (query.resourceId != null &&
        !note.anchors.any((a) => a.resourceId == query.resourceId)) {
      continue;
    }
    if (needle.isNotEmpty && !_matchesText(note, needle)) continue;
    result.add(note);
  }

  int byModified(Note a, Note b) => b.updatedAt.compareTo(a.updatedAt);
  switch (query.sort) {
    case NotesSort.modified:
      result.sort(byModified);
    case NotesSort.created:
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case NotesSort.notebook:
      // Orden por cuaderno: las notas sin cuaderno quedan al final y, dentro
      // de cada cuaderno, las más recientes primero (el original sólo habilita
      // este orden cuando hay un cuaderno seleccionado).
      String nameOf(Note note) => note.notebooks.isEmpty
          ? ''
          : (notebookNames[note.notebooks.first] ?? '');
      result.sort((a, b) {
        final nameA = nameOf(a).toLowerCase();
        final nameB = nameOf(b).toLowerCase();
        if (nameA.isEmpty != nameB.isEmpty) return nameA.isEmpty ? 1 : -1;
        final byName = nameA.compareTo(nameB);
        return byName != 0 ? byName : byModified(a, b);
      });
  }
  return result;
}

/// Etiquetas presentes en [notes], ordenadas alfabéticamente.
List<String> allTags(Iterable<Note> notes) {
  final tags = <String>{};
  for (final note in notes) {
    tags.addAll(note.tags);
  }
  final list = tags.toList()..sort();
  return list;
}

/// Recursos con notas ancladas (para el filtro «Recurso»).
List<String> anchoredResourceIds(Iterable<Note> notes) {
  final ids = <String>{};
  for (final note in notes) {
    for (final anchor in note.anchors) {
      if (anchor.resourceId.isNotEmpty) ids.add(anchor.resourceId);
    }
  }
  final list = ids.toList()..sort();
  return list;
}

/// Un ancla pertenece al recurso del lector cuando coincide con él.
///
/// Las anclas antiguas sin recurso se tratan como comodín para no ocultar
/// notas que ya existían antes de que el anclaje guardara el recurso.
bool anchorMatchesResource(NoteAnchor anchor, String resourceId) =>
    anchor.resourceId.isEmpty || anchor.resourceId == resourceId;

/// Notas ancladas a un versículo concreto (`versículo ─▶ notas`), sin
/// resaltados (que se pintan en el texto) ni notas en la papelera.
Map<int, List<Note>> notesByVerse(
  Iterable<Note> notes, {
  required String resourceId,
  required String bookCode,
  required int chapter,
  bool includeHighlights = false,
}) {
  final map = <int, List<Note>>{};
  for (final note in notes) {
    if (note.isTrashed) continue;
    if (!includeHighlights && note.isHighlight) continue;
    for (final anchor in note.anchors) {
      if (!anchorMatchesResource(anchor, resourceId) ||
          anchor.bookCode != bookCode ||
          anchor.chapter != chapter ||
          anchor.verse == null) {
        continue;
      }
      map.putIfAbsent(anchor.verse!, () => []).add(note);
      break;
    }
  }
  return map;
}

/// Centinela de «hasta el fin del versículo» para resaltados que empiezan o
/// terminan en otro versículo (los resaltados multi-verso comparten ancla con
/// offsets por versículo; al pintar un verso intermedio no se conoce el largo
/// final, y este valor es siempre mayor que cualquier texto).
const int kHighlightOpenEnd = 1 << 30;

/// Rango de resaltado dentro de un versículo.
class VerseHighlight {
  const VerseHighlight({
    required this.noteId,
    required this.start,
    required this.end,
    required this.color,
    this.style = kHighlightStyleHighlight,
  });

  final String noteId;
  final int start;
  final int end;
  final String color;
  final String style;

  bool get isUnderline => style == kHighlightStyleUnderline;
}

/// Resaltados por versículo (`versículo ─▶ rangos`), listos para pintar.
///
/// Sólo se devuelven los del recurso del lector: los offsets pertenecen al
/// texto de esa versión y no son comparables entre recursos distintos.
///
/// Un resaltado que cruza versículos (ancla con `verseEnd`) produce un rango
/// en cada versículo cubierto: del offset inicial hasta el fin (`kHighlightOpenEnd`)
/// en el primero, `kHighlightOpenEnd` en los intermedios y hasta el offset final
/// en el último.
Map<int, List<VerseHighlight>> highlightsByVerse(
  Iterable<Note> notes, {
  required String resourceId,
  required String bookCode,
  required int chapter,
}) {
  final map = <int, List<VerseHighlight>>{};
  for (final note in notes) {
    if (note.isTrashed || !note.isHighlight) continue;
    for (final anchor in note.anchors) {
      if (!anchorMatchesResource(anchor, resourceId) ||
          anchor.bookCode != bookCode ||
          anchor.chapter != chapter ||
          anchor.verse == null ||
          !anchor.hasRange) {
        continue;
      }
      final first = anchor.verse!;
      final last = anchor.verseEnd ?? first;
      if (last > first) {
        map
            .putIfAbsent(first, () => [])
            .add(
              VerseHighlight(
                noteId: note.id,
                start: anchor.startOffset!,
                end: kHighlightOpenEnd,
                color: note.color,
                style: note.style,
              ),
            );
        for (var verse = first + 1; verse < last; verse++) {
          map
              .putIfAbsent(verse, () => [])
              .add(
                VerseHighlight(
                  noteId: note.id,
                  start: 0,
                  end: kHighlightOpenEnd,
                  color: note.color,
                  style: note.style,
                ),
              );
        }
        map
            .putIfAbsent(last, () => [])
            .add(
              VerseHighlight(
                noteId: note.id,
                start: 0,
                end: anchor.endOffset!,
                color: note.color,
                style: note.style,
              ),
            );
      } else {
        map
            .putIfAbsent(first, () => [])
            .add(
              VerseHighlight(
                noteId: note.id,
                start: anchor.startOffset!,
                end: anchor.endOffset!,
                color: note.color,
                style: note.style,
              ),
            );
      }
      break;
    }
  }
  for (final ranges in map.values) {
    ranges.sort((a, b) => a.start.compareTo(b.start));
  }
  return map;
}

/// Resaltados vigentes que se solapan con un rango de versículo (o tramo de
/// varios: [verseEnd] y [end] interpretan el último versículo).
///
/// Lo usan el lector (para marcar el color activo y ofrecer «Quitar») y el
/// panel (para actualizar el color existente en vez de crear otro encima).
List<Note> highlightsForRange(
  Iterable<Note> notes, {
  required String resourceId,
  required String bookCode,
  required int chapter,
  required int verse,
  required int start,
  required int end,
  int? verseEnd,
}) {
  final selLast = verseEnd ?? verse;
  final result = <Note>[];
  for (final note in notes) {
    if (!note.isHighlight || note.isTrashed) {
      continue;
    }
    for (final anchor in note.anchors) {
      if (!anchorMatchesResource(anchor, resourceId) ||
          anchor.bookCode != bookCode ||
          anchor.chapter != chapter ||
          anchor.verse == null ||
          !anchor.hasRange) {
        continue;
      }
      final first = anchor.verse!;
      final last = anchor.verseEnd ?? first;
      if (last < verse || first > selLast) continue;
      final sharedFirst = first > verse ? first : verse;
      final sharedLast = last < selLast ? last : selLast;
      if (sharedFirst != sharedLast) {
        // Comparten más de un versículo: inevitable que se solapen.
        result.add(note);
        break;
      }
      // Solape en un único versículo: compárense los tramos efectivos allí.
      final (aStart, aEnd) = _rangeInVerse(
        verse: sharedFirst,
        anchorFirst: first,
        anchorLast: last,
        start: anchor.startOffset,
        end: anchor.endOffset,
      );
      final (sStart, sEnd) = _rangeInVerse(
        verse: sharedFirst,
        anchorFirst: verse,
        anchorLast: selLast,
        start: start,
        end: end,
      );
      if (aStart < sEnd && aEnd > sStart) {
        result.add(note);
        break;
      }
    }
  }
  return result;
}

/// Tramo efectivo del ancla dentro de [verse] (con centinelas de abierto).
(int, int) _rangeInVerse({
  required int verse,
  required int anchorFirst,
  required int anchorLast,
  required int? start,
  required int? end,
}) {
  final open = kHighlightOpenEnd;
  final startIn = anchorFirst == verse ? (start ?? 0) : 0;
  final endIn = anchorLast == verse ? (end ?? open) : open;
  return (startIn, endIn);
}
