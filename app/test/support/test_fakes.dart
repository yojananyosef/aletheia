/// Dobles de prueba compartidos por los widget tests (catálogo y documentos).
///
/// Sin E/S: el gateway es una subclase de [CatalogGateway] en modo `local` y
/// el repositorio sirve dos Biblias sintéticas (RV1909 en español y KJV en
/// inglés) para poder verificar el cambio de recurso.
library;

import 'package:aletheia/catalog/catalog_client.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/catalog_models.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/catalog/sections_repository.dart';

const testResources = [
  ResourceSummary(
    id: 'bible.rv1909',
    type: 'bible',
    title: 'Reina-Valera 1909',
    abbrev: 'RV1909',
    authors: ['Reina, Casiodoro de', 'Valera, Cipriano de'],
    language: 'es',
    licenseKind: 'public-domain',
    licenseText: 'Dominio público',
    verses: 31102,
    sections: 1189,
    description: 'Traducción clásica al español.',
  ),
  ResourceSummary(
    id: 'commentary.test',
    type: 'commentary',
    title: 'Comentario de prueba',
    abbrev: 'CP',
    authors: ['Autor de prueba'],
    language: 'es',
    licenseKind: 'public-domain',
    licenseText: 'Dominio público',
    sections: 120,
  ),
];

/// Segunda Biblia (solo para pruebas que necesitan cambiar de versión).
const testKjv = ResourceSummary(
  id: 'bible.kjv',
  type: 'bible',
  title: 'King James Version',
  abbrev: 'KJV',
  authors: ['King James'],
  language: 'en',
  licenseKind: 'public-domain',
  licenseText: 'Public domain',
  verses: 31102,
  sections: 1189,
  description: 'Versión inglesa de 1611.',
);

const testFacets = {
  'type': {'bible': 1, 'commentary': 1},
  'language': {'es': 2},
  'author': {'Autor de prueba': 1, 'Reina, Casiodoro de': 1},
};

SearchHit testHit(
  String ref,
  String citation,
  String snippet, {
  String resourceId = 'bible.rv1909',
  String abbrev = 'RV1909',
  String bookName = 'Juan',
}) => SearchHit(
  resourceId: resourceId,
  resourceTitle: resourceId == 'bible.kjv'
      ? 'King James Version'
      : 'Reina-Valera 1909',
  abbrev: abbrev,
  sectionId: ref.split('.').take(2).join('.'),
  book: ref.split('.').first,
  bookName: bookName,
  chapter: int.parse(ref.split('.')[1]),
  verse: int.parse(ref.split('.')[2]),
  ref: ref,
  citation: citation,
  snippet: snippet,
);

/// Gateway falso: sirve el catálogo en memoria y registra las búsquedas.
class FakeCatalogGateway extends CatalogGateway {
  FakeCatalogGateway({
    this.searchResult,
    this.listError,
    this.searchError,
    List<ResourceSummary>? resources,
  }) : resources = resources ?? testResources,
       super(
         mode: 'local',
         client: CatalogClient(baseUrl: 'http://127.0.0.1:1'),
       );

  final List<ResourceSummary> resources;
  SearchResult? searchResult;
  CatalogException? listError;
  CatalogException? searchError;
  List<CrossReference> crossReferenceResult = const [];

  /// Consultas recibidas: `query|scope` o `query|scope|resource`.
  final List<String> searchCalls = [];

  @override
  Future<ResourceListing> listResources({
    String query = '',
    String? type,
    String? language,
    String? author,
    String sort = 'title',
    int page = 1,
    int pageSize = 50,
  }) async {
    final error = listError;
    if (error != null) throw error;
    final items = resources.where((r) {
      if (type != null && r.type != type) return false;
      if (language != null && r.language != language) return false;
      if (author != null && !r.authors.contains(author)) return false;
      if (query.trim().isNotEmpty &&
          !r.title.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
    return ResourceListing(
      total: items.length,
      page: page,
      pageSize: pageSize,
      items: items,
      facets: testFacets,
    );
  }

  @override
  Future<SearchResult> search({
    required String query,
    String scope = 'all',
    String? resource,
    String? type,
    String? language,
    String? book,
    int page = 1,
    int pageSize = 20,
  }) async {
    final filters = [
      if (type != null) 'type=$type',
      if (language != null) 'language=$language',
      if (book != null) 'book=$book',
    ].join(',');
    searchCalls.add(
      [
        resource == null ? '$query|$scope' : '$query|$scope|$resource',
        if (filters.isNotEmpty) filters,
      ].join('|'),
    );
    final error = searchError;
    if (error != null) throw error;
    final result = searchResult;
    if (result == null) {
      return SearchResult(
        query: query,
        scope: scope,
        total: 0,
        page: page,
        pageSize: pageSize,
        hits: const [],
      );
    }
    final hits = resource == null
        ? result.hits
        : result.hits.where((h) => h.resourceId == resource).toList();
    return SearchResult(
      query: query,
      scope: scope,
      total: resource == null ? result.total : hits.length,
      page: page,
      pageSize: pageSize,
      hits: page == 1 ? hits : const [],
    );
  }

  @override
  Future<List<CrossReference>> crossReferences(
    String reference, {
    int limit = 40,
  }) async => crossReferenceResult.take(limit).toList();
}

/// Documentos sintéticos (sin E/S) para el lector.
class FakeDocumentRepository implements DocumentRepository {
  static final Map<String, DocumentManifest> _manifests = {
    'bible.rv1909': DocumentManifest.fromJson({
      'resourceId': 'bible.rv1909',
      'title': 'Biblia de prueba',
      'abbrev': 'RV1909',
      'language': 'es',
      'source': 'test',
      'license': 'test',
      'books': [
        {
          'code': 'GEN',
          'name': 'Génesis',
          'chapters': [
            {'n': 1, 'verses': 1},
          ],
        },
        {
          'code': 'JHN',
          'name': 'Juan',
          'chapters': [
            {'n': 1, 'verses': 2},
            {'n': 2, 'verses': 1},
          ],
        },
      ],
    }),
    'bible.kjv': DocumentManifest.fromJson({
      'resourceId': 'bible.kjv',
      'title': 'King James Version',
      'abbrev': 'KJV',
      'language': 'en',
      'source': 'test',
      'license': 'test',
      'books': [
        {
          'code': 'GEN',
          'name': 'Genesis',
          'chapters': [
            {'n': 1, 'verses': 1},
          ],
        },
        {
          'code': 'JHN',
          'name': 'John',
          'chapters': [
            {'n': 1, 'verses': 2},
          ],
        },
      ],
    }),
    'bible.tahot': DocumentManifest.fromJson({
      'resourceId': 'bible.tahot',
      'title': 'Texto hebreo de prueba',
      'abbrev': 'TAHOT',
      'language': 'he',
      'source': 'test',
      'license': 'CC BY 4.0',
      'attributes': {'rtl': true},
      'books': [
        {
          'code': 'PSA',
          'name': 'Salmos',
          'chapters': [
            {'n': 3, 'verses': 2},
          ],
        },
      ],
    }),
    'bible.tagnt': DocumentManifest.fromJson({
      'resourceId': 'bible.tagnt',
      'title': 'Texto griego de prueba',
      'abbrev': 'TAGNT',
      'language': 'grc',
      'source': 'test',
      'license': 'CC BY 4.0',
      'books': [
        {
          'code': 'JHN',
          'name': 'Juan',
          'chapters': [
            {'n': 1, 'verses': 1},
          ],
        },
      ],
    }),
  };

  static final Map<String, BookDocument> _rv1909 = {
    'GEN': BookDocument.fromJson({
      'code': 'GEN',
      'name': 'Génesis',
      'chapters': [
        {
          'n': 1,
          'blocks': [
            {'type': 'chapterNumber', 'value': 1},
            {
              'type': 'verseGroup',
              'verses': [
                {
                  'n': 1,
                  'inlines': [
                    {'t': 'text', 'v': 'Texto de Génesis 1:1.'},
                  ],
                },
              ],
            },
          ],
        },
      ],
    }),
    'JHN': BookDocument.fromJson({
      'code': 'JHN',
      'name': 'Juan',
      'chapters': [
        {
          'n': 1,
          'blocks': [
            {'type': 'chapterNumber', 'value': 1},
            {
              'type': 'verseGroup',
              'verses': [
                {
                  'n': 1,
                  'inlines': [
                    {'t': 'text', 'v': 'EN el principio era el Verbo.'},
                  ],
                },
                {
                  'n': 2,
                  'inlines': [
                    {'t': 'text', 'v': 'Este era en el principio con Dios.'},
                  ],
                },
              ],
            },
          ],
        },
        {
          'n': 2,
          'blocks': [
            {'type': 'chapterNumber', 'value': 2},
            {
              'type': 'verseGroup',
              'verses': [
                {
                  'n': 1,
                  'inlines': [
                    {'t': 'text', 'v': 'Y al tercer día…'},
                  ],
                },
              ],
            },
          ],
        },
      ],
    }),
  };

  static final Map<String, BookDocument> _tahot = {
    'PSA': BookDocument.fromJson({
      'code': 'PSA',
      'name': 'Salmos',
      'chapters': [
        {
          'n': 3,
          'blocks': [
            {'type': 'chapterNumber', 'value': 3},
            {
              'type': 'verseGroup',
              'verses': [
                {
                  'n': 0,
                  'inlines': [
                    {
                      't': 'text',
                      'v': 'אֱלֹהִים ',
                      'strong': 'H0430',
                      'strongFull': 'H0430',
                      'morph': 'HNcmpa',
                      'translit': 'e.lo.him',
                      'gloss': 'God',
                      'glossEs': 'Dios',
                    },
                    {
                      't': 'text',
                      'v': 'מִזְמוֹר',
                      'strong': 'H4210',
                      'strongFull': 'H4210',
                      'morph': 'HNcmsa',
                      'translit': 'miz.Mor',
                      'gloss': 'a psalm',
                    },
                  ],
                },
                {
                  'n': 1,
                  'inlines': [
                    {
                      't': 'text',
                      'v': 'יְהוָה ',
                      'strong': 'H3068',
                      'strongFull': 'H3068',
                      'morph': 'HNp',
                      'translit': 'a.do.Nai',
                      'gloss': 'LORD',
                      'glossEs': 'Señor',
                    },
                    {
                      't': 'text',
                      'v': 'רֹעִי',
                      'strong': 'H7462',
                      'strongFull': 'H7462',
                      'morph': 'HVqrmsc/Sp1cs',
                      'translit': "ro.'i",
                      'gloss': 'my shepherd',
                      'glossEs': 'mi pastor',
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    }),
  };

  static final Map<String, BookDocument> _tagnt = {
    'JHN': BookDocument.fromJson({
      'code': 'JHN',
      'name': 'Juan',
      'chapters': [
        {
          'n': 1,
          'blocks': [
            {'type': 'chapterNumber', 'value': 1},
            {
              'type': 'verseGroup',
              'verses': [
                {
                  'n': 1,
                  'inlines': [
                    {
                      't': 'text',
                      'v': 'Ἐν ',
                      'strong': 'G1722',
                      'strongFull': 'G1722',
                      'morph': 'PREP',
                      'lemma': 'ἐν',
                      'translit': 'En',
                      'gloss': 'in on among',
                      'glossEs': 'en',
                    },
                    {
                      't': 'text',
                      'v': 'ἀρχῇ ',
                      'strong': 'G0746',
                      'strongFull': 'G0746',
                      'morph': 'N-DSF',
                      'lemma': 'ἀρχή',
                      'translit': 'archē',
                      'gloss': 'beginning',
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    }),
  };

  static final Map<String, BookDocument> _kjv = {
    'GEN': BookDocument.fromJson({
      'code': 'GEN',
      'name': 'Genesis',
      'chapters': [
        {
          'n': 1,
          'blocks': [
            {'type': 'chapterNumber', 'value': 1},
            {
              'type': 'verseGroup',
              'verses': [
                {
                  'n': 1,
                  'inlines': [
                    {
                      't': 'text',
                      'v': 'In the beginning God created the heaven and the earth.',
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    }),
    'JHN': BookDocument.fromJson({
      'code': 'JHN',
      'name': 'John',
      'chapters': [
        {
          'n': 1,
          'blocks': [
            {'type': 'chapterNumber', 'value': 1},
            {
              'type': 'verseGroup',
              'verses': [
                {
                  'n': 1,
                  'inlines': [
                    {
                      't': 'text',
                      'v': 'In the beginning was the Word, and the Word was with God.',
                    },
                  ],
                },
                {
                  'n': 2,
                  'inlines': [
                    {
                      't': 'text',
                      'v': 'The same was in the beginning with God.',
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    }),
  };

  @override
  Future<DocumentManifest> loadManifest(String resourceId) async =>
      _manifests[resourceId] ?? _manifests['bible.rv1909']!;

  @override
  Future<BookDocument> loadBook(String resourceId, String code) async {
    final books = switch (resourceId) {
      'bible.kjv' => _kjv,
      'bible.tahot' => _tahot,
      'bible.tagnt' => _tagnt,
      _ => _rv1909,
    };
    return books[code] ?? books.values.first;
  }
}

/// Secciones sintéticas (M5): devocional generado al vuelo y dos artículos
/// del Factbook, con las mismas claves que el contrato del catálogo.
class FakeSectionsRepository implements SectionsRepository {
  final List<String> indexCalls = [];
  final List<String> sectionCalls = [];

  static const factbookTopics = [
    {
      'id': 'gracia',
      'kind': 'topic',
      'title': 'Gracia',
      'summary': 'Favor inmerecido de Dios.',
      'tags': ['Teología', 'Salvación'],
      'related': ['fe'],
      'references': ['EPH.2.8'],
      'blocks': [
        {'type': 'heading', 'text': 'Gracia', 'style': 'section'},
        {
          'type': 'paragraph',
          'inlines': [
            {'t': 'text', 'v': 'La gracia es el favor que Dios concede.'},
          ],
        },
      ],
    },
    {
      'id': 'fe',
      'kind': 'topic',
      'title': 'Fe',
      'summary': 'Confianza activa en Dios.',
      'tags': ['Vida cristiana'],
      'related': ['gracia'],
      'references': ['HEB.11.1'],
      'blocks': [
        {'type': 'heading', 'text': 'Fe', 'style': 'section'},
        {
          'type': 'paragraph',
          'inlines': [
            {'t': 'text', 'v': 'La fe responde a lo que Dios ha mostrado.'},
          ],
        },
        {
          'type': 'map',
          'title': 'Belén y Jerusalén',
          'caption': 'Mapa de prueba del Factbook.',
          'center': [31.75, 35.22],
          'latSpan': 0.4,
          'lonSpan': 0.5,
          'markers': [
            {'name': 'Belén', 'lat': 31.704306, 'lon': 35.207639,
             'ref': 'LUK.2.4'},
          ],
        },
      ],
    },
  ];

  @override
  Future<List<SectionSummary>> loadIndex(String resourceId) async {
    indexCalls.add(resourceId);
    return factbookTopics.map(SectionSummary.fromJson).toList();
  }

  @override
  Future<CatalogSection?> loadSection(
    String resourceId,
    String sectionId,
  ) async {
    sectionCalls.add('$resourceId/$sectionId');
    if (sectionId.startsWith('dayofyear.')) {
      return CatalogSection.fromJson({
        'id': sectionId,
        'day': sectionId.substring('dayofyear.'.length),
        'title': 'Lectura de prueba',
        'theme': 'Confianza',
        'reference': 'JHN.1.1',
        'referenceLabel': 'Juan 1:1',
        'blocks': [
          {'type': 'heading', 'text': 'Lectura de prueba', 'style': 'section'},
          {
            'type': 'paragraph',
            'inlines': [
              {
                't': 'span',
                'v': '«En el principio era el Verbo.»',
                'style': 'italic',
              },
            ],
          },
          {
            'type': 'paragraph',
            'inlines': [
              {'t': 'text', 'v': 'Contenido devocional de prueba.'},
            ],
          },
        ],
      });
    }
    for (final topic in factbookTopics) {
      if (topic['id'] == sectionId) return CatalogSection.fromJson(topic);
    }
    return null;
  }
}
