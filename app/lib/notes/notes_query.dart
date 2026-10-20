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
      kinds.length + notebooks.length + tags.length + (resourceId != null ? 1 : 0);

  NotesQuery copyWith({
    String? text,
    bool? trash,
    Set<String>? kinds,
    Set<String>? notebooks,
    Set<String>? tags,
    String? resourceId,
    bool clearResource = false,
    NotesSort? sort,
  }) =>
      NotesQuery(
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

/// Notas ancladas a un versículo concreto (`versículo ─▶ notas`), sin
/// resaltados (que se pintan en el texto) ni notas en la papelera.
Map<int, List<Note>> notesByVerse(
  Iterable<Note> notes, {
  required String bookCode,
  required int chapter,
  bool includeHighlights = false,
}) {
  final map = <int, List<Note>>{};
  for (final note in notes) {
    if (note.isTrashed) continue;
    if (!includeHighlights && note.isHighlight) continue;
    for (final anchor in note.anchors) {
      if (anchor.bookCode != bookCode ||
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
Map<int, List<VerseHighlight>> highlightsByVerse(
  Iterable<Note> notes, {
  required String bookCode,
  required int chapter,
}) {
  final map = <int, List<VerseHighlight>>{};
  for (final note in notes) {
    if (note.isTrashed || !note.isHighlight) continue;
    for (final anchor in note.anchors) {
      if (anchor.bookCode != bookCode ||
          anchor.chapter != chapter ||
          anchor.verse == null ||
          !anchor.hasRange) {
        continue;
      }
      map.putIfAbsent(anchor.verse!, () => []).add(
            VerseHighlight(
              noteId: note.id,
              start: anchor.startOffset!,
              end: anchor.endOffset!,
              color: note.color,
              style: note.style,
            ),
          );
      break;
    }
  }
  for (final ranges in map.values) {
    ranges.sort((a, b) => a.start.compareTo(b.start));
  }
  return map;
}
