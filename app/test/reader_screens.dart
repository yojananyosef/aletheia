// Herramienta de desarrollo: captura el panel del lector a PNG para comparar
// con las capturas de referencia (según la evidencia de reconocimiento).
//
// No forma parte de la suite de tests: el archivo no termina en `_test.dart`,
// así que `flutter test` no lo ejecuta por defecto.
//
// Ejecutar:  flutter test test/reader_screens.dart
// Salida:    /tmp/opencode/reader-{1-home,2-contents,3-history}.png
//
// El entorno de test no trae fuentes (el texto saldría en cajas): aquí se
// registran las del SDK de Flutter (Roboto + MaterialIcons) y una serif del
// sistema bajo los nombres de familia que usa la app.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/core/theme.dart';
import 'package:aletheia/reader/reader_panel.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/notes/notes_persistence.dart';

class _DiskRepository extends DocumentRepository {
  static const _root = 'assets/catalog/rv1909';

  @override
  Future<DocumentManifest> loadManifest(String resourceId) async =>
      DocumentManifest.fromJson(
        jsonDecode(File('$_root/manifest.json').readAsStringSync())
            as Map<String, dynamic>,
      );

  @override
  Future<BookDocument> loadBook(String resourceId, String code) async =>
      BookDocument.fromJson(
        jsonDecode(File('$_root/books/$code.json').readAsStringSync())
            as Map<String, dynamic>,
      );
}

/// Registra una familia de fuentes con los archivos indicados (los que falten
/// se ignoran: la captura saldrá con cajas en vez de texto).
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
  // La codificación de imagen usa la hebra de rasterizado real: debe correr
  // fuera de la zona de async falso del widget test.
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  final file = File('/tmp/opencode/reader-$name.png');
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('captura → ${file.path} (${boundary.size.width}x${boundary.size.height})');
}

void main() {
  testWidgets('capturas del panel del lector', (tester) async {
    final home = Platform.environment['HOME'] ?? '';
    final sdkFonts = '$home/.local/share/flutter/bin/cache/artifacts/material_fonts';
    await _loadFamily('Roboto', [
      '$sdkFonts/Roboto-Regular.ttf',
      '$sdkFonts/Roboto-Bold.ttf',
      '$sdkFonts/Roboto-Medium.ttf',
      '$sdkFonts/Roboto-Italic.ttf',
    ]);
    await _loadFamily('MaterialIcons', ['$sdkFonts/MaterialIcons-Regular.otf']);
    // El cuerpo del lector pide 'DejaVu Serif' con respaldo a serifs del
    // sistema; para la captura basta registrar cualquiera de ellas.
    await _loadFamily('DejaVu Serif', [
      '/usr/share/fonts/liberation/LiberationSerif-Regular.ttf',
      '/usr/share/fonts/liberation/LiberationSerif-Bold.ttf',
      '/usr/share/fonts/liberation/LiberationSerif-Italic.ttf',
    ]);

    tester.view.devicePixelRatio = 1.0;
    // Permite comparar paneles estrechos (como el original) y anchos:
    //   SCREEN_WIDTH=900 SCREEN_SUFFIX=-w900 flutter test test/reader_screens.dart
    final width =
        double.tryParse(Platform.environment['SCREEN_WIDTH'] ?? '') ?? 640;
    final suffix = Platform.environment['SCREEN_SUFFIX'] ?? '';
    tester.view.physicalSize = Size(width, 820);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final captureKey = GlobalKey();
    final tab = WorkspaceTab(
      id: 'tab1',
      kind: PanelKind.bible,
      title: 'Biblia',
      reference: 'JHN.1.1',
      history: const ['GEN.1.1', 'PSA.23.1', 'JHN.1.1'],
      historyIndex: 2,
    );
    final tile = WorkspaceTile(id: 'tile_0', tabs: [tab]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
          documentRepositoryProvider.overrideWithValue(_DiskRepository()),
        ],
        // El RepaintBoundary abarca el MaterialApp completo para que las
        // capturas incluyan los overlays (menús emergentes, diálogos).
        child: RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            home: Scaffold(
              body: Material(
                color: Colors.white,
                child: ReaderPanel(tile: tile, tab: tab),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, captureKey, '1-home$suffix');

    // Índice (Contents)
    await tester.tap(find.text('Índice'));
    await tester.pumpAndSettle();
    await _capture(tester, captureKey, '2-contents$suffix');

    // Historial (menú emergente, con el índice cerrado)
    await tester.tap(find.text('Índice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    await _capture(tester, captureKey, '3-history$suffix');
  });
}
