/// Modelos del documento del catálogo (M1).
///
/// Formato (ver `docs/spec/03-contrato-catalogo.md`):
/// - `manifest.json`: metadatos del recurso + índice de libros/capítulos.
/// - `books/<CODE>.json`: bloques por capítulo de un libro.
///
/// Bloques: `heading`, `chapterNumber`, `verseGroup`, `rule`.
/// Inlines: `text` (con estilo opcional), `span` (itálicas), `footnote`,
/// `xref` y `line`.
library;

// --------------------------------------------------------------- manifest

class DocumentManifest {
  const DocumentManifest({
    required this.resourceId,
    required this.title,
    required this.abbrev,
    required this.language,
    required this.source,
    required this.license,
    required this.books,
    this.rtl = false,
  });

  final String resourceId;
  final String title;
  final String abbrev;
  final String language;
  final String source;
  final String license;
  final List<ManifestBook> books;

  /// El texto se compone de derecha a izquierda (hebreo).
  final bool rtl;

  /// Acepta tanto el manifiesto de los assets (`resourceId`, `license` texto)
  /// como el del servicio de catálogo (`id`, `license: {kind, text}`).
  static DocumentManifest fromJson(Map<String, dynamic> json) {
    final license = json['license'];
    final attributes = (json['attributes'] as Map?) ?? const {};
    return DocumentManifest(
        resourceId: (json['resourceId'] ?? json['id'] ?? '') as String,
        title: json['title'] as String? ?? '',
        abbrev: json['abbrev'] as String? ?? '',
        language: json['language'] as String? ?? '',
        source: json['source'] as String? ?? '',
        license: license is Map
            ? (license['text'] as String? ?? '')
            : (license as String? ?? ''),
        books: ((json['books'] as List?) ?? const [])
            .map((e) => ManifestBook.fromJson(e as Map<String, dynamic>))
            .toList(),
        rtl: attributes['rtl'] == true || json['language'] == 'he',
    );
  }

  int indexOfBook(String code) => books.indexWhere((b) => b.code == code);

  ManifestBook? bookByCode(String code) {
    final i = indexOfBook(code);
    return i >= 0 ? books[i] : null;
  }

  /// Ubicación del capítulo siguiente (mismo libro o siguiente libro).
  ({String book, int chapter})? nextLocation(String bookCode, int chapter) {
    final i = indexOfBook(bookCode);
    if (i < 0) return null;
    final book = books[i];
    if (chapter < book.chapters.length) {
      return (book: book.code, chapter: chapter + 1);
    }
    if (i + 1 < books.length) return (book: books[i + 1].code, chapter: 1);
    return null;
  }

  /// Ubicación del capítulo anterior (libro anterior si hace falta).
  ({String book, int chapter})? previousLocation(String bookCode, int chapter) {
    final i = indexOfBook(bookCode);
    if (i < 0) return null;
    if (chapter > 1) return (book: bookCode, chapter: chapter - 1);
    if (i > 0) {
      final prev = books[i - 1];
      return (book: prev.code, chapter: prev.chapters.length);
    }
    return null;
  }
}

class ManifestBook {
  const ManifestBook({required this.code, required this.name, required this.chapters});

  final String code;
  final String name;
  final List<ManifestChapter> chapters;

  static ManifestBook fromJson(Map<String, dynamic> json) => ManifestBook(
        code: json['code'] as String,
        name: json['name'] as String? ?? '',
        chapters: ((json['chapters'] as List?) ?? const [])
            .map((e) => ManifestChapter.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ManifestChapter {
  const ManifestChapter({required this.n, required this.verses});

  final int n;
  final int verses;

  static ManifestChapter fromJson(Map<String, dynamic> json) =>
      ManifestChapter(n: json['n'] as int? ?? 0, verses: json['verses'] as int? ?? 0);
}

// ------------------------------------------------------- secciones M5

/// Metadatos de una sección del catálogo (capítulo de la Biblia o entrada de
/// un recurso pequeño: devocional fechado o artículo del Factbook).
class SectionSummary {
  const SectionSummary({
    required this.id,
    required this.title,
    this.day,
    this.theme,
    this.summary,
    this.reference,
    this.referenceLabel,
    this.tags = const [],
    this.related = const [],
    this.references = const [],
  });

  final String id;
  final String title;

  /// `MM.DD` en el devocional.
  final String? day;
  final String? theme;
  final String? summary;

  /// Referencia canónica principal y su etiqueta legible.
  final String? reference;
  final String? referenceLabel;

  final List<String> tags;

  /// Ids de otras secciones del mismo recurso (Factbook).
  final List<String> related;

  /// Referencias bíblicas canónicas citadas (Factbook).
  final List<String> references;

  static SectionSummary fromJson(Map<String, dynamic> json) => SectionSummary(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        day: json['day'] as String?,
        theme: json['theme'] as String?,
        summary: json['summary'] as String?,
        reference: json['reference'] as String?,
        referenceLabel: json['referenceLabel'] as String?,
        tags: ((json['tags'] as List?) ?? const []).cast<String>(),
        related: ((json['related'] as List?) ?? const []).cast<String>(),
        references: ((json['references'] as List?) ?? const []).cast<String>(),
      );
}

/// Sección completa: metadatos + bloques (mismo formato que el lector).
class CatalogSection {
  const CatalogSection({required this.summary, required this.blocks});

  final SectionSummary summary;
  final List<BookBlock> blocks;

  static CatalogSection fromJson(Map<String, dynamic> json) => CatalogSection(
        summary: SectionSummary.fromJson(json),
        blocks: ((json['blocks'] as List?) ?? const [])
            .map((e) => BookBlock.tryFromJson(e as Map<String, dynamic>))
            .whereType<BookBlock>()
            .toList(),
      );
}

// ------------------------------------------------------------- documento

class BookDocument {
  const BookDocument({required this.code, required this.name, required this.chapters});

  final String code;
  final String name;
  final List<ChapterDocument> chapters;

  static BookDocument fromJson(Map<String, dynamic> json) => BookDocument(
        code: json['code'] as String,
        name: json['name'] as String? ?? '',
        chapters: ((json['chapters'] as List?) ?? const [])
            .map((e) => ChapterDocument.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  ChapterDocument? chapter(int n) {
    for (final c in chapters) {
      if (c.n == n) return c;
    }
    return null;
  }
}

class ChapterDocument {
  const ChapterDocument({required this.n, required this.blocks, this.footnotes = const {}});

  final int n;
  final List<BookBlock> blocks;
  final Map<String, ChapterFootnote> footnotes;

  static ChapterDocument fromJson(Map<String, dynamic> json) => ChapterDocument(
        n: json['n'] as int? ?? 0,
        blocks: ((json['blocks'] as List?) ?? const [])
            .map((e) => BookBlock.tryFromJson(e as Map<String, dynamic>))
            .whereType<BookBlock>()
            .toList(),
        footnotes: {
          for (final e in ((json['footnotes'] as Map?) ?? const {}).entries)
            e.key as String: ChapterFootnote.fromJson(e.value as Map<String, dynamic>),
        },
      );
}

class ChapterFootnote {
  const ChapterFootnote({required this.label, required this.text});

  final String label;
  final String text;

  static ChapterFootnote fromJson(Map<String, dynamic> json) => ChapterFootnote(
        label: json['label'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );
}

// ---------------------------------------------------------------- bloques

sealed class BookBlock {
  const BookBlock();

  static BookBlock? tryFromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'heading':
        return HeadingBlock(
          text: json['text'] as String? ?? '',
          style: json['style'] as String? ?? 'section',
        );
      case 'chapterNumber':
        return ChapterNumberBlock(json['value'] as int? ?? 0);
      case 'verseGroup':
        return VerseGroupBlock(
          style: json['style'] as String? ?? 'paragraph',
          indent: json['indent'] as int? ?? 0,
          verses: ((json['verses'] as List?) ?? const [])
              .map((e) => Verse.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      case 'paragraph':
        return VerseGroupBlock(
          style: 'paragraph',
          verses: [
            Verse(
              n: 0,
              inlines: ((json['inlines'] as List?) ?? const [])
                  .map((e) => DocInline.tryFromJson(e as Map<String, dynamic>))
                  .whereType<DocInline>()
                  .toList(),
            ),
          ],
        );
      case 'rule':
        return const RuleBlock();
      case 'map':
        return MapBlock.fromJson(json);
      default:
        return null;
    }
  }
}

class HeadingBlock extends BookBlock {
  const HeadingBlock({required this.text, this.style = 'section'});

  final String text;

  /// `section` (centrado, negrita) o `psalmTitle` (cursiva).
  final String style;
}

class ChapterNumberBlock extends BookBlock {
  const ChapterNumberBlock(this.value);

  final int value;
}

final class VerseGroupBlock extends BookBlock {
  const VerseGroupBlock({
    required this.verses,
    this.style = 'paragraph',
    this.indent = 0,
  });

  final List<Verse> verses;

  /// `paragraph` (flujo continuo), `poetry` o `list`.
  final String style;

  /// Nivel de sangría (poesía/listas).
  final int indent;
}

class RuleBlock extends BookBlock {
  const RuleBlock();
}

/// Mapa esquemático con marcadores de lugares bíblicos.
///
/// La geometría (costas y lagos) se dibuja con Natural Earth; las
/// coordenadas de los lugares proceden de OpenBible.info (CC BY 4.0). El
/// bloque solo guarda el encuadre y los marcadores, no las teselas.
class MapBlock extends BookBlock {
  const MapBlock({
    required this.title,
    required this.centerLat,
    required this.centerLon,
    required this.latSpan,
    required this.lonSpan,
    this.caption,
    this.markers = const [],
    this.routes = const [],
  });

  final String title;
  final String? caption;
  final double centerLat;
  final double centerLon;
  final double latSpan;
  final double lonSpan;
  final List<MapMarker> markers;

  /// Rutas trazadas sobre el mapa (viajes, itinerarios).
  ///
  /// Cada ruta es una secuencia ordenada de paradas; el pintor dibuja la
  /// polilínea con flechas de dirección y numera las paradas.
  final List<MapRoute> routes;

  static MapBlock fromJson(Map<String, dynamic> json) {
    double number(Object? value, double fallback) =>
        value is num ? value.toDouble() : fallback;

    final center = (json['center'] as List?) ?? const [];
    final markers = ((json['markers'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MapMarker.fromJson)
        .toList();
    final routes = ((json['routes'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MapRoute.fromJson)
        .toList();
    return MapBlock(
      title: json['title'] as String? ?? '',
      caption: json['caption'] as String?,
      centerLat: center.isNotEmpty ? number(center[0], 31.8) : 31.8,
      centerLon: center.length > 1 ? number(center[1], 35.2) : 35.2,
      latSpan: number(json['latSpan'], 4),
      lonSpan: number(json['lonSpan'], 4),
      markers: markers,
      routes: routes,
    );
  }
}

class MapMarker {
  const MapMarker({
    required this.name,
    required this.lat,
    required this.lon,
    this.ref,
  });

  final String name;
  final double lat;
  final double lon;

  /// Referencia canónica opcional que se abre al pulsar el marcador.
  final String? ref;

  static MapMarker fromJson(Map<String, dynamic> json) => MapMarker(
        name: json['name'] as String? ?? '',
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lon: (json['lon'] as num?)?.toDouble() ?? 0,
        ref: json['ref'] as String?,
      );
}

/// Un itinerario trazado sobre el mapa: etiqueta y paradas ordenadas.
///
/// Las paradas reutilizan [MapMarker]; la polilínea pasa por sus coordenadas
/// en orden y el pintor añade flechas de dirección y numeración de paradas.
class MapRoute {
  const MapRoute({required this.label, required this.stops});

  final String label;
  final List<MapMarker> stops;

  static MapRoute fromJson(Map<String, dynamic> json) => MapRoute(
        label: json['label'] as String? ?? '',
        stops: ((json['stops'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MapMarker.fromJson)
            .toList(),
      );
}

class Verse {
  const Verse({required this.n, required this.inlines});

  final int n;
  final List<DocInline> inlines;

  static Verse fromJson(Map<String, dynamic> json) => Verse(
        n: json['n'] as int? ?? 0,
        inlines: ((json['inlines'] as List?) ?? const [])
            .map((e) => DocInline.tryFromJson(e as Map<String, dynamic>))
            .whereType<DocInline>()
            .toList(),
      );
}

// ---------------------------------------------------------------- inlines

sealed class DocInline {
  const DocInline();

  static DocInline? tryFromJson(Map<String, dynamic> json) {
    switch (json['t']) {
      case 'text':
        return TextInline.fromJson(json, defaultStyle: json['style'] as String?);
      case 'span':
        return TextInline.fromJson(
          json,
          defaultStyle: json['style'] as String? ?? 'italic',
        );
      case 'footnote':
        return FootnoteRef(json['id'] as String? ?? '', label: json['label'] as String?);
      case 'xref':
        return XrefLink(
          label: json['label'] as String? ?? '',
          ref: json['ref'] as String?,
        );
      case 'line':
        return const LineInline();
      default:
        return null;
    }
  }
}

class TextInline extends DocInline {
  const TextInline(
    this.text, {
    this.style,
    this.strong,
    this.strongFull,
    this.morph,
    this.lemma,
    this.translit,
    this.gloss,
    this.glossEs,
  });

  final String text;

  /// `italic`, `red` o `null`.
  final String? style;

  /// Strong base normalizado (`H0430`, `G2316`), sin sufijo de matiz.
  final String? strong;

  /// Strong tal como aparece en la fuente (`H0430G`, `G0976`).
  final String? strongFull;

  /// Morfología de la instancia (`HNcmpa`, `N-NSF`, ...).
  final String? morph;

  /// Lema de diccionario cuando la fuente lo ofrece (griego).
  final String? lemma;

  /// Transliteración de la forma.
  final String? translit;

  /// Glosa de la fuente (inglés en TAHOT/TAGNT).
  final String? gloss;

  /// Glosa española propia para las voces frecuentes.
  final String? glossEs;

  bool get isStudyWord =>
      (strong != null && strong!.isNotEmpty) ||
      (morph != null && morph!.isNotEmpty);

  String get cleanText => text.trim();

  String? get displayGloss {
    final es = glossEs?.trim();
    if (es != null && es.isNotEmpty) return es;
    final en = gloss?.trim();
    return (en != null && en.isNotEmpty) ? en : null;
  }

  static TextInline fromJson(
    Map<String, dynamic> json, {
    String? defaultStyle,
  }) {
    String? value(String key) {
      final raw = json[key];
      if (raw is! String) return null;
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return TextInline(
      json['v'] as String? ?? '',
      style: defaultStyle,
      strong: value('strong'),
      strongFull: value('strongFull'),
      morph: value('morph'),
      lemma: value('lemma'),
      translit: value('translit'),
      gloss: value('gloss'),
      glossEs: value('glossEs'),
    );
  }
}

class FootnoteRef extends DocInline {
  const FootnoteRef(this.id, {this.label});

  final String id;
  final String? label;
}

class XrefLink extends DocInline {
  const XrefLink({required this.label, this.ref});

  final String label;
  final String? ref;
}

class LineInline extends DocInline {
  const LineInline();
}
