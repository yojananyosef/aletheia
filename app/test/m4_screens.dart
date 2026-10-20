// Herramienta de desarrollo: captura las pantallas de M4 (panel de Notas,
// editor, filtros, papelera y notas dentro del lector) para revisarlas contra
// los diseños.
//
// No forma parte de la suite de tests: el archivo no termina en `_test.dart`.
//
// Ejecutar:  flutter test test/m4_screens.dart
// Salida:    /tmp/opencode/m4-*.png
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
import 'package:aletheia/notes/notes_models.dart';
import 'package:aletheia/notes/notes_panel.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/reader/reader_panel.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';

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
  final file = File('/tmp/opencode/m4-$name.png');
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('captura → ${file.path} (${boundary.size.width}x${boundary.size.height})');
}

Widget _scope({
  required GlobalKey key,
  required Widget child,
  NotesState? notes,
  Locale? locale,
}) =>
    KeyedSubtree(
      key: UniqueKey(),
      child: UncontrolledProviderScope(
        container: ProviderContainer(
          overrides: [
            workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
            notesStoreProvider.overrideWithValue(NotesStore.inMemory(notes)),
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

final _now = DateTime(2026, 10, 19, 10, 30);

NotesState _seedNotes() => NotesState(
      notes: [
        Note(
          id: 'note_1',
          title: 'El Verbo y la creación',
          body: 'Juan presenta al **Verbo** como agente de la creación.\n\n'
              '- Coeterno con Dios\n'
              '- Fuente de vida y luz\n\n'
              'Comparar con ==Génesis 1:1== y con *Proverbios 8*.',
          anchors: const [
            NoteAnchor(
              resourceId: 'bible.rv1909',
              reference: 'JHN.1.1',
              bookCode: 'JHN',
              chapter: 1,
              verse: 1,
            ),
          ],
          notebooks: const ['nb_1'],
          tags: const ['Cristología', 'Creación'],
          createdAt: _now.subtract(const Duration(days: 3)),
          updatedAt: _now.subtract(const Duration(hours: 2)),
        ),
        Note(
          id: 'note_2',
          title: 'La luz en las tinieblas',
          body: 'La luz resplandece y las tinieblas no la comprendieron.',
          anchors: const [
            NoteAnchor(
              resourceId: 'bible.rv1909',
              reference: 'JHN.1.5',
              bookCode: 'JHN',
              chapter: 1,
              verse: 5,
              quote: 'la luz en las tinieblas resplandece',
            ),
          ],
          notebooks: const ['nb_1'],
          tags: const ['Luz'],
          createdAt: _now.subtract(const Duration(days: 2)),
          updatedAt: _now.subtract(const Duration(days: 1)),
        ),
        Note(
          id: 'hl_1',
          kind: 'highlight',
          body: 'El testimonio de Juan.',
          anchors: const [
            NoteAnchor(
              resourceId: 'bible.rv1909',
              reference: 'JHN.1.6',
              bookCode: 'JHN',
              chapter: 1,
              verse: 6,
              startOffset: 0,
              endOffset: 26,
              quote: 'Hubo un hombre enviado de Dios',
            ),
          ],
          tags: const ['Testimonio'],
          color: 'green',
          createdAt: _now.subtract(const Duration(days: 1)),
          updatedAt: _now.subtract(const Duration(hours: 5)),
        ),
        Note(
          id: 'note_trash',
          title: 'Borrador descartado',
          body: 'Idea que no llegó a nada.',
          deletedAt: _now.subtract(const Duration(days: 1)),
          createdAt: _now.subtract(const Duration(days: 6)),
          updatedAt: _now.subtract(const Duration(days: 1)),
        ),
      ],
      notebooks: [
        Notebook(
          id: 'nb_1',
          name: 'Estudio de Juan',
          createdAt: _now,
        ),
      ],
    );

void main() {
  testWidgets('capturas de M4: Notas y lector', (tester) async {
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

    // --- Panel de Notas: lista -----------------------------------------
    tester.view.physicalSize = const Size(760, 900);
    final listKey = GlobalKey();
    await tester.pumpWidget(_scope(
      key: listKey,
      locale: const Locale('es'),
      notes: _seedNotes(),
      child: const NotesPanel(),
    ));
    await tester.pumpAndSettle();
    await _capture(tester, listKey, 'notes-list');

    // --- Panel de Notas: filtros ---------------------------------------
    final filtersKey = GlobalKey();
    await tester.pumpWidget(_scope(
      key: filtersKey,
      locale: const Locale('es'),
      notes: _seedNotes(),
      child: const NotesPanel(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notes-sidebar-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notes-filters-button')));
    await tester.pumpAndSettle();
    await _capture(tester, filtersKey, 'notes-filters');

    // --- Panel de Notas: editor ----------------------------------------
    final editorKey = GlobalKey();
    await tester.pumpWidget(_scope(
      key: editorKey,
      locale: const Locale('es'),
      notes: _seedNotes(),
      child: const NotesPanel(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-card-note_1')));
    await tester.pumpAndSettle();
    await _capture(tester, editorKey, 'notes-editor');

    // --- Panel de Notas: papelera --------------------------------------
    final trashKey = GlobalKey();
    await tester.pumpWidget(_scope(
      key: trashKey,
      locale: const Locale('es'),
      notes: _seedNotes(),
      child: const NotesPanel(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notes-sidebar-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notes-trash-toggle')));
    await tester.pumpAndSettle();
    await _capture(tester, trashKey, 'notes-trash');

    // --- Lector: anotaciones y resaltados inline ------------------------
    tester.view.physicalSize = const Size(820, 900);
    final readerKey = GlobalKey();
    final tab = WorkspaceTab(
      id: 'tab_lector',
      kind: PanelKind.bible,
      title: 'RV1909',
      reference: 'JHN.1.1',
      resourceId: 'bible.rv1909',
    );
    await tester.pumpWidget(_scope(
      key: readerKey,
      locale: const Locale('es'),
      notes: _seedNotes(),
      child: ReaderPanel(
        tile: WorkspaceTile(id: 'tile_0', tabs: [tab]),
        tab: tab,
      ),
    ));
    await tester.pumpAndSettle();
    await _capture(tester, readerKey, 'reader-annotations');

    // --- Lector: modo Notas --------------------------------------------
    final notesModeKey = GlobalKey();
    await tester.pumpWidget(_scope(
      key: notesModeKey,
      locale: const Locale('es'),
      notes: _seedNotes(),
      child: ReaderPanel(
        tile: WorkspaceTile(id: 'tile_0', tabs: [tab]),
        tab: tab,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-mode-notes')));
    await tester.pumpAndSettle();
    await _capture(tester, notesModeKey, 'reader-notes');
  });
}
