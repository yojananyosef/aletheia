// Herramienta de desarrollo: captura el resaltado por palabra de la
// Comparación de textos con una segunda versión española sintética (ESP2).
// El catálogo real solo trae RV1909 y KJV, y entre idiomas distintos no se
// resalta nada: esta variante permite revisar el diseño del paquete C.
//
// No forma parte de la suite: el archivo no termina en `_test.dart`.
//
// Ejecutar:  flutter test test/m5_compare_diff_screens.dart
// Salida:    /tmp/opencode/m5-app-compare-diff.png
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/catalog_models.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

const _esp2 = ResourceSummary(
  id: 'bible.esp2',
  type: 'bible',
  title: 'Español de prueba',
  abbrev: 'ESP2',
  authors: [],
  language: 'es',
  licenseKind: 'public-domain',
  licenseText: 'Dominio público',
  verses: 31102,
  sections: 1189,
  description: 'Variante sintética para verificar el resaltado.',
);

class _VariantRepository implements DocumentRepository {
  Map<String, dynamic> _json(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  static const _changes = <int, String>{
    1: 'EN el principio existía el Verbo, y el Verbo estaba con Dios, y el Verbo era Dios.',
    2: 'Él estaba en el principio con Dios.',
    3: 'Todas las cosas por medio de él fueron hechas; y sin él nada de lo que es hecho, fué hecho.',
    5: 'Y la luz en las tinieblas brilla; mas las tinieblas no la comprendieron.',
  };

  @override
  Future<DocumentManifest> loadManifest(String resourceId) async {
    final map = _json('assets/catalog/rv1909/manifest.json');
    if (resourceId == 'bible.esp2') {
      map['resourceId'] = 'bible.esp2';
      map['title'] = 'Español de prueba';
      map['abbrev'] = 'ESP2';
    }
    return DocumentManifest.fromJson(map);
  }

  @override
  Future<BookDocument> loadBook(String resourceId, String code) async {
    final doc = _json('assets/catalog/rv1909/books/$code.json');
    if (resourceId == 'bible.esp2' && code == 'JHN') {
      for (final chapter in (doc['chapters'] as List)) {
        if (chapter['n'] != 1) continue;
        for (final block in (chapter['blocks'] as List)) {
          final verses = block['verses'];
          if (verses is! List) continue;
          for (final verse in verses) {
            final text = _changes[verse['n']];
            if (text != null) {
              verse['inlines'] = [
                {'t': 'text', 'v': text}
              ];
            }
          }
        }
      }
    }
    return BookDocument.fromJson(doc);
  }
}

Future<void> _loadFamily(String family, List<String> files) async {
  final loader = FontLoader(family);
  var any = false;
  for (final file in files) {
    if (!File(file).existsSync()) continue;
    final bytes = File(file).readAsBytesSync();
    loader.addFont(
        Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    any = true;
  }
  if (any) await loader.load();
}

void main() {
  testWidgets('verificación del resaltado intra-idioma', (tester) async {
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
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(
      overrides: [
        workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
        notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
        documentRepositoryProvider.overrideWithValue(_VariantRepository()),
        catalogGatewayProvider.overrideWithValue(FakeCatalogGateway(
          resources: [testResources.first, _esp2],
        )),
      ],
    );
    addTearDown(container.dispose);

    final appKey = GlobalKey();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(key: appKey, child: const AletheiaApp()),
    ));
    await tester.pumpAndSettle();

    container.read(workspaceProvider.notifier).openTab(
        const TabSpec(kind: PanelKind.textComparison, reference: 'JHN.1.1'));
    await tester.pumpAndSettle();

    final boundary =
        appKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    Directory('/tmp/opencode').createSync(recursive: true);
    File('/tmp/opencode/m5-app-compare-diff.png').writeAsBytesSync(bytes!);
    // ignore: avoid_print
    print('captura → /tmp/opencode/m5-app-compare-diff.png');
  });
}
