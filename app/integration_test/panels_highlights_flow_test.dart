// Prueba de integración sobre el binario Linux real (los dos fallos
// corregidos): cambiar/quitar el color de un resaltado desde el menú de
// selección y el destino/arrastre de pestañas entre paneles.
//
// Ejecutar:  flutter test integration_test/panels_highlights_flow_test.dart -d linux
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_controller.dart';
import 'package:aletheia/notes/notes_models.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

/// Posición global del carácter `offset` de un párrafo (gestos de texto).
Offset _textOffsetToPosition(RenderParagraph paragraph, int offset) {
  const caret = Rect.fromLTWH(0, 0, 2, 20);
  final local = paragraph.getOffsetForCaret(
    TextPosition(offset: offset),
    caret,
  );
  return paragraph.localToGlobal(local) + const Offset(1, 8);
}

Future<ProviderContainer> _launch(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
      notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AletheiaApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

String _tileOf(ProviderContainer container, String tabId) => container
    .read(workspaceProvider)
    .tiles
    .firstWhere((tile) => tile.tabs.any((tab) => tab.id == tabId))
    .id;

/// Spans con color de fondo (resaltados) dentro de un párrafo.
Iterable<TextSpan> _backgroundSpans(InlineSpan span) sync* {
  if (span is! TextSpan) return;
  if (span.style?.backgroundColor != null) yield span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    yield* _backgroundSpans(child);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];

  testWidgets('resaltado: cambiar el color actualiza y «Quitar» lo elimina', (
    tester,
  ) async {
    final container = await _launch(tester);
    await tester.tap(find.byKey(const ValueKey('nav-bible')));
    await tester.pumpAndSettle();

    final verseText = find.textContaining('EN el principio crió Dios');
    expect(verseText, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: verseText, matching: find.byType(RichText)).first,
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

    // Crear el resaltado.
    await select();
    await tester.tap(find.byKey(const Key('selection-highlight-green')));
    await tester.pumpAndSettle();
    var notes = container.read(notesProvider).notes;
    expect(notes, hasLength(1));
    expect(notes.single.color, 'green');

    // Cambiar el color sobre el mismo texto: actualiza, no apila.
    await select();
    expect(find.byKey(const Key('selection-highlight-remove')), findsOneWidget);
    await tester.tap(find.byKey(const Key('selection-highlight-red')));
    await tester.pumpAndSettle();
    notes = container.read(notesProvider).notes;
    expect(notes, hasLength(1));
    expect(notes.single.color, 'red');

    // Quitarlo desde el menú de selección.
    await select();
    await tester.tap(find.byKey(const Key('selection-highlight-remove')));
    await tester.pumpAndSettle();
    expect(container.read(notesProvider).notes, isEmpty);

    // Deja vencer el guardado con retardo antes de desmontar el árbol.
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets(
    'un resaltado de otra versión no se pinta ni se confunde al quitar',
    (tester) async {
      final container = await _launch(tester);
      // Resaltado viejo anclado a otra versión (VBL) sobre el mismo
      // versículo; el lector abre RV1909.
      container
          .read(notesProvider.notifier)
          .createHighlight(
            anchor: const NoteAnchor(
              resourceId: 'bible.vbl',
              reference: 'GEN.1.1',
              bookCode: 'GEN',
              chapter: 1,
              verse: 1,
              startOffset: 1,
              endOffset: 14,
              quote: 'N el principio',
            ),
            color: 'orange',
          );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('nav-bible')));
      await tester.pumpAndSettle();

      final verseText = find.textContaining('EN el principio crió Dios');
      expect(verseText, findsOneWidget);
      RenderParagraph paragraph() => tester.renderObject<RenderParagraph>(
        find.descendant(of: verseText, matching: find.byType(RichText)).first,
      );
      expect(_backgroundSpans(paragraph().text), isEmpty);

      final plain = paragraph().text.toPlainText();
      final wordStart = plain.indexOf('principio');

      Future<void> select() async {
        final gesture = await tester.startGesture(
          _textOffsetToPosition(paragraph(), wordStart + 2),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await gesture.moveTo(_textOffsetToPosition(paragraph(), wordStart + 12));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
      }

      // No hay resaltado de este recurso bajo la selección: no se ofrece
      // «Quitar» (y el viejo sigue sin pintarse).
      await select();
      expect(
        find.byKey(const Key('selection-highlight-remove')),
        findsNothing,
      );

      // Pintar aquí crea un resaltado de RV1909 sin tocar el de VBL.
      await tester.tap(find.byKey(const Key('selection-highlight-green')));
      await tester.pumpAndSettle();
      var notes = container.read(notesProvider).notes;
      expect(notes, hasLength(2));
      expect(
        notes
            .singleWhere((n) => n.anchors.single.resourceId == 'bible.vbl')
            .color,
        'orange',
      );
      expect(
        notes
            .singleWhere((n) => n.anchors.single.resourceId == 'bible.rv1909')
            .color,
        'green',
      );

      // Quitar el nuevo deja intacto el de la otra versión y el texto limpio.
      await select();
      await tester.tap(find.byKey(const Key('selection-highlight-remove')));
      await tester.pumpAndSettle();
      notes = container.read(notesProvider).notes;
      expect(notes, hasLength(1));
      expect(notes.single.anchors.single.resourceId, 'bible.vbl');
      expect(_backgroundSpans(paragraph().text), isEmpty);

      // Deja vencer el guardado con retardo antes de desmontar el árbol.
      await tester.pump(const Duration(milliseconds: 500));
    },
  );

  testWidgets('paneles: la primera pestaña abre a la izquierda y se arrastra', (
    tester,
  ) async {
    final container = await _launch(tester);
    final ctrl = container.read(workspaceProvider.notifier);

    // La Biblia (primera apertura desde el chrome) cae en el primer panel.
    await tester.tap(find.byKey(const ValueKey('nav-bible')));
    await tester.pumpAndSettle();
    var state = container.read(workspaceProvider);
    final bibleId = state.tiles.first.tabs.single.id;
    expect(state.tiles[1].tabs, isEmpty);
    expect(_tileOf(container, bibleId), 'tile_0');

    // La segunda apertura aprovecha el panel libre.
    await tester.tap(find.byKey(const ValueKey('nav-notes')));
    await tester.pumpAndSettle();
    state = container.read(workspaceProvider);
    expect(state.tiles[0].tabs, hasLength(1));
    final notesId = state.tiles[1].tabs.single.id;
    expect(_tileOf(container, notesId), 'tile_1');

    // Arrastrar la pestaña de Notas al primer panel.
    final chip = find.byKey(ValueKey('tab-chip-$notesId'));
    final target = tester.getCenter(find.byKey(const ValueKey('tile-tile_0')));
    final gesture = await tester.startGesture(tester.getCenter(chip));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    await tester.pumpAndSettle();

    state = container.read(workspaceProvider);
    expect(state.tiles[0].tabs, hasLength(2));
    expect(state.tiles[1].tabs, isEmpty);
    expect(ctrl.activeTileId, 'tile_0');

    // Abrir desde el panel activo (ya lleno) usa el otro panel, sin taparlo.
    ctrl.openTab(const TabSpec(kind: PanelKind.favorites));
    state = container.read(workspaceProvider);
    expect(state.tiles[0].tabs, hasLength(2));
    expect(state.tiles[1].tabs.single.kind, PanelKind.favorites);

    await tester.pump(const Duration(milliseconds: 500));
  });
}
