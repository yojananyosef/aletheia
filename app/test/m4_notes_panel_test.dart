/// Pruebas de Notas (M4): panel global, editor, filtros, papelera, cuadernos,
/// compartir y la integración con el lector (marcadores, resaltados, selección
/// → nota y modo Notas del panel).
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_controller.dart';
import 'package:aletheia/notes/notes_models.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/notes/notes_query.dart';
import 'package:aletheia/reader/selection_toolbar.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

// --------------------------------------------------------------- utilidades

/// Posición global del carácter `offset` de un párrafo (para gestos de texto).
Offset _textOffsetToPosition(RenderParagraph paragraph, int offset) {
  const caret = Rect.fromLTWH(0, 0, 2, 20);
  final local =
      paragraph.getOffsetForCaret(TextPosition(offset: offset), caret);
  return paragraph.localToGlobal(local) + const Offset(1, 8);
}

ProviderContainer _container({CatalogGateway? gateway, NotesState? notes}) {
  final container = ProviderContainer(
    overrides: [
      workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
      notesStoreProvider.overrideWithValue(NotesStore.inMemory(notes)),
      catalogGatewayProvider.overrideWithValue(gateway ?? FakeCatalogGateway()),
      documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
    ],
  );
  return container;
}

void _setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<ProviderContainer> _pumpNotesPanel(WidgetTester tester,
    {NotesState? notes}) async {
  _setWindow(tester, const Size(1400, 900));
  final container = _container(notes: notes);
  addTearDown(container.dispose);
  container.read(workspaceProvider.notifier).openTab(
        const TabSpec(kind: PanelKind.notes),
      );
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const AletheiaApp(),
  ));
  await tester.pumpAndSettle();
  return container;
}

Future<ProviderContainer> _pumpReader(
  WidgetTester tester, {
  required NotesState notes,
  String reference = 'JHN.1.1',
}) async {
  _setWindow(tester, const Size(1400, 900));
  final container = _container(notes: notes);
  addTearDown(container.dispose);
  container.read(workspaceProvider.notifier).openTab(TabSpec(
        kind: PanelKind.bible,
        title: 'RV1909',
        reference: reference,
        resourceId: 'bible.rv1909',
      ));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const AletheiaApp(),
  ));
  await tester.pumpAndSettle();
  return container;
}

Note _seedNote({
  required String id,
  String kind = 'note',
  String title = '',
  String body = '',
  String? reference,
  String? bookCode,
  int? chapter,
  int? verse,
  int? start,
  int? end,
  String? quote,
  String color = 'yellow',
  List<String> notebooks = const [],
  List<String> tags = const [],
  DateTime? updatedAt,
  DateTime? deletedAt,
  String resourceId = 'bible.rv1909',
}) =>
    Note(
      id: id,
      kind: kind,
      title: title,
      body: body,
      anchors: [
        if (reference != null || bookCode != null)
          NoteAnchor(
            resourceId: resourceId,
            reference: reference,
            bookCode: bookCode,
            chapter: chapter,
            verse: verse,
            startOffset: start,
            endOffset: end,
            quote: quote,
          ),
      ],
      notebooks: notebooks,
      tags: tags,
      color: color,
      createdAt: updatedAt ?? DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime(2026, 1, 1),
      deletedAt: deletedAt,
    );

List<TextSpan> _flatten(InlineSpan? span) {
  final out = <TextSpan>[];
  void walk(InlineSpan? node) {
    if (node is TextSpan) {
      if (node.text != null) out.add(node);
      for (final child in node.children ?? const <InlineSpan>[]) {
        walk(child);
      }
    }
  }

  walk(span);
  return out;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];

  group('panel de Notas', () {
    testWidgets('estado vacío, crear nota y buscarla', (tester) async {
      final container = await _pumpNotesPanel(tester);

      expect(find.text('Aún no hay notas'), findsOneWidget);
      expect(find.byKey(const Key('notes-new-note')), findsOneWidget);

      await tester.tap(find.byKey(const Key('notes-new-note')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('note-title-field')), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('note-title-field')), 'Mi primera nota');
      await tester.enterText(
          find.byKey(const Key('note-body-field')), 'Contenido de prueba');
      await tester.pump(const Duration(milliseconds: 600));

      final note = container.read(notesProvider).notes.single;
      expect(note.title, 'Mi primera nota');

      // Volver a la lista: se ve la tarjeta con el título.
      await tester.tap(find.byKey(const Key('note-editor-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('note-card-${note.id}')), findsOneWidget);
      expect(find.text('Mi primera nota'), findsOneWidget);

      // «Buscar» filtra por texto.
      await tester.enterText(find.byKey(const Key('notes-find-field')), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Aún no hay notas'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('notes-find-field')), 'primera');
      await tester.pumpAndSettle();
      expect(find.byKey(Key('note-card-${note.id}')), findsOneWidget);
    });

    testWidgets('papelera: enviar, listar, restaurar y vaciar', (tester) async {
      final container = await _pumpNotesPanel(tester);
      final notifier = container.read(notesProvider.notifier);
      final a = notifier.createNote(title: 'Nota A');
      final b = notifier.createNote(title: 'Nota B');
      await tester.pumpAndSettle();

      expect(find.text('Nota A'), findsOneWidget);
      expect(find.text('Nota B'), findsOneWidget);

      // Enviar A a la papelera desde la tarjeta.
      await tester.tap(find.byKey(Key('note-trash-$a')));
      await tester.pumpAndSettle();
      expect(find.text('Nota A'), findsNothing);

      // La papelera vive en la barra lateral interna del panel.
      await tester.tap(find.byKey(const Key('notes-sidebar-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notes-trash-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Nota A'), findsOneWidget);
      expect(find.text('Nota B'), findsNothing);
      await tester.tap(find.byKey(Key('note-restore-$a')));
      await tester.pumpAndSettle();
      expect(find.text('Aún no hay notas'), findsNothing);
      expect(find.text('La papelera está vacía'), findsOneWidget);

      // Volver y eliminar B definitivamente desde el menú del panel.
      await tester.tap(find.byKey(const Key('notes-trash-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('note-trash-$b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notes-panel-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vaciar la papelera'));
      await tester.pumpAndSettle();
      expect(container.read(notesProvider).notes.map((n) => n.id), [a]);
    });

    testWidgets('filtros por tipo y etiqueta, y cuadernos', (tester) async {
      final container = await _pumpNotesPanel(
        tester,
        notes: NotesState(
          notes: [
            _seedNote(id: 'n1', title: 'Con nota', tags: ['fe']),
            _seedNote(id: 'h1', kind: 'highlight', quote: 'resaltado'),
          ],
          notebooks: const [],
        ),
      );
      final notifier = container.read(notesProvider.notifier);
      final nb = notifier.addNotebook('Sermones');
      notifier.toggleNotebookOnNote('n1', nb);
      await tester.pumpAndSettle();

      // Filtro por tipo: solo resaltados (barra lateral interna, pestaña
      // «Filtros», como el panel del original).
      await tester.tap(find.byKey(const Key('notes-sidebar-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notes-filters-button')), findsOneWidget);
      expect(find.text('Tipo'), findsOneWidget);
      await tester.tap(find.byKey(const Key('notes-filter-kind-highlight')));
      await tester.pumpAndSettle();
      expect(find.text('Con nota'), findsNothing);
      expect(find.byKey(const Key('note-card-h1')), findsOneWidget);

      // «Todos» limpia los filtros.
      await tester.tap(find.byKey(const Key('notes-scope-all')));
      await tester.pumpAndSettle();
      expect(find.text('Con nota'), findsOneWidget);

      // Filtro por cuaderno (pestaña «Cuadernos»).
      await tester.tap(find.byKey(const Key('notes-notebooks-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('notes-notebook-filter-$nb')));
      await tester.pumpAndSettle();
      expect(find.text('Con nota'), findsOneWidget);
      expect(find.byKey(const Key('note-card-h1')), findsNothing);
    });

    testWidgets('cabecera con recuento, densidad y orden por cuaderno',
        (tester) async {
      final container = await _pumpNotesPanel(
        tester,
        notes: NotesState(
          notes: [
            _seedNote(id: 'n1', title: 'Con nota'),
            _seedNote(id: 'n2', title: 'Otra'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Fila del ámbito con recuento, como «Todos (1 resultado)» del original.
      expect(find.text('Todos (2 resultados)'), findsOneWidget);

      // Densidad: la lista compacta queda marcada en el propio control.
      await tester.tap(find.byKey(const Key('notes-density')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckedPopupMenuItem<bool>, 'Compacto'));
      await tester.pumpAndSettle();
      expect(find.text('Compacto'), findsOneWidget);

      // Orden: creación, modificación y cuaderno; «Cuaderno» está deshabilitado
      // mientras no haya un cuaderno seleccionado (tooltip del original).
      await tester.tap(find.byKey(const Key('notes-sort-button')));
      await tester.pumpAndSettle();
      expect(find.text('Fecha de creación'), findsOneWidget);
      expect(find.text('Fecha de modificación'), findsOneWidget);
      var notebookItem = tester.widget<PopupMenuItem<NotesSort>>(
        find.widgetWithText(PopupMenuItem<NotesSort>, 'Cuaderno'),
      );
      expect(notebookItem.enabled, isFalse);
      await tester.tap(find.text('Fecha de creación'));
      await tester.pumpAndSettle();
      expect(find.text('por Fecha de creación'), findsOneWidget);

      // Con un cuaderno seleccionado el orden por cuaderno se habilita.
      final nb = container.read(notesProvider.notifier).addNotebook('Sermones');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notes-sidebar-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notes-notebooks-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('notes-notebook-filter-$nb')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notes-sort-button')));
      await tester.pumpAndSettle();
      notebookItem = tester.widget<PopupMenuItem<NotesSort>>(
        find.widgetWithText(PopupMenuItem<NotesSort>, 'Cuaderno'),
      );
      expect(notebookItem.enabled, isTrue);
      await tester.tap(find.text('Cuaderno'));
      await tester.pumpAndSettle();
      expect(find.text('por Cuaderno'), findsOneWidget);
    });

    testWidgets('el editor formatea y previsualiza el cuerpo', (tester) async {
      final container = await _pumpNotesPanel(
        tester,
        notes: NotesState(notes: [_seedNote(id: 'n1', title: 'Formato')]),
      );
      await tester.tap(find.byKey(const Key('note-card-n1')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('note-body-field')), 'Hola mundo');
      await tester.pump(const Duration(milliseconds: 400));

      final field =
          tester.widget<TextField>(find.byKey(const Key('note-body-field')));
      field.controller!.selection =
          const TextSelection(baseOffset: 0, extentOffset: 4);
      await tester.pump();
      await tester.tap(find.byKey(const Key('format-bold')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(field.controller!.text, '**Hola** mundo');
      expect(container.read(notesProvider).notes.single.body, '**Hola** mundo');

      await tester.tap(find.byKey(const Key('format-preview')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('note-body-preview')), findsOneWidget);
      expect(find.text('Hola mundo'), findsOneWidget);
    });

    testWidgets('compartir copia la nota como Markdown', (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') calls.add(call);
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await _pumpNotesPanel(
        tester,
        notes: NotesState(notes: [
          _seedNote(
            id: 'n1',
            title: 'Compartida',
            body: 'Cuerpo',
            reference: 'JHN.1.1',
            bookCode: 'JHN',
            chapter: 1,
            verse: 1,
          ),
        ]),
      );
      await tester.tap(find.byKey(const Key('note-card-n1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('note-editor-share')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copiar como Markdown'));
      await tester.pumpAndSettle();

      expect(calls, isNotEmpty);
      final text = (calls.last.arguments as Map)['text'] as String;
      expect(text, startsWith('# Compartida'));
      expect(text, contains('Cuerpo'));
      expect(text, contains('Juan 1:1'));
      expect(find.text('Nota copiada al portapapeles'), findsOneWidget);
    });
  });

  group('lector', () {
    testWidgets('marcadores, resaltados y modo Notas', (tester) async {
      final container = await _pumpReader(
        tester,
        notes: NotesState(notes: [
          _seedNote(
            id: 'n1',
            title: 'Nota anclada',
            body: 'Sobre el versículo 2',
            reference: 'JHN.1.2',
            bookCode: 'JHN',
            chapter: 1,
            verse: 2,
          ),
          _seedNote(
            id: 'h1',
            kind: 'highlight',
            color: 'yellow',
            reference: 'JHN.1.1',
            bookCode: 'JHN',
            chapter: 1,
            verse: 1,
            start: 3,
            end: 15,
          ),
        ]),
      );

      // El texto del versículo 1 lleva el resaltado.
      final spans = tester
          .widgetList<Text>(find.byType(Text))
          .expand((t) => _flatten(t.textSpan))
          .where((s) => s.style?.backgroundColor != null)
          .toList();
      expect(spans.map((s) => s.text), contains('el principio'));

      // El versículo 2 tiene marcador de nota.
      final marker = find.byKey(const Key('verse-note-marker-n1'));
      expect(marker, findsOneWidget);

      // Al pulsarlo, se ven las notas del versículo y se abre el editor.
      await tester.tap(marker);
      await tester.pumpAndSettle();
      expect(find.text('Notas en este versículo'), findsOneWidget);
      await tester.tap(find.byKey(const Key('verse-note-option-n1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('note-title-field')), findsOneWidget);
      expect(find.text('Juan 1:2'), findsWidgets);

      // Volver a la lista del modo Notas: agrupada por referencia.
      await tester.tap(find.byKey(const Key('note-editor-back')));
      await tester.pumpAndSettle();
      expect(find.text('Nota anclada'), findsOneWidget);

      // «Mostrar en el lector» vuelve al texto.
      await tester.tap(find.byKey(const Key('note-reader-n1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reader-pages')), findsNothing);
      expect(find.textContaining('Este era en el principio'), findsOneWidget);
      expect(container.read(notesProvider).notes, hasLength(2));
    });

    testWidgets('nota nueva anclada a la referencia actual', (tester) async {
      final container = await _pumpReader(
        tester,
        notes: const NotesState(),
        reference: 'JHN.1.2',
      );

      // Modo Notas desde la toolbar del lector.
      await tester.tap(find.byKey(const ValueKey('reader-mode-notes')));
      await tester.pumpAndSettle();
      expect(find.text('No hay notas en este recurso'), findsOneWidget);

      await tester.tap(find.byKey(const Key('notes-new-note')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('note-title-field')), findsOneWidget);

      // La nota nace anclada a la referencia del panel.
      final note = container.read(notesProvider).notes.single;
      expect(note.mainAnchor?.reference, 'JHN.1.2');
      expect(note.mainAnchor?.resourceId, 'bible.rv1909');
    });

    testWidgets('seleccionar texto y crear una nota con cita', (tester) async {
      final container = await _pumpReader(tester, notes: const NotesState());

      final verseText = find.textContaining('EN el principio era el Verbo');
      expect(verseText, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(
        find
            .descendant(of: verseText, matching: find.byType(RichText))
            .first,
      );
      final plain = paragraph.text.toPlainText();
      final wordStart = plain.indexOf('principio');
      expect(wordStart, greaterThanOrEqualTo(0));

      // En los tests la plataforma es Android: la selección se inicia con una
      // pulsación larga (el arrastre con ratón no compite en la arena). El
      // arrastre se queda dentro de la misma palabra para que el menú ofrezca
      // «Consultar», como en el original.
      final gesture = await tester.startGesture(
        _textOffsetToPosition(paragraph, wordStart + 1),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(_textOffsetToPosition(paragraph, wordStart + 8));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Menú de selección con la estructura del original (ledger-04 §2): fila
      // de acciones + fila de anotaciones (nota, cinco colores, subrayado).
      final toolbar = find.byType(SelectionToolbar);
      expect(toolbar, findsOneWidget);
      Finder inToolbar(String label) =>
          find.descendant(of: toolbar, matching: find.text(label));
      expect(inToolbar('Copiar'), findsOneWidget);
      expect(inToolbar('Consultar'), findsOneWidget, reason: 'palabra única');
      expect(inToolbar('Buscar'), findsOneWidget);
      expect(find.byKey(const Key('selection-more-options')), findsOneWidget);
      for (final color in kHighlightPickColorIds) {
        expect(find.byKey(Key('selection-highlight-$color')), findsOneWidget);
      }
      expect(find.byKey(const Key('selection-underline-red')), findsOneWidget);

      await tester.tap(find.byKey(const Key('selection-add-note')));
      await tester.pumpAndSettle();

      final notes = container.read(notesProvider).notes;
      expect(notes, hasLength(1));
      final note = notes.single;
      expect(note.quote, isNotNull);
      expect(note.mainAnchor?.reference, 'JHN.1.1');
      expect(note.mainAnchor?.startOffset, isNotNull);
      expect(find.byKey(const Key('note-title-field')), findsOneWidget);

      // Deja vencer el guardado con retardo antes de desmontar el árbol.
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('el menú de selección resalta con color y con subrayado',
        (tester) async {
      final container = await _pumpReader(tester, notes: const NotesState());

      final verseText = find.textContaining('EN el principio era el Verbo');
      final paragraph = tester.renderObject<RenderParagraph>(
        find
            .descendant(of: verseText, matching: find.byType(RichText))
            .first,
      );
      final plain = paragraph.text.toPlainText();
      final wordStart = plain.indexOf('principio');

      Future<void> select() async {
        final gesture = await tester.startGesture(
          _textOffsetToPosition(paragraph, wordStart + 2),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await gesture.moveTo(_textOffsetToPosition(paragraph, wordStart + 14));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
      }

      // Resaltado con el color elegido en la paleta del menú.
      await select();
      await tester.tap(find.byKey(const Key('selection-highlight-green')));
      await tester.pumpAndSettle();
      var notes = container.read(notesProvider).notes;
      expect(notes, hasLength(1));
      expect(notes.single.isHighlight, isTrue);
      expect(notes.single.color, 'green');
      expect(notes.single.style, kHighlightStyleHighlight);

      // Subrayado rojo (estilo del original distinto del fondo).
      await select();
      await tester.tap(find.byKey(const Key('selection-underline-red')));
      await tester.pumpAndSettle();
      notes = container.read(notesProvider).notes;
      expect(notes, hasLength(2));
      expect(notes.last.isUnderline, isTrue);
      expect(notes.last.color, kDefaultUnderlineColor);

      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
