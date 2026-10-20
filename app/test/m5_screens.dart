// Herramienta de desarrollo: captura las pantallas de M5 (devocional,
// Factbook y comparación de textos) con la app real montada sobre el catálogo
// local (assets) para revisarlas contra los diseños del original.
//
// Las capturas del original viven en /tmp/opencode/m5-devotional.png,
// m5-factbook.png y m5-compare.png: esta herramienta escribe con prefijo
// `m5-app-` para no pisarlas.
//
// No forma parte de la suite de tests: el archivo no termina en `_test.dart`.
//
// Ejecutar:  flutter test test/m5_screens.dart
// Salida:    /tmp/opencode/m5-app-*.png
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/catalog/sections_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

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

/// Secciones desde el disco (los assets reales). `rootBundle` no completa
/// dentro del *fake async* de `testWidgets` porque es E/S real; aquí se leen
/// los mismos archivos de forma síncrona.
class _DiskSectionsRepository implements SectionsRepository {
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  List<Map<String, dynamic>> _entries(String resourceId) =>
      _cache.putIfAbsent(resourceId, () {
        final text =
            File('assets/catalog/$resourceId/sections.json').readAsStringSync();
        return (jsonDecode(text) as List).cast<Map<String, dynamic>>();
      });

  @override
  Future<List<SectionSummary>> loadIndex(String resourceId) async => [
        for (final entry in _entries(resourceId)) SectionSummary.fromJson(entry),
      ];

  @override
  Future<CatalogSection?> loadSection(
    String resourceId,
    String sectionId,
  ) async {
    for (final entry in _entries(resourceId)) {
      if (entry['id'] == sectionId) return CatalogSection.fromJson(entry);
    }
    return null;
  }
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
  final file = File('/tmp/opencode/m5-app-$name.png');
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('captura → ${file.path} (${boundary.size.width}x${boundary.size.height})');
}

void main() {
  testWidgets('capturas de M5: devocional, Factbook y comparación',
      (tester) async {
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
        documentRepositoryProvider.overrideWithValue(_DiskRepository()),
        catalogGatewayProvider.overrideWithValue(FakeCatalogGateway(
          resources: [testResources.first, testKjv],
        )),
        sectionsRepositoryProvider
            .overrideWithValue(_DiskSectionsRepository()),
      ],
    );
    addTearDown(container.dispose);

    final appKey = GlobalKey();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(key: appKey, child: const AletheiaApp()),
    ));
    await tester.pumpAndSettle();

    final ctrl = container.read(workspaceProvider.notifier);

    // --- Devocional del día -------------------------------------------
    ctrl.openTab(const TabSpec(kind: PanelKind.devotional));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'devotional');

    // --- Factbook: lista de temas y artículo (gracia) ------------------
    ctrl.openTab(const TabSpec(kind: PanelKind.factbook));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'factbook-list');

    await tester.tap(find.byKey(const ValueKey('factbook-topic-gracia')));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'factbook-article');

    // --- Comparación de textos: RV1909 + KJV ---------------------------
    ctrl.openTab(const TabSpec(kind: PanelKind.textComparison));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'compare');
  });
}
