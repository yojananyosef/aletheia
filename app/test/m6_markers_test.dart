// M6.2: Marcadores (Formato ▸ Marcadores): filtro de los indicadores de nota y
// resaltados del lector por cuaderno y etiqueta (nuestros «datasets» locales).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_models.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

Note _note({
  required String id,
  String kind = 'note',
  String title = '',
  int verse = 1,
  int? start,
  int? end,
  List<String> notebooks = const [],
  List<String> tags = const [],
}) =>
    Note(
      id: id,
      kind: kind,
      title: title,
      anchors: [
        NoteAnchor(
          resourceId: 'bible.rv1909',
          reference: 'JHN.1.$verse',
          bookCode: 'JHN',
          chapter: 1,
          verse: verse,
          startOffset: start,
          endOffset: end,
        ),
      ],
      notebooks: notebooks,
      tags: tags,
      color: 'yellow',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

final _notes = NotesState(
  notes: [
    // Nota en el cuaderno «Sermones» (versículo 2).
    _note(id: 'n1', title: 'Sermón', verse: 2, notebooks: ['nb1']),
    // Nota suelta (sin cuaderno ni etiqueta).
    _note(id: 'n3', title: 'Suelta', verse: 1),
    // Resaltado con la etiqueta «fe» sobre «el principio» del versículo 1.
    _note(id: 'n2', kind: 'highlight', verse: 1, start: 3, end: 15, tags: ['fe']),
  ],
  notebooks: [
    Notebook(id: 'nb1', name: 'Sermones', createdAt: DateTime(2026, 1, 1)),
  ],
);

void _setWindow(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(2200, 1000);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<ProviderContainer> _pumpReader(
  WidgetTester tester, {
  NotesState? notes,
}) async {
  _setWindow(tester);
  final container = ProviderContainer(
    overrides: [
      workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
      notesStoreProvider
          .overrideWithValue(NotesStore.inMemory(notes ?? const NotesState())),
      catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
      documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
    ],
  );
  addTearDown(container.dispose);
  container.read(workspaceProvider.notifier).openTab(const TabSpec(
        kind: PanelKind.bible,
        title: 'RV1909',
        reference: 'JHN.1.1',
        resourceId: 'bible.rv1909',
      ));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const AletheiaApp(),
  ));
  await tester.pumpAndSettle();
  return container;
}

TabDisplay _display(ProviderContainer container) {
  for (final tile in container.read(workspaceProvider).tiles) {
    for (final tab in tile.tabs) {
      if (tab.kind == PanelKind.bible) return tab.display;
    }
  }
  throw StateError('sin pestaña de Biblia');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _switchInside(Key key) => find.descendant(
      of: find.byKey(key),
      matching: find.byType(Switch),
    );

/// Abre el flyout Formato ▸ Marcadores.
Future<void> _openMarkers(WidgetTester tester) async {
  await _tap(tester, find.byKey(const ValueKey('reader-mode-format')));
  await _tap(tester, find.byKey(const ValueKey('reader-markers')));
}

/// Vuelve al texto (Inicio) para ver el efecto del filtro.
Future<void> _backToText(WidgetTester tester) =>
    _tap(tester, find.byKey(const ValueKey('reader-mode-home')));

List<TextSpan> _highlightSpans(WidgetTester tester) {
  final out = <TextSpan>[];
  void walk(InlineSpan? node) {
    if (node is TextSpan) {
      if (node.style?.backgroundColor != null) out.add(node);
      for (final child in node.children ?? const <InlineSpan>[]) {
        walk(child);
      }
    }
  }

  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    walk(text.textSpan);
  }
  return out;
}

void main() {
  // ------------------------------------------------------ filtros (puros)

  test('TabDisplay: filtro de marcadores y persistencia', () {
    const none = TabDisplay(markers: true);
    expect(none.markerFilterMatches(const [], const []), isTrue);

    const notebooks = TabDisplay(markers: true, markerNotebooks: ['nb1']);
    expect(notebooks.markerFilterMatches(const ['nb1'], const []), isTrue);
    expect(notebooks.markerFilterMatches(const ['nb2'], const ['fe']), isFalse);

    const tags = TabDisplay(markers: true, markerTags: ['fe']);
    expect(tags.markerFilterMatches(const ['nb1'], const ['fe']), isTrue);
    expect(tags.markerFilterMatches(const ['nb1'], const []), isFalse);

    const both =
        TabDisplay(markers: true, markerNotebooks: ['nb1'], markerTags: ['fe']);
    expect(both.markerFilterMatches(const ['nb1'], const ['fe']), isTrue);
    expect(both.markerFilterMatches(const ['nb1'], const []), isFalse);
    expect(both.markerFilterMatches(const [], const ['fe']), isFalse);

    // Con el maestro apagado se pinta todo.
    expect(both.copyWith(markers: false).markerFilterMatches(const [], const []),
        isTrue);

    // Ida y vuelta por JSON (persistencia del panel).
    final back = TabDisplay.fromJson(both.toJson());
    expect(back.markers, isTrue);
    expect(back.markerNotebooks, ['nb1']);
    expect(back.markerTags, ['fe']);
    final defaults = TabDisplay.fromJson(TabDisplay.defaults.toJson());
    expect(defaults.markerNotebooks, isEmpty);
    expect(defaults.markerTags, isEmpty);
  });

  // ------------------------------------------------------- filtros (lector)

  testWidgets('Marcadores filtra notas y resaltados por cuaderno y etiqueta',
      (tester) async {
    final container = await _pumpReader(tester, notes: _notes);

    // Sin filtros: los dos indicadores y el resaltado.
    expect(find.byKey(const Key('verse-note-marker-n1')), findsOneWidget);
    expect(find.byKey(const Key('verse-note-marker-n3')), findsOneWidget);
    expect(_highlightSpans(tester), isNotEmpty);

    await _openMarkers(tester);
    expect(find.text('CUADERNOS'), findsOneWidget);
    expect(find.text('Sermones (1)'), findsOneWidget);
    expect(find.text('#fe (1)'), findsOneWidget);

    // Con el maestro apagado la casilla no responde.
    await _tap(tester, find.text('Sermones (1)'));
    expect(_display(container).markerNotebooks, isEmpty);

    // Encender y filtrar por cuaderno: solo la nota del cuaderno.
    await _tap(tester, _switchInside(const ValueKey('markers-switch')));
    expect(_display(container).markers, isTrue);
    await _tap(tester, find.text('Sermones (1)'));
    expect(_display(container).markerNotebooks, ['nb1']);

    await _backToText(tester);
    expect(find.byKey(const Key('verse-note-marker-n1')), findsOneWidget);
    expect(find.byKey(const Key('verse-note-marker-n3')), findsNothing);
    expect(_highlightSpans(tester), isEmpty);

    // Cuaderno + etiqueta exigen ambas condiciones: no queda nada.
    await _openMarkers(tester);
    await _tap(tester, find.text('#fe (1)'));
    expect(_display(container).markerTags, ['fe']);
    await _backToText(tester);
    expect(find.byKey(const Key('verse-note-marker-n1')), findsNothing);
    expect(find.byKey(const Key('verse-note-marker-n3')), findsNothing);
    expect(_highlightSpans(tester), isEmpty);

    // Solo la etiqueta: vuelve el resaltado.
    await _openMarkers(tester);
    await _tap(tester, find.text('Sermones (1)'));
    expect(_display(container).markerNotebooks, isEmpty);
    await _backToText(tester);
    expect(find.byKey(const Key('verse-note-marker-n1')), findsNothing);
    expect(_highlightSpans(tester), isNotEmpty);

    // Apagar el maestro pinta todo, pero recuerda los filtros.
    await _openMarkers(tester);
    await _tap(tester, _switchInside(const ValueKey('markers-switch')));
    expect(_display(container).markers, isFalse);
    await _backToText(tester);
    expect(find.byKey(const Key('verse-note-marker-n1')), findsOneWidget);
    expect(find.byKey(const Key('verse-note-marker-n3')), findsOneWidget);
    expect(_highlightSpans(tester), isNotEmpty);
    expect(_display(container).markerTags, ['fe']);
  });

  // -------------------------------------------------------- estado vacío

  testWidgets('Marcadores sin cuadernos ni etiquetas muestra su aviso',
      (tester) async {
    await _pumpReader(tester, notes: const NotesState());

    await _openMarkers(tester);
    expect(
      find.textContaining('Aún no hay cuadernos ni etiquetas'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('markers-switch')), findsOneWidget);
  });
}
