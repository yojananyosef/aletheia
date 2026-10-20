// Herramienta de desarrollo: captura los drawers de M6.1 (Ideas e Información)
// con la app real montada sobre el catálogo local (assets) para revisarlas
// contra las capturas locales del original.
//
// No forma parte de la suite de tests: el archivo no termina en `_test.dart`.
//
// Ejecutar:  flutter test test/m6_screens.dart
// Salida:    /tmp/opencode/m6-app-*.png
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/assistant/assistant_controller.dart';
import 'package:aletheia/assistant/assistant_models.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/catalog/sections_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_models.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

/// Documentos reales desde el disco (assets de la RV1909).
class _DiskRepository implements DocumentRepository {
  static const _root = 'assets/catalog/rv1909';

  @override
  Future<DocumentManifest> loadManifest(String resourceId) async =>
      DocumentManifest.fromJson(jsonDecode(
              File('$_root/manifest.json').readAsStringSync())
          as Map<String, dynamic>);

  @override
  Future<BookDocument> loadBook(String resourceId, String code) async =>
      BookDocument.fromJson(jsonDecode(
              File('$_root/books/$code.json').readAsStringSync())
          as Map<String, dynamic>);
}

/// Secciones desde el disco (los assets reales del Factbook y el devocional).
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

/// Motor de demostración para la captura del chat del Asistente: responde con
/// texto propio y una cita, sin salir de la máquina.
class _DemoAssistantEngine implements StudyAssistantEngine {
  @override
  String get name => 'Proveedor de demostración';

  @override
  Future<AssistantAnswer> ask({
    required String question,
    required AssistantScope scope,
  }) async =>
      const AssistantAnswer(
        text: 'El prólogo de Juan presenta al Verbo como Dios y como la luz '
            'que vence a las tinieblas; la respuesta se apoya en la RV1909 '
            'de tu biblioteca.',
        references: ['JHN.1.1', 'JHN.1.5'],
      );
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
  final file = File('/tmp/opencode/m6-app-$name.png');
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('captura → ${file.path} (${boundary.size.width}x${boundary.size.height})');
}

void main() {
  testWidgets('capturas de M6.1: Ideas, Información y menú Artículo',
      (tester) async {
    // Un `tap` sintético deja el foco en modo teclado y el framework dibuja un
    // anillo negro alrededor de los menús; no ocurre con el ratón real.
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    addTearDown(() =>
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
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

    StudyAssistantEngine? assistantEngine;
    final container = ProviderContainer(
      overrides: [
        assistantEngineProvider.overrideWith((ref) => assistantEngine),
        // Un solo panel: la captura muestra el lector a todo el ancho.
        workspaceStoreProvider.overrideWithValue(
          WorkspaceStore.inMemory(WorkspaceState.fresh(layoutId: 'one')),
        ),
        notesStoreProvider.overrideWithValue(NotesStore.inMemory(NotesState(
          notes: [
            Note(
              id: 'demo-note',
              title: 'Sermón del domingo',
              body: 'La gracia como regalo.',
              anchors: const [
                NoteAnchor(
                  resourceId: 'bible.rv1909',
                  reference: 'EPH.2.8',
                  bookCode: 'EPH',
                  chapter: 2,
                  verse: 8,
                ),
              ],
              notebooks: const ['nb-demo'],
              color: 'yellow',
              createdAt: DateTime(2026, 10, 19),
              updatedAt: DateTime(2026, 10, 19),
            ),
            Note(
              id: 'demo-highlight',
              kind: 'highlight',
              anchors: const [
                NoteAnchor(
                  resourceId: 'bible.rv1909',
                  reference: 'EPH.2.8',
                  bookCode: 'EPH',
                  chapter: 2,
                  verse: 8,
                  startOffset: 0,
                  endOffset: 17,
                ),
              ],
              tags: const ['fe'],
              color: 'green',
              createdAt: DateTime(2026, 10, 19),
              updatedAt: DateTime(2026, 10, 19),
            ),
          ],
          notebooks: [
            Notebook(
              id: 'nb-demo',
              name: 'Sermones',
              createdAt: DateTime(2026, 10, 19),
            ),
          ],
        ))),
        documentRepositoryProvider.overrideWithValue(_DiskRepository()),
        catalogGatewayProvider
            .overrideWithValue(FakeCatalogGateway(resources: testResources)),
        sectionsRepositoryProvider.overrideWithValue(_DiskSectionsRepository()),
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

    // --- Ideas: pestaña de la referencia actual (Efesios 2:8) ----------
    ctrl.openTab(const TabSpec(
      kind: PanelKind.bible,
      reference: 'EPH.2.8',
      title: 'Efesios 2:8',
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reader-insights')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('insights-tab-reference')));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'insights-reference');

    // --- Ideas: pestaña de información del libro -----------------------
    await tester.tap(find.byKey(const ValueKey('insights-tab-book')));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'insights-book');

    // --- Información (ⓘ): ficha con información auxiliar ---------------
    await tester.tap(find.byKey(const ValueKey('reader-info')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Información auxiliar'));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'info');

    // --- Artículo ▾: menú abierto --------------------------------------
    await tester.tap(find.byKey(const ValueKey('reader-info')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-article')));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'article-menu');

    // --- Formato ▸ Marcadores (M6.2) -----------------------------------
    await tester.tapAt(const Offset(400, 500)); // cierra el menú
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-mode-format')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-markers')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('markers-switch')),
      matching: find.byType(Switch),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sermones (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#fe (1)'));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'markers');

    // --- Herramientas: menú de la barra lateral (M6.3) ------------------
    await tester.tap(find.byKey(const ValueKey('reader-mode-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tools-menu-sidebar')));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'tools-menu');
    await tester.tapAt(const Offset(300, 700));
    await tester.pumpAndSettle();

    // --- Estudio guiado: listado y una guía en ejecución -----------------
    ctrl.openTab(const TabSpec(kind: PanelKind.guidedStudy));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'guided-hub');
    await tester.tap(find.byKey(const ValueKey('guide-exegetical')));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'guided-run');

    // --- Planes de lectura (M6.3) ----------------------------------------
    ctrl.openTab(const TabSpec(kind: PanelKind.readingPlans));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan-start-bible-year')));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'plans');

    // --- Panel de inicio (M6.3) ------------------------------------------
    ctrl.openTab(const TabSpec(kind: PanelKind.dashboard));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'dashboard');

    // --- Asistente de estudio (M6.4) -------------------------------------
    ctrl.openTab(const TabSpec(kind: PanelKind.studyAssistant));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'assistant');
    assistantEngine = _DemoAssistantEngine();
    container.invalidate(assistantEngineProvider);
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'assistant-chat-empty');
    await tester.tap(find.byKey(const ValueKey('assistant-suggest-1')));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'assistant-chat');

    // --- Shell en ventana angosta: rail + ómnibus en diálogo ------------
    tester.view.physicalSize = const Size(760, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpAndSettle();
    ctrl.openTab(const TabSpec(kind: PanelKind.bible, reference: 'JHN.1.1'));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'shell-narrow');
    await tester.tap(find.byKey(const ValueKey('sidebar-omnibox')));
    await tester.pumpAndSettle();
    await _capture(tester, appKey, 'shell-narrow-omnibox');
    await tester.tapAt(const Offset(380, 500));
    await tester.pumpAndSettle();

    // Guardado diferido del workspace.
    await tester.pump(const Duration(milliseconds: 500));
  });
}
