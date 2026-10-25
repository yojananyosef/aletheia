// Herramienta de desarrollo: captura la Biblioteca y la Búsqueda a PNG para
// comparar con las referencias del original (según la evidencia de reconocimiento).
//
// No forma parte de la suite de tests: el archivo no termina en `_test.dart`.
//
// Ejecutar:  flutter test test/m2_screens.dart
// Salida:    /tmp/opencode/m2-{library,library-detail,library-narrow,search}.png
//
// Los datos son los que devuelve el servicio real (recogidos con curl); se
// incrustan aquí porque el entorno de test no permite HTTP real.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_client.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/catalog_models.dart';
import 'package:aletheia/core/theme.dart';
import 'package:aletheia/library/library_overlay.dart';
import 'package:aletheia/search/search_panel.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/notes/notes_persistence.dart';

// ------------------------------------------------ datos reales del servicio

const _resources = [
  ResourceSummary(
    id: 'bible.kjv',
    type: 'bible',
    title: 'King James Version',
    subtitle: 'King James Version (Authorized Version)',
    abbrev: 'KJV',
    authors: ['Traductores de la Versión Autorizada (1611)'],
    language: 'en',
    publisher: 'eBible.org',
    edition: '1769 (texto estandarizado)',
    description:
        'Versión autorizada inglesa de 1611, en el texto estandarizado de 1769. '
        'Esta edición incluye los 66 libros del canon protestante; el paquete de '
        'origen es de dominio público.',
    licenseKind: 'public-domain',
    licenseText: 'Public Domain',
    tags: ['Biblia', 'Inglés', 'Dominio público'],
    verses: 31102,
    sections: 1189,
  ),
  ResourceSummary(
    id: 'bible.rv1909',
    type: 'bible',
    title: 'Reina-Valera 1909',
    subtitle: 'Santa Biblia — Reina Valera 1909',
    abbrev: 'RV1909',
    authors: ['Reina, Casiodoro de', 'Valera, Cipriano de'],
    language: 'es',
    publisher: 'Sociedad Bíblica Británica y Extranjera',
    edition: '1909',
    description:
        'Traducción clásica al español iniciada por Casiodoro de Reina (1569) y '
        'revisada por Cipriano de Valera; esta edición de 1909 es de dominio '
        'público. Incluye los 66 libros del canon protestante.',
    licenseKind: 'public-domain',
    licenseText: 'Dominio público',
    tags: ['Biblia', 'Español', 'Dominio público'],
    verses: 31102,
    sections: 1189,
  ),
];

const _verbsHits = [
  SearchHit(
    resourceId: 'bible.rv1909',
    resourceTitle: 'Reina-Valera 1909',
    abbrev: 'RV1909',
    sectionId: 'JHN.1',
    book: 'JHN',
    bookName: 'Juan',
    chapter: 1,
    verse: 1,
    ref: 'JHN.1.1',
    citation: 'Juan 1:1',
    snippet:
        'EN el principio era el <em>Verbo</em>, y el <em>Verbo</em> era con '
        'Dios, y el <em>Verbo</em> era Dios.',
  ),
  SearchHit(
    resourceId: 'bible.rv1909',
    resourceTitle: 'Reina-Valera 1909',
    abbrev: 'RV1909',
    sectionId: 'REV.19',
    book: 'REV',
    bookName: 'Apocalipsis',
    chapter: 19,
    verse: 13,
    ref: 'REV.19.13',
    citation: 'Apocalipsis 19:13',
    snippet: '…y su nombre es llamado EL <em>VERBO</em> DE DIOS.',
  ),
  SearchHit(
    resourceId: 'bible.rv1909',
    resourceTitle: 'Reina-Valera 1909',
    abbrev: 'RV1909',
    sectionId: '1JN.5',
    book: '1JN',
    bookName: '1 Juan',
    chapter: 5,
    verse: 7,
    ref: '1JN.5.7',
    citation: '1 Juan 5:7',
    snippet:
        'Porque tres son los que dan testimonio en el cielo, el Padre, el '
        '<em>Verbo</em>, y el Espíritu Santo: y estos tres son uno.',
  ),
  SearchHit(
    resourceId: 'bible.rv1909',
    resourceTitle: 'Reina-Valera 1909',
    abbrev: 'RV1909',
    sectionId: 'JHN.1',
    book: 'JHN',
    bookName: 'Juan',
    chapter: 1,
    verse: 14,
    ref: 'JHN.1.14',
    citation: 'Juan 1:14',
    snippet:
        'Y aquel <em>Verbo</em> fué hecho carne, y habitó entre nosotros '
        '(y vimos su gloria, gloria como del unigénito del Padre), lleno de '
        'gracia y de verdad.',
  ),
  SearchHit(
    resourceId: 'bible.rv1909',
    resourceTitle: 'Reina-Valera 1909',
    abbrev: 'RV1909',
    sectionId: '1JN.1',
    book: '1JN',
    bookName: '1 Juan',
    chapter: 1,
    verse: 1,
    ref: '1JN.1.1',
    citation: '1 Juan 1:1',
    snippet:
        'LO que era desde el principio, lo que hemos oído, lo que hemos '
        'visto con nuestros ojos, lo que hemos mirado, y palparon nuestras '
        'manos tocante al <em>Verbo</em> de vida;',
  ),
];

class _FixtureGateway extends CatalogGateway {
  _FixtureGateway()
    : super(
        mode: 'auto',
        client: CatalogClient(baseUrl: 'http://127.0.0.1:1'),
      );

  @override
  Future<ResourceListing> listResources({
    String query = '',
    String? type,
    String? language,
    String? author,
    String? subject,
    String? publisher,
    String sort = 'title',
    int page = 1,
    int pageSize = 50,
  }) async {
    final items =
        _resources.where((r) {
          if (type != null && r.type != type) return false;
          if (language != null && r.language != language) return false;
          if (author != null && !r.authors.contains(author)) return false;
          return true;
        }).toList()..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    return ResourceListing(
      total: items.length,
      page: page,
      pageSize: pageSize,
      items: items,
      facets: const {
        'type': {'bible': 2},
        'language': {'en': 1, 'es': 1},
        'author': {
          'Reina, Casiodoro de': 1,
          'Traductores de la Versión Autorizada (1611)': 1,
          'Valera, Cipriano de': 1,
        },
      },
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
  }) async => SearchResult(
    query: query,
    scope: scope,
    total: _verbsHits.length,
    page: page,
    pageSize: pageSize,
    hits: _verbsHits,
  );
}

// ------------------------------------------------------------------ capturas

Future<void> _loadFamily(String family, List<String> files) async {
  final loader = FontLoader(family);
  var any = false;
  for (final file in files) {
    if (!File(file).existsSync()) continue;
    final bytes = File(file).readAsBytesSync();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    any = true;
  }
  if (any) await loader.load();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  final file = File('/tmp/opencode/m2-$name.png');
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print(
    'captura → ${file.path} (${boundary.size.width}x${boundary.size.height})',
  );
}

Widget _frame({
  required GlobalKey key,
  required Widget child,
  required Size size,
}) => RepaintBoundary(
  key: key,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildLightTheme(),
    home: Scaffold(
      backgroundColor: kWorkspaceBg,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            // Fondo que imita el espacio de trabajo (dashboard vacío).
            Positioned.fill(
              child: Container(
                color: kWorkspaceBg,
                child: const Center(
                  child: Icon(
                    Icons.space_dashboard_outlined,
                    size: 64,
                    color: Color(0x22000000),
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    ),
  ),
);

ProviderScope _scope(Widget child) => ProviderScope(
  overrides: [
    workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
    notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
    catalogGatewayProvider.overrideWithValue(_FixtureGateway()),
  ],
  child: child,
);

void main() {
  testWidgets('capturas de Biblioteca y Búsqueda', (tester) async {
    final home = Platform.environment['HOME'] ?? '';
    final sdkFonts =
        '$home/.local/share/flutter/bin/cache/artifacts/material_fonts';
    await _loadFamily('Roboto', [
      '$sdkFonts/Roboto-Regular.ttf',
      '$sdkFonts/Roboto-Bold.ttf',
      '$sdkFonts/Roboto-Medium.ttf',
      '$sdkFonts/Roboto-Italic.ttf',
    ]);
    await _loadFamily('MaterialIcons', ['$sdkFonts/MaterialIcons-Regular.otf']);

    tester.view.devicePixelRatio = 1.0;

    // --- Biblioteca en ventana amplia --------------------------------
    tester.view.physicalSize = const Size(1180, 760);
    final wideKey = GlobalKey();
    await tester.pumpWidget(
      _scope(
        _frame(
          key: wideKey,
          size: const Size(1180, 760),
          child: const LibraryOverlay(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, wideKey, 'library');

    // --- Biblioteca con el detalle abierto --------------------------
    await tester.tap(find.byKey(const ValueKey('library-row-bible.rv1909')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await _capture(tester, wideKey, 'library-detail');

    // --- Biblioteca en la ventana real (764 px) ---------------------
    tester.view.physicalSize = const Size(764, 800);
    final narrowKey = GlobalKey();
    await tester.pumpWidget(
      _scope(
        _frame(
          key: narrowKey,
          size: const Size(764, 800),
          child: const LibraryOverlay(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, narrowKey, 'library-narrow');

    // --- Biblioteca estrecha con el detalle (sustituye a la lista) ---
    await tester.tap(find.byKey(const ValueKey('library-row-bible.rv1909')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await _capture(tester, narrowKey, 'library-narrow-detail');

    // --- Búsqueda con resultados reales -----------------------------
    tester.view.physicalSize = const Size(764, 800);
    final searchKey = GlobalKey();
    final tab = WorkspaceTab(
      id: 'tab-search',
      kind: PanelKind.search,
      title: 'Búsqueda',
      query: 'Verbo',
      history: const ['principio', 'Verbo'],
      historyIndex: 1,
    );
    final tile = WorkspaceTile(id: 'tile_0');
    await tester.pumpWidget(
      _scope(
        _frame(
          key: searchKey,
          size: const Size(764, 800),
          child: Material(
            color: Colors.white,
            child: SearchPanel(tile: tile, tab: tab),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, searchKey, 'search');

    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  });
}
