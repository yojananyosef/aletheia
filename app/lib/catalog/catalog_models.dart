/// Modelos del catálogo (M2): recursos, facets y resultados de búsqueda.
///
/// Los produce el cliente del servicio `catalog/` y también el índice de
/// recursos incluidos en la app (modo local). JSON manual con `dart:convert`,
/// siguiendo el contrato en `docs/spec/03-contrato-catalogo.md`.
library;

/// Etiqueta del idioma para la UI (`lang`: idioma de la interfaz).
String languageLabel(String language, {String lang = 'es'}) =>
    switch (language) {
      'es' => lang == 'en' ? 'Spanish' : 'Español',
      'en' => lang == 'en' ? 'English' : 'Inglés',
      'el' => lang == 'en' ? 'Greek' : 'Griego',
      'he' => lang == 'en' ? 'Hebrew' : 'Hebreo',
      'la' => lang == 'en' ? 'Latin' : 'Latín',
      'mul' => lang == 'en' ? 'Hebrew and Greek' : 'Hebreo y griego',
      _ => language,
    };

/// Etiqueta legible de una licencia cuando el manifiesto no trae texto.
String licenseLabel(String kind, {String lang = 'es'}) => switch (kind) {
  'public-domain' => lang == 'en' ? 'Public domain' : 'Dominio público',
  'cc0' => 'CC0',
  'cc-by' => 'CC BY 4.0',
  'cc-by-sa' => 'CC BY-SA 4.0',
  'proprietary' => lang == 'en' ? 'Proprietary' : 'Licencia propietaria',
  _ => lang == 'en' ? 'Unknown license' : 'Licencia desconocida',
};

/// Etiqueta del tipo de recurso para la UI (`lang`: idioma de la interfaz).
String resourceTypeLabel(String type, {String lang = 'es'}) => switch (type) {
  'bible' => lang == 'en' ? 'Bible' : 'Biblia',
  'commentary' => lang == 'en' ? 'Commentary' : 'Comentario',
  'dictionary' => lang == 'en' ? 'Dictionary' : 'Diccionario',
  'encyclopedia' => lang == 'en' ? 'Encyclopedia' : 'Enciclopedia',
  'factbook' => lang == 'en' ? 'Articles' : 'Artículos',
  'devotional' => lang == 'en' ? 'Devotional' : 'Devocional',
  'dataset' => lang == 'en' ? 'Dataset' : 'Datos',
  'guide' => lang == 'en' ? 'Guide' : 'Guía',
  'workflow' => lang == 'en' ? 'Workflow' : 'Flujo de trabajo',
  'document' => lang == 'en' ? 'Document' : 'Documento',
  _ => type,
};

/// Cuenta con separador de millares fino (31102 → 31 102).
String formatCount(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write('\u202f');
    buffer.write(text[i]);
  }
  return buffer.toString();
}

// ---------------------------------------------------------------- recursos

class ResourceSummary {
  const ResourceSummary({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.abbrev,
    this.authors = const [],
    this.language = '',
    this.publisher,
    this.edition,
    this.description,
    this.licenseKind = 'unknown',
    this.licenseText = '',
    this.tags = const [],
    this.verses = 0,
    this.sections = 0,
    this.locked = false,
  });

  final String id;
  final String type;
  final String title;
  final String? subtitle;
  final String? abbrev;
  final List<String> authors;
  final String language;
  final String? publisher;
  final String? edition;
  final String? description;
  final String licenseKind;
  final String licenseText;
  final List<String> tags;
  final int verses;
  final int sections;
  final bool locked;

  bool get isPublicDomain => licenseKind == 'public-domain';

  bool get isBible => type == 'bible';

  String get authorsLabel => authors.join('; ');

  /// Etiqueta del tipo para la UI (español por defecto).
  String get typeLabel => resourceTypeLabel(type);

  /// Etiqueta del tipo en el idioma de la interfaz.
  String typeLabelIn(String lang) => resourceTypeLabel(type, lang: lang);

  static ResourceSummary fromJson(Map<String, dynamic> json) {
    final license = json['license'];
    final stats = json['stats'];
    return ResourceSummary(
      id: (json['id'] ?? json['resourceId'] ?? '') as String,
      type: json['type'] as String? ?? 'document',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      abbrev: json['abbrev'] as String?,
      authors: ((json['authors'] as List?) ?? const []).cast<String>(),
      language: json['language'] as String? ?? '',
      publisher: json['publisher'] as String?,
      edition: json['edition'] as String?,
      description: json['description'] as String?,
      licenseKind: license is Map
          ? (license['kind'] as String? ?? 'unknown')
          : 'unknown',
      licenseText: _licenseText(license),
      tags: ((json['tags'] as List?) ?? const []).cast<String>(),
      verses: stats is Map ? (stats['verses'] as int? ?? 0) : 0,
      sections: stats is Map ? (stats['sections'] as int? ?? 0) : 0,
      locked: json['locked'] as bool? ?? false,
    );
  }

  /// Acepta `license` como texto o como mapa (`{kind, text}`), incluso si el
  /// manifiesto viene de una sincronización antigua con `text` anidado.
  static String _licenseText(Object? license) {
    var value = license;
    while (value is Map) {
      value = value['text'];
    }
    return value is String ? value : '';
  }
}

class ResourceListing {
  const ResourceListing({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
    this.facets = const {},
  });

  static const empty = ResourceListing(
    total: 0,
    page: 1,
    pageSize: 50,
    items: [],
  );

  final int total;
  final int page;
  final int pageSize;
  final List<ResourceSummary> items;

  /// `{'type': {'bible': 2}, 'language': {'es': 1}, 'author': {...}}`
  final Map<String, Map<String, int>> facets;

  bool get hasMore => page * pageSize < total;

  static ResourceListing fromJson(Map<String, dynamic> json) => ResourceListing(
    total: json['total'] as int? ?? 0,
    page: json['page'] as int? ?? 1,
    pageSize: json['pageSize'] as int? ?? 50,
    items: ((json['items'] as List?) ?? const [])
        .map((e) => ResourceSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
    facets: {
      for (final entry in ((json['facets'] as Map?) ?? const {}).entries)
        entry.key as String: {
          for (final facet in (entry.value as Map).entries)
            facet.key as String: (facet.value as num).toInt(),
        },
    },
  );
}

// --------------------------------------------------------------- búsqueda

class SearchHit {
  const SearchHit({
    required this.resourceId,
    required this.resourceTitle,
    required this.sectionId,
    required this.book,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.ref,
    required this.citation,
    required this.snippet,
    this.abbrev,
    this.resourceType = 'bible',
    this.locked = false,
  });

  final String resourceId;
  final String resourceTitle;

  /// `bible`, `factbook`, `devotional`, etc.; decide a qué panel saltar.
  final String resourceType;
  final String? abbrev;
  final String sectionId;
  final String book;
  final String bookName;
  final int chapter;
  final int verse;

  /// Referencia canónica interna (`JHN.1.1`).
  final String ref;

  /// Cita legible en el idioma del recurso (`Juan 1:1`).
  final String citation;

  /// Fragmento con las coincidencias entre `<em>…</em>`.
  final String snippet;

  final bool locked;

  static SearchHit fromJson(Map<String, dynamic> json) => SearchHit(
    resourceId: json['resourceId'] as String? ?? '',
    resourceTitle: json['resourceTitle'] as String? ?? '',
    resourceType: json['resourceType'] as String? ?? 'bible',
    abbrev: json['abbrev'] as String?,
    sectionId: json['sectionId'] as String? ?? '',
    book: json['book'] as String? ?? '',
    bookName: json['bookName'] as String? ?? '',
    chapter: json['chapter'] as int? ?? 0,
    verse: json['verse'] as int? ?? 0,
    ref: json['ref'] as String? ?? '',
    citation: json['citation'] as String? ?? '',
    snippet: json['snippet'] as String? ?? '',
    locked: json['locked'] as bool? ?? false,
  );
}

class SearchResult {
  const SearchResult({
    required this.query,
    required this.scope,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hits,
    this.facets = const {},
  });

  final String query;
  final String scope;
  final int total;
  final int page;
  final int pageSize;
  final List<SearchHit> hits;

  /// `{'type': {'bible': 2}, 'language': {'es': 3}, 'book': {'JHN': 12}}`.
  final Map<String, Map<String, int>> facets;

  bool get hasMore => page * pageSize < total;

  static SearchResult fromJson(Map<String, dynamic> json) => SearchResult(
    query: json['query'] as String? ?? '',
    scope: json['scope'] as String? ?? 'all',
    total: json['total'] as int? ?? 0,
    page: json['page'] as int? ?? 1,
    pageSize: json['pageSize'] as int? ?? 20,
    hits: ((json['hits'] as List?) ?? const [])
        .map((e) => SearchHit.fromJson(e as Map<String, dynamic>))
        .toList(),
    facets: _facetsFromJson(json['facets']),
  );

  static Map<String, Map<String, int>> _facetsFromJson(Object? raw) => {
    for (final entry in ((raw as Map?) ?? const {}).entries)
      entry.key as String: {
        for (final facet in (entry.value as Map).entries)
          facet.key as String: (facet.value as num).toInt(),
      },
  };
}

/// Referencia cruzada de una fuente externa (TSK).
///
/// Solo se guarda la referencia canónica; la etiqueta legible se calcula con
/// el idioma activo de la UI.
class CrossReference {
  const CrossReference({required this.reference, this.source = 'tsk'});

  final String reference;
  final String source;

  static CrossReference fromJson(Map<String, dynamic> json) => CrossReference(
    reference: json['ref'] as String? ?? '',
    source: json['source'] as String? ?? 'tsk',
  );
}

/// Ámbitos de búsqueda de la UI (todo, Biblia, libros y Temas).
class SearchScope {
  const SearchScope(this.id, this.label, {this.enabled = true, this.note});

  final String id;
  final String label;
  final bool enabled;
  final String? note;

  static const all = SearchScope('all', 'Todo');
  static const bible = SearchScope('bible', 'Biblia');
  static const books = SearchScope('books', 'Libros');
  static const values = [
    all,
    bible,
    books,
    SearchScope('factbook', 'Temas'),
    SearchScope('morph', 'Morfología', enabled: false, note: 'M6'),
    SearchScope('media', 'Multimedia', enabled: false, note: 'M5'),
    SearchScope('maps', 'Mapas', enabled: false, note: 'M5'),
  ];

  /// Etiqueta en el idioma de la interfaz.
  String labelIn(String lang) {
    if (lang == 'es') return label;
    return switch (id) {
      'all' => 'All',
      'bible' => 'Bible',
      'books' => 'Books',
      'factbook' => 'Topics',
      'morph' => 'Morphology',
      'media' => 'Media',
      'maps' => 'Maps',
      _ => label,
    };
  }
}
