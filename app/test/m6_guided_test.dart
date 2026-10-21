// M6.3: Estudio guiado (guías y flujos propios) y menú de Herramientas.
library;

import 'package:flutter/material.dart';
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

/// Sin secciones propias en estas pruebas: el Factbook abre con su estado
/// vacío en lugar de intentar leer assets.
class _EmptySections implements SectionsRepository {
  const _EmptySections();

  @override
  Future<List<SectionSummary>> loadIndex(String resourceId) async => const [];

  @override
  Future<CatalogSection?> loadSection(String resourceId, String sectionId) async =>
      null;
}

void _setWindow(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1500, 950);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<ProviderContainer> _pump(WidgetTester tester) async {
  _setWindow(tester);
  final container = ProviderContainer(
    overrides: [
      workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
      notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
      catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
      documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
      sectionsRepositoryProvider.overrideWithValue(const _EmptySections()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const AletheiaApp(),
  ));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Reactiva la primera pestaña del tipo dado (las acciones de un paso pueden
/// activar otra pestaña del mismo tile).
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
  // ------------------------------------------------------- menú de herramientas

  testWidgets('Herramientas abre su menú y las herramientas reales',
      (tester) async {
    final container = await _pump(tester);

    await _tap(tester, find.byKey(const ValueKey('tools-menu-sidebar')));
    expect(find.text('Atlas'), findsOneWidget);
    expect(find.text('Cursos'), findsOneWidget);
    expect(find.text('Documentos'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Medios'), findsOneWidget);
    expect(find.text('Explorador de Salmos'), findsOneWidget);
    expect(find.text('Planes de lectura'), findsOneWidget);
    // Todas las filas abren una herramienta real.
    final atlas = tester.widget<PopupMenuItem<String>>(
      find.byKey(const ValueKey('tool-atlas')),
    );
    expect(atlas.enabled, isTrue);
    expect(find.text('Pronto'), findsNothing);

    await _tap(tester, find.byKey(const ValueKey('tool-atlas')));
    expect(_tab(container, PanelKind.atlas), isNotNull);

    await _tap(tester, find.byKey(const ValueKey('tools-menu-sidebar')));
    await _tap(tester, find.byKey(const ValueKey('tool-factbook')));
    expect(_tab(container, PanelKind.factbook), isNotNull);

    await _tap(tester, find.byKey(const ValueKey('tools-menu-sidebar')));
    await _tap(tester, find.byKey(const ValueKey('tool-compare')));
    expect(_tab(container, PanelKind.textComparison), isNotNull);
  });

  // ------------------------------------------------------------ estudio guiado

  testWidgets('Estudio guiado: guías, flujos y búsqueda', (tester) async {
    final container = await _pump(tester);
    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.guidedStudy));
    await tester.pumpAndSettle();

    expect(find.text('GUÍAS'), findsOneWidget);
    expect(find.text('FLUJOS DE TRABAJO'), findsOneWidget);
    expect(find.text('Estudio de palabras bíblicas'), findsOneWidget);
    expect(find.text('Guía exegética'), findsOneWidget);
    expect(find.text('Guía de pasajes'), findsOneWidget);
    expect(find.text('Guía para sermones'), findsOneWidget);
    expect(find.text('Estudio bíblico básico'), findsOneWidget);
    expect(find.text('Estudio bíblico inductivo'), findsOneWidget);
    expect(find.text('Lectio divina'), findsOneWidget);

    // La caja Find filtra ambas secciones.
    await tester.enterText(find.byKey(const ValueKey('guided-find')), 'lectio');
    await tester.pumpAndSettle();
    expect(find.text('Lectio divina'), findsOneWidget);
    expect(find.text('Guía exegética'), findsNothing);
    expect(find.text('GUÍAS'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('guided-find')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('Ninguna guía coincide'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('guided-find')), '');
    await tester.pumpAndSettle();
    expect(find.text('Guía exegética'), findsOneWidget);
  });

  testWidgets('una guía genera sus pasos y abre las herramientas',
      (tester) async {
    final container = await _pump(tester);
    container.read(workspaceProvider.notifier).openTab(const TabSpec(
          kind: PanelKind.bible,
          reference: 'EPH.2.8',
          resourceId: 'bible.rv1909',
        ));
    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.guidedStudy));
    await tester.pumpAndSettle();

    // Estudio de palabras bíblicas: pide la palabra.
    await _tap(tester, find.byKey(const ValueKey('guide-word')));
    expect(find.text('Palabra'), findsOneWidget);
    expect(find.text('Lee el pasaje completo'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('guide-param')), 'gracia');
    await tester.pumpAndSettle();
    expect(find.textContaining('«gracia»'), findsOneWidget);

    // Buscar en el catálogo abre el panel de búsqueda con la consulta.
    await _tap(tester, find.byKey(const ValueKey('guide-step-action-1')));
    expect(_tab(container, PanelKind.search)?.query, 'gracia');

    // Marcar un paso lo tacha y volver atrás devuelve al listado.
    await _tap(tester, find.byKey(const ValueKey('guide-step-done-0')));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('guide-back')));
    expect(find.text('GUÍAS'), findsOneWidget);
    // Deja correr el guardado diferido del workspace.
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('un flujo usa la referencia del lector', (tester) async {
    final container = await _pump(tester);
    container.read(workspaceProvider.notifier).openTab(const TabSpec(
          kind: PanelKind.bible,
          reference: 'EPH.2.8',
          resourceId: 'bible.rv1909',
        ));
    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.guidedStudy));
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const ValueKey('guide-basic')));
    // El parámetro se precarga con la referencia activa.
    expect(find.widgetWithText(TextField, 'EPH.2.8'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('guide-step-action-1')));
    expect(_tab(container, PanelKind.bible)?.reference, 'EPH.2.8');

    // El paso de interpretación abre Temas con el pasaje.
    _activate(container, PanelKind.guidedStudy);
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('guide-step-action-3')));
    expect(_tab(container, PanelKind.factbook)?.query, 'EPH.2.8');
    await tester.pump(const Duration(milliseconds: 500));
  });
}
