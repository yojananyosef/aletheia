// M6.4: Asistente de estudio (plugin de IA opcional).
//
// Sin proveedor conectado el panel reproduce el estado «sin sesión» del
// original (aviso de IA, preguntas de ejemplo deshabilitadas y bloque para
// conectar). Con un motor inyectado aparece el chat con alcance, recientes,
// «Copiar todo» y respuestas con citas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/assistant/assistant_controller.dart';
import 'package:aletheia/assistant/assistant_models.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/reading_plans/reading_plans_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

class _FakeEngine implements StudyAssistantEngine {
  _FakeEngine({this.fail = false});

  final bool fail;
  final List<String> questions = [];
  AssistantScope? lastScope;

  @override
  String get name => 'Proveedor de prueba';

  @override
  Future<AssistantAnswer> ask({
    required String question,
    required AssistantScope scope,
  }) async {
    questions.add(question);
    lastScope = scope;
    if (fail) throw StateError('sin conexión');
    return const AssistantAnswer(
      text: 'Respuesta de prueba con una cita.',
      references: ['JHN.1.1'],
    );
  }
}

void _setWindow(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1400, 950);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  StudyAssistantEngine? engine,
}) async {
  _setWindow(tester);
  final container = ProviderContainer(
    overrides: [
      workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
      notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
      readingPlansStoreProvider
          .overrideWithValue(ReadingPlansStore.inMemory()),
      catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
      documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
      if (engine != null) assistantEngineProvider.overrideWithValue(engine),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const AletheiaApp(),
  ));
  await tester.pumpAndSettle();
  container
      .read(workspaceProvider.notifier)
      .openTab(const TabSpec(kind: PanelKind.studyAssistant));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _activate(ProviderContainer container, PanelKind kind) {
  final state = container.read(workspaceProvider);
  for (final tile in state.tiles) {
    for (var i = 0; i < tile.tabs.length; i++) {
      if (tile.tabs[i].kind == kind) {
        container.read(workspaceProvider.notifier).activateTab(tile.id, i);
        return;
      }
    }
  }
}

WorkspaceTab? _tab(ProviderContainer container, PanelKind kind) {
  for (final tile in container.read(workspaceProvider).tiles) {
    for (final tab in tile.tabs) {
      if (tab.kind == kind) return tab;
    }
  }
  return null;
}

void main() {
  testWidgets('sin proveedor: invitación, aviso de IA y plugin explicado',
      (tester) async {
    final container = await _pump(tester);

    expect(
        find.textContaining('Solo pregunta'), findsOneWidget);
    expect(find.text('Esta función usa IA. Verifica siempre los resultados.'),
        findsOneWidget);

    // Las preguntas de ejemplo están deshabilitadas, como en el original.
    for (var i = 1; i <= 3; i++) {
      final button = tester.widget<OutlinedButton>(
        find.byKey(ValueKey('assistant-prompt-$i')),
      );
      expect(button.onPressed, isNull);
    }

    // El botón explica el plugin y ofrece el Estudio guiado.
    await _tap(tester, find.byKey(const ValueKey('assistant-connect')));
    expect(find.text('Asistente de estudio'), findsWidgets);
    expect(find.textContaining('plugin opcional'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('assistant-open-guided')));
    expect(_tab(container, PanelKind.guidedStudy), isNotNull);
  });

  testWidgets('con motor: chat, citas, recientes, alcance y copiar',
      (tester) async {
    final engine = _FakeEngine();
    final container = await _pump(tester, engine: engine);

    expect(find.text('Proveedor de prueba'), findsOneWidget);
    expect(find.text('Todos los libros'), findsOneWidget);

    // La primera pregunta sale de una sugerencia.
    await _tap(tester, find.byKey(const ValueKey('assistant-suggest-1')));
    expect(engine.questions.single, '¿Qué enseña Juan 1 sobre el Verbo?');
    expect(engine.lastScope, AssistantScope.allBooks);
    expect(find.text('Respuesta de prueba con una cita.'), findsOneWidget);

    // La cita abre el lector.
    await _tap(tester, find.byKey(const ValueKey('assistant-ref-0')));
    expect(_tab(container, PanelKind.bible)?.reference, 'JHN.1.1');

    // Recientes repite una pregunta anterior.
    _activate(container, PanelKind.studyAssistant);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('assistant-recents')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(PopupMenuItem<String>),
      matching: find.text('¿Qué enseña Juan 1 sobre el Verbo?'),
    ));
    await tester.pumpAndSettle();
    expect(engine.questions.length, 2);
    expect(find.text('Respuesta de prueba con una cita.'), findsNWidgets(2));

    // «Copiar todo» deja la conversación en el portapapeles.
    await _tap(tester, find.byKey(const ValueKey('assistant-copy')));
    expect(find.text('Conversación copiada.'), findsOneWidget);

    // El alcance se puede cambiar y llega al proveedor.
    await tester.tap(find.byKey(const ValueKey('assistant-scope')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(PopupMenuItem<AssistantScope>),
      matching: find.text('La Biblia'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('La Biblia'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('assistant-input')), '¿Quién es Melquisedec?');
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('assistant-send')));
    expect(engine.lastScope, AssistantScope.bible);
    expect(engine.questions.last, '¿Quién es Melquisedec?');

    // «Nuevo» vacía la conversación.
    await _tap(tester, find.byKey(const ValueKey('assistant-new')));
    expect(find.text('Respuesta de prueba con una cita.'), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('un fallo del proveedor se avisa en el chat', (tester) async {
    final container = await _pump(tester, engine: _FakeEngine(fail: true));

    await tester.enterText(
        find.byKey(const ValueKey('assistant-input')), '¿Quién es Melquisedec?');
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('assistant-send')));
    expect(find.text('No se pudo obtener respuesta del proveedor.'),
        findsOneWidget);
    expect(_tab(container, PanelKind.studyAssistant), isNotNull);
  });
}
