// Herramienta de desarrollo: captura los arreglos del panel del lector y de
// la barra lateral (búsqueda dentro del panel y ventana estrecha).
//
// No forma parte de la suite de tests: el archivo no termina en `_test.dart`.
//
// Ejecutar:  flutter test test/fix_screens.dart
// Salida:    /tmp/opencode/fix-{panel-search,narrow-shell}.png
//
// Los documentos se leen del disco (assets de la app y datos del servicio) y
// los resultados de búsqueda son los reales del servicio para «principio».
import 'dart:convert';
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
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/core/theme.dart';
import 'package:aletheia/reader/reader_panel.dart';
import 'package:aletheia/shell/shell.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/notes/notes_persistence.dart';

/// Documentos reales desde el disco: assets (RV1909) y datos del servicio.
class _DiskRepository implements DocumentRepository {
  static String _root(String resourceId) => resourceId == 'bible.kjv'
      ? '../catalog/data/resources/bible.kjv'
      : 'assets/catalog/rv1909';

  @override
  Future<DocumentManifest> loadManifest(String resourceId) async =>
      DocumentManifest.fromJson(
        jsonDecode(
          File('${_root(resourceId)}/manifest.json').readAsStringSync(),
        ) as Map<String, dynamic>,
      );

  @override
  Future<BookDocument> loadBook(String resourceId, String code) async =>
      BookDocument.fromJson(
        jsonDecode(
          File('${_root(resourceId)}/books/$code.json').readAsStringSync(),
        ) as Map<String, dynamic>,
      );
}

/// Resultados reales del servicio para `principio` (scope Biblia, RV1909).
class _SearchGateway extends CatalogGateway {
  _SearchGateway()
    : super(
        mode: 'local',
        client: CatalogClient(baseUrl: 'http://127.0.0.1:1'),
      );

  static const _hits = [
    SearchHit(
      resourceId: 'bible.rv1909',
      resourceTitle: 'Reina-Valera 1909',
      abbrev: 'RV1909',
      sectionId: 'MAT.24',
      book: 'MAT',
      bookName: 'San Mateo',
      chapter: 24,
      verse: 8,
      ref: 'MAT.24.8',
      citation: 'San Mateo 24:8',
      snippet: 'Y todas estas cosas, <em>principio</em> de dolores.',
    ),
    SearchHit(
      resourceId: 'bible.rv1909',
      resourceTitle: 'Reina-Valera 1909',
      abbrev: 'RV1909',
      sectionId: 'JHN.1',
      book: 'JHN',
      bookName: 'Juan',
      chapter: 1,
      verse: 2,
      ref: 'JHN.1.2',
      citation: 'Juan 1:2',
      snippet: 'Este era en el <em>principio</em> con Dios.',
    ),
    SearchHit(
      resourceId: 'bible.rv1909',
      resourceTitle: 'Reina-Valera 1909',
      abbrev: 'RV1909',
      sectionId: 'MRK.1',
      book: 'MRK',
      bookName: 'Marcos',
      chapter: 1,
      verse: 1,
      ref: 'MRK.1.1',
      citation: 'Marcos 1:1',
      snippet: '<em>PRINCIPIO</em> del evangelio de Jesucristo, Hijo de Dios.',
    ),
  ];

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
    total: _hits.length,
    page: page,
    pageSize: pageSize,
    hits: _hits,
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
  final file = File('/tmp/opencode/fix-$name.png');
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print(
    'captura → ${file.path} (${boundary.size.width}x${boundary.size.height})',
  );
}

Widget _scope({
  required GlobalKey key,
  required Widget child,
  required DocumentRepository repository,
  required CatalogGateway gateway,
  WorkspaceState? state,
}) => ProviderScope(
  overrides: [
    workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory(state)),
    notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
    documentRepositoryProvider.overrideWithValue(repository),
    catalogGatewayProvider.overrideWithValue(gateway),
  ],
  child: RepaintBoundary(
    key: key,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      home: Scaffold(
        body: Material(color: Colors.white, child: child),
      ),
    ),
  ),
);

void main() {
  testWidgets('capturas de los arreglos del panel y la barra lateral', (
    tester,
  ) async {
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
    await _loadFamily('DejaVu Serif', [
      '/usr/share/fonts/liberation/LiberationSerif-Regular.ttf',
      '/usr/share/fonts/liberation/LiberationSerif-Bold.ttf',
      '/usr/share/fonts/liberation/LiberationSerif-Italic.ttf',
    ]);

    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final repository = _DiskRepository();
    final gateway = _SearchGateway();

    // --- Búsqueda dentro del panel del lector ---------------------------
    tester.view.physicalSize = const Size(660, 780);
    final searchKey = GlobalKey();
    final searchTab = WorkspaceTab(
      id: 'tab_buscar',
      kind: PanelKind.bible,
      title: 'RV1909',
      reference: 'MAT.24.1',
      resourceId: 'bible.rv1909',
      history: const ['GEN.1.1', 'JHN.1.1', 'MAT.24.1'],
      historyIndex: 2,
    );
    await tester.pumpWidget(
      _scope(
        key: searchKey,
        repository: repository,
        gateway: gateway,
        child: ReaderPanel(
          tile: WorkspaceTile(id: 'tile_0', tabs: [searchTab]),
          tab: searchTab,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reader-search-field')),
      'principio',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await _capture(tester, searchKey, 'panel-search');

    // --- Ventana estrecha: dos versiones y barra lateral expandida ------
    tester.view.physicalSize = const Size(764, 900);
    final shellKey = GlobalKey();
    final rvTab = WorkspaceTab(
      id: 'tab_rv',
      kind: PanelKind.bible,
      title: 'RV1909',
      reference: 'JHN.1.1',
      resourceId: 'bible.rv1909',
    );
    final kjvTab = WorkspaceTab(
      id: 'tab_kjv',
      kind: PanelKind.bible,
      title: 'KJV',
      reference: 'GEN.1.1',
      resourceId: 'bible.kjv',
    );
    final state = WorkspaceState(
      layoutId: 'two',
      bannerVisible: false,
      tiles: [
        WorkspaceTile(id: 'tile_0', tabs: [rvTab]),
        WorkspaceTile(id: 'tile_1', tabs: [kjvTab]),
      ],
    );
    await tester.pumpWidget(
      _scope(
        key: shellKey,
        repository: repository,
        gateway: gateway,
        state: state,
        child: const Shell(),
      ),
    );
    await tester.pumpAndSettle();
    // El pie permite expandir la barra lateral aunque la ventana sea estrecha.
    await tester.tap(find.byTooltip('Expandir barra lateral'));
    await tester.pumpAndSettle();
    await _capture(tester, shellKey, 'narrow-shell');
  });
}
