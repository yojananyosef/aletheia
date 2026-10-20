// Herramienta de desarrollo: captura las pantallas de M3 (Formato, Vista
// paginada y Ajustes en español e inglés) para revisarlas contra los diseños.
//
// No forma parte de la suite de tests: el archivo no termina en `_test.dart`.
//
// Ejecutar:  flutter test test/m3_screens.dart
// Salida:    /tmp/opencode/m3-{format-flyout,paged-view,settings,settings-en}.png
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
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/core/theme.dart';
import 'package:aletheia/l10n/app_localizations.dart';
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
      DocumentManifest.fromJson(jsonDecode(
              File('${_root(resourceId)}/manifest.json').readAsStringSync())
          as Map<String, dynamic>);

  @override
  Future<BookDocument> loadBook(String resourceId, String code) async =>
      BookDocument.fromJson(jsonDecode(
              File('${_root(resourceId)}/books/$code.json').readAsStringSync())
          as Map<String, dynamic>);
}

/// Catálogo local con los dos recursos empaquetados (sin red).
class _LocalGateway extends CatalogGateway {
  _LocalGateway()
      : super(mode: 'local', client: CatalogClient(baseUrl: 'http://127.0.0.1:1'));
}

// ------------------------------------------------------------------ capturas

Future<void> _loadFamily(String family, List<String> files) async {
  final loader = FontLoader(family);
  var any = false;
  for (final file in files) {
    if (!File(file).existsSync()) continue;
    final bytes = File(file).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    any = true;
  }
  if (any) await loader.load();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  final file = File('/tmp/opencode/m3-$name.png');
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('captura → ${file.path} (${boundary.size.width}x${boundary.size.height})');
}

/// Cada captura usa su propio contenedor y un subárbol nuevo: al reutilizar
/// el `ProviderScope` anterior, Riverpod conserva el estado del primero.
Widget _scope({
  required GlobalKey key,
  required Widget child,
  WorkspaceState? state,
  Locale? locale,
}) =>
    KeyedSubtree(
      key: UniqueKey(),
      child: UncontrolledProviderScope(
        container: ProviderContainer(
          overrides: [
            workspaceStoreProvider
                .overrideWithValue(WorkspaceStore.inMemory(state)),
notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
            documentRepositoryProvider.overrideWithValue(_DiskRepository()),
            catalogGatewayProvider.overrideWithValue(_LocalGateway()),
          ],
        ),
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Material(color: Colors.white, child: child),
            ),
          ),
        ),
      ),
    );

WorkspaceTab _rvTab({
  required String id,
  required String reference,
  TabDisplay display = TabDisplay.defaults,
}) =>
    WorkspaceTab(
      id: id,
      kind: PanelKind.bible,
      title: 'RV1909',
      reference: reference,
      resourceId: 'bible.rv1909',
      display: display,
    );

void main() {
  testWidgets('capturas de M3: Formato, Vista y Ajustes', (tester) async {
    final home = Platform.environment['HOME'] ?? '';
    final sdkFonts = '$home/.local/share/flutter/bin/cache/artifacts/material_fonts';
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

    // --- Formato ▸ Reformato -------------------------------------------
    tester.view.physicalSize = const Size(700, 820);
    final formatKey = GlobalKey();
    final formatTab = _rvTab(
      id: 'tab_formato',
      reference: 'JHN.1.1',
      display: const TabDisplay(reformat: true, oneVersePerLine: true),
    );
    await tester.pumpWidget(_scope(
      key: formatKey,
      locale: const Locale('es'),
      child: ReaderPanel(
        tile: WorkspaceTile(id: 'tile_0', tabs: [formatTab]),
        tab: formatTab,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-mode-format')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-reformat')));
    await tester.pumpAndSettle();
    await _capture(tester, formatKey, 'format-flyout');

    // --- Vista ▸ Vista paginada ----------------------------------------
    final pagedKey = GlobalKey();
    // La vista paginada se define en la pestaña: el panel no está conectado a
    // un espacio de trabajo real en estas capturas.
    final pagedTab = _rvTab(
      id: 'tab_vista',
      reference: 'JHN.1.1',
      display: const TabDisplay(paged: true, columns: '1'),
    );
    await tester.pumpWidget(_scope(
      key: pagedKey,
      locale: const Locale('es'),
      child: ReaderPanel(
        tile: WorkspaceTile(id: 'tile_0', tabs: [pagedTab]),
        tab: pagedTab,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-mode-view')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-paged-view')));
    await tester.pumpAndSettle();
    await _capture(tester, pagedKey, 'paged-view');

    // --- Ajustes (español) ---------------------------------------------
    tester.view.physicalSize = const Size(1200, 850);
    final settingsKey = GlobalKey();
    await tester.pumpWidget(_scope(
      key: settingsKey,
      locale: const Locale('es'),
      state: WorkspaceState(
        layoutId: 'one',
        bannerVisible: false,
        locale: 'es',
        tiles: [
          WorkspaceTile(
            id: 'tile_0',
            tabs: [
              const WorkspaceTab(
                id: 'tab_ajustes',
                kind: PanelKind.settings,
                title: '',
              ),
            ],
          ),
        ],
      ),
      child: const Shell(),
    ));
    await tester.pumpAndSettle();
    await _capture(tester, settingsKey, 'settings');

    // --- Ajustes (inglés) ----------------------------------------------
    final englishKey = GlobalKey();
    await tester.pumpWidget(_scope(
      key: englishKey,
      locale: const Locale('en'),
      state: WorkspaceState(
        layoutId: 'one',
        bannerVisible: false,
        locale: 'en',
        tiles: [
          WorkspaceTile(
            id: 'tile_0',
            tabs: [
              const WorkspaceTab(
                id: 'tab_ajustes',
                kind: PanelKind.settings,
                title: '',
              ),
            ],
          ),
        ],
      ),
      child: const Shell(),
    ));
    await tester.pumpAndSettle();
    await _capture(tester, englishKey, 'settings-en');
  });
}
