/// Modelo de **Notas** (M4): notas y resaltados *local-first*.
///
/// Una nota puede llevar varios anclajes (`NoteAnchor`): recurso + referencia
/// y, si vienen de una selección, versículo y rango de caracteres dentro del
/// texto plano del versículo (para pintar resaltados y reabrir el pasaje).
/// `kind` distingue las notas (`note`) de los resaltados (`highlight`), que
/// solo se diferencian por el estilo.
library;

import 'dart:ui' show Color;

/// Paleta de resaltado del clon (colores propios, no del original).
/// Paleta de resaltados — los cinco colores del original (ver
/// la evidencia de reconocimiento §2). `pink` se conserva
/// para leer datos ya guardados por versiones anteriores del clon.
const Map<String, Color> kHighlightPalette = {
  'yellow': Color(0xFFFFF0A8),
  'green': Color(0xFFC7E9C0),
  'blue': Color(0xFFC6E0FF),
  'red': Color(0xFFF8C4C0),
  'orange': Color(0xFFFFDCC0),
  'pink': Color(0xFFF7CEDC),
};

const List<String> kHighlightColorIds = [
  'yellow',
  'green',
  'blue',
  'red',
  'orange',
  'pink',
];

/// Colores que ofrece el menú de selección y el selector del editor (los del
/// original; `pink` solo se lee).
const List<String> kHighlightPickColorIds = [
  'yellow',
  'green',
  'blue',
  'red',
  'orange',
];

const String kDefaultHighlightColor = 'yellow';

/// Estilos de resaltado: fondo (`highlight`) o subrayado (`underline`).
const String kHighlightStyleHighlight = 'highlight';
const String kHighlightStyleUnderline = 'underline';
const List<String> kHighlightStyleIds = [
  kHighlightStyleHighlight,
  kHighlightStyleUnderline,
];

/// Color del «Subrayado rojo» del menú del original.
const String kDefaultUnderlineColor = 'red';

Color highlightColor(String id) =>
    kHighlightPalette[id] ?? kHighlightPalette[kDefaultHighlightColor]!;

/// Anclaje de una nota (recurso + referencia; rango opcional).
class NoteAnchor {
  const NoteAnchor({
    required this.resourceId,
    this.reference,
    this.bookCode,
    this.chapter,
    this.verse,
    this.verseEnd,
    this.startOffset,
    this.endOffset,
    this.quote,
  });

  factory NoteAnchor.fromJson(Map<String, dynamic> json) => NoteAnchor(
        resourceId: json['resourceId'] as String? ?? '',
        reference: json['reference'] as String?,
        bookCode: json['bookCode'] as String?,
        chapter: json['chapter'] as int?,
        verse: json['verse'] as int?,
        verseEnd: json['verseEnd'] as int?,
        startOffset: json['startOffset'] as int?,
        endOffset: json['endOffset'] as int?,
        quote: json['quote'] as String?,
      );

  final String resourceId;

  /// Referencia canónica (`JHN.1.8`).
  final String? reference;
  final String? bookCode;
  final int? chapter;
  final int? verse;
  final int? verseEnd;

  /// Rango dentro del texto plano del versículo (si viene de una selección).
  final int? startOffset;
  final int? endOffset;
  final String? quote;

  bool get hasRange =>
      startOffset != null && endOffset != null && endOffset! > startOffset!;

  bool get hasVerse => bookCode != null && chapter != null && verse != null;

  NoteAnchor copyWith({String? resourceId, String? reference}) => NoteAnchor(
        resourceId: resourceId ?? this.resourceId,
        reference: reference ?? this.reference,
        bookCode: bookCode,
        chapter: chapter,
        verse: verse,
        verseEnd: verseEnd,
        startOffset: startOffset,
        endOffset: endOffset,
        quote: quote,
      );

  Map<String, dynamic> toJson() => {
        'resourceId': resourceId,
        if (reference != null) 'reference': reference,
        if (bookCode != null) 'bookCode': bookCode,
        if (chapter != null) 'chapter': chapter,
        if (verse != null) 'verse': verse,
        if (verseEnd != null) 'verseEnd': verseEnd,
        if (startOffset != null) 'startOffset': startOffset,
        if (endOffset != null) 'endOffset': endOffset,
        if (quote != null) 'quote': quote,
      };
}

/// Nota o resaltado del usuario.
class Note {
  const Note({
    required this.id,
    this.kind = 'note',
    this.title = '',
    this.body = '',
    this.anchors = const [],
    this.notebooks = const [],
    this.tags = const [],
    this.color = kDefaultHighlightColor,
    this.style = kHighlightStyleHighlight,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String? ?? '',
        kind: json['kind'] as String? ?? 'note',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        anchors: ((json['anchors'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(NoteAnchor.fromJson)
            .toList(),
        notebooks:
            ((json['notebooks'] as List?) ?? const []).whereType<String>().toList(),
        tags: ((json['tags'] as List?) ?? const []).whereType<String>().toList(),
        color: json['color'] as String? ?? kDefaultHighlightColor,
        style: json['style'] as String? ?? kHighlightStyleHighlight,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
      );

  final String id;

  /// `note` | `highlight`.
  final String kind;
  final String title;
  final String body;
  final List<NoteAnchor> anchors;

  /// Identificadores de cuaderno.
  final List<String> notebooks;
  final List<String> tags;

  /// Color del resaltado (`kHighlightColorIds`).
  final String color;

  /// Estilo del resaltado (`kHighlightStyleIds`).
  final String style;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isHighlight => kind == 'highlight';
  bool get isNote => !isHighlight;
  bool get isTrashed => deletedAt != null;
  bool get isUnderline => style == kHighlightStyleUnderline;

  NoteAnchor? get mainAnchor => anchors.isEmpty ? null : anchors.first;

  String? get quote {
    for (final anchor in anchors) {
      final text = anchor.quote;
      if (text != null && text.trim().isNotEmpty) return text.trim();
    }
    return null;
  }

  String get firstTag => tags.isEmpty ? '' : tags.first;

  /// Texto para la cabecera de la tarjeta (título, cita o primera línea).
  String get headline {
    if (title.trim().isNotEmpty) return title.trim();
    final quoted = quote;
    if (quoted != null) return quoted;
    final line = body.trim().split('\n').first.trim();
    return line.isEmpty ? '' : line;
  }

  /// Cuerpo sin la cabecera (para la previsualización de la tarjeta).
  String get preview {
    final text = body.trim();
    if (text.isEmpty) return '';
    if (title.trim().isNotEmpty) return text.split('\n').first.trim();
    // La cita ya hace de cabecera: el cuerpo entero es la previsualización.
    if (quote != null) return text.replaceAll('\n', ' ').trim();
    final lines = text.split('\n');
    return lines.length == 1 ? '' : lines.skip(1).join(' ').trim();
  }

  Note copyWith({
    String? kind,
    String? title,
    String? body,
    List<NoteAnchor>? anchors,
    List<String>? notebooks,
    List<String>? tags,
    String? color,
    String? style,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) =>
      Note(
        id: id,
        kind: kind ?? this.kind,
        title: title ?? this.title,
        body: body ?? this.body,
        anchors: anchors ?? this.anchors,
        notebooks: notebooks ?? this.notebooks,
        tags: tags ?? this.tags,
        color: color ?? this.color,
        style: style ?? this.style,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'title': title,
        'body': body,
        'anchors': [for (final anchor in anchors) anchor.toJson()],
        'notebooks': notebooks,
        'tags': tags,
        'color': color,
        'style': style,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      };
}

/// Cuaderno (agrupación de notas del usuario).
class Notebook {
  const Notebook({required this.id, required this.name, required this.createdAt});

  factory Notebook.fromJson(Map<String, dynamic> json) => Notebook(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  final String id;
  final String name;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Estado completo de Notas (lo que se persiste).
class NotesState {
  const NotesState({this.notes = const [], this.notebooks = const []});

  factory NotesState.fromJson(Map<String, dynamic> json) => NotesState(
        notes: ((json['notes'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Note.fromJson)
            .toList(),
        notebooks: ((json['notebooks'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Notebook.fromJson)
            .toList(),
      );

  final List<Note> notes;
  final List<Notebook> notebooks;

  int get activeCount => notes.where((note) => !note.isTrashed).length;
  int get trashCount => notes.where((note) => note.isTrashed).length;

  Map<String, dynamic> toJson() => {
        'notes': [for (final note in notes) note.toJson()],
        'notebooks': [for (final notebook in notebooks) notebook.toJson()],
      };
}
