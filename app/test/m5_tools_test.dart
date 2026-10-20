// Herramientas de M5: Devocional del día, Factbook, Comparación de textos y
// diseños guardados.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/catalog_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/catalog/sections_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/maps/bible_map.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

void _setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

ProviderContainer _container({
  List<ResourceSummary>? resources,
  FakeSectionsRepository? sections,
}) =>
    ProviderContainer(
      overrides: [
        workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
        notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
        catalogGatewayProvider.overrideWithValue(
            FakeCatalogGateway(resources: resources ?? testResources)),
        documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
        sectionsRepositoryProvider
            .overrideWithValue(sections ?? FakeSectionsRepository()),
        mapGeometryProvider.overrideWith(
          (ref) => const MapGeometry(land: [], lakes: []),
        ),
      ],
    );

Future<ProviderContainer> _pump(
  WidgetTester tester,
  TabSpec? spec, {
  List<ResourceSummary>? resources,
  FakeSectionsRepository? sections,
}) async {
  _setWindow(tester, const Size(1400, 900));
  final container = _container(resources: resources, sections: sections);
  addTearDown(container.dispose);
  if (spec != null) {
    container.read(workspaceProvider.notifier).openTab(spec);
  }
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const AletheiaApp(),
  ));
  await tester.pumpAndSettle();
  return container;
}

bool _hasBibleTab(ProviderContainer container, String reference) {
  for (final tile in container.read(workspaceProvider).tiles) {
    for (final tab in tile.tabs) {
      if (tab.kind == PanelKind.bible && tab.reference == reference) {
        return true;
      }
    }
  }
  return false;
}

void main() {
  // ------------------------------------------------------------- devocional

  group('Devocional del día', () {
    testWidgets('muestra la lectura de hoy y navega por días', (tester) async {
      final sections = FakeSectionsRepository();
      final container = await _pump(
        tester,
        const TabSpec(kind: PanelKind.devotional),
        sections: sections,
      );

      expect(find.text('Contenido devocional de prueba.'), findsOneWidget);
      expect(sections.sectionCalls.single,
          startsWith('devotional.daily/dayofyear.'));
      final firstId = sections.sectionCalls.single.split('/').last;

      final labelBefore = tester
          .widget<Text>(find.byKey(const ValueKey('devotional-date')))
          .data!;

      await tester.tap(find.byKey(const ValueKey('devotional-next')));
      await tester.pumpAndSettle();
      final secondId = sections.sectionCalls.last.split('/').last;
      expect(secondId, isNot(firstId));
      final labelAfter = tester
          .widget<Text>(find.byKey(const ValueKey('devotional-date')))
          .data!;
      expect(labelAfter, isNot(labelBefore));

      await tester.tap(find.byKey(const ValueKey('devotional-today')));
      await tester.pumpAndSettle();
      final labelBack = tester
          .widget<Text>(find.byKey(const ValueKey('devotional-date')))
          .data!;
      expect(labelBack, labelBefore);

      // El enlace del pasaje abre el lector en la referencia.
      await tester.tap(find.byKey(const ValueKey('devotional-open-passage')));
      await tester.pumpAndSettle();
      expect(_hasBibleTab(container, 'JHN.1.1'), isTrue);
    });
  });

  // --------------------------------------------------------------- factbook

  group('Factbook', () {
    testWidgets('lista temas, abre un artículo y navega a los relacionados',
        (tester) async {
      final container = await _pump(
        tester,
        const TabSpec(kind: PanelKind.factbook),
      );

      expect(find.text('Gracia'), findsOneWidget);
      expect(find.text('Fe'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('factbook-topic-gracia')));
      await tester.pumpAndSettle();
      expect(
          find.text('La gracia es el favor que Dios concede.'), findsOneWidget);
      expect(find.text('Efesios 2:8'), findsOneWidget);
      expect(find.byKey(const ValueKey('factbook-related-fe')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('factbook-related-fe')));
      await tester.pumpAndSettle();
      expect(find.text('La fe responde a lo que Dios ha mostrado.'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('bible-map')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('map-marker-Belén')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('factbook-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('factbook-topics')), findsOneWidget);

      // Una referencia bíblica sin tema ofrece abrir el pasaje en el lector.
      await tester.enterText(
          find.byKey(const ValueKey('factbook-search')), 'Juan 1:1');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('factbook-open-passage')));
      await tester.pumpAndSettle();
      expect(_hasBibleTab(container, 'JHN.1.1'), isTrue);
    });

    testWidgets('la búsqueda y las lentes filtran los temas', (tester) async {
      await _pump(tester, const TabSpec(kind: PanelKind.factbook));

      await tester.enterText(
          find.byKey(const ValueKey('factbook-search')), 'xyz');
      await tester.pumpAndSettle();
      expect(find.text('No se encontraron temas'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('factbook-clear')));
      await tester.pumpAndSettle();
      expect(find.text('Gracia'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('factbook-lens-theology')));
      await tester.pumpAndSettle();
      expect(find.text('Gracia'), findsOneWidget);
      expect(find.text('Fe'), findsNothing);
    });
  });

  // ------------------------------------------------------ comparación

  group('Comparación de textos', () {
    testWidgets('compara dos versiones con porcentaje y referencia',
        (tester) async {
      final container = await _pump(
        tester,
        const TabSpec(kind: PanelKind.textComparison),
        resources: [testResources.first, testKjv],
      );

      expect(find.text('RV1909'), findsNWidgets(2));
      expect(find.text('KJV'), findsNWidgets(2));
      expect(find.text('Juan 1:1'), findsOneWidget);
      expect(find.text('Juan 1:2'), findsOneWidget);
      // El porcentaje va en línea dentro del texto enriquecido: la base lo
      // muestra (0 %) y la KJV lo omite por ser otro idioma.
      expect(find.textContaining('0% de diferencia', findRichText: true),
          findsNWidgets(2));
      expect(find.textContaining('% de diferencia', findRichText: true),
          findsNWidgets(2));
      expect(find.textContaining('In the beginning', findRichText: true),
          findsOneWidget);
      expect(find.byKey(const ValueKey('compare-single-version')),
          findsNothing);

      await tester.tap(find.byKey(const ValueKey('compare-verse-1')));
      await tester.pumpAndSettle();
      expect(_hasBibleTab(container, 'JHN.1.1'), isTrue);
    });

    testWidgets('cambia de referencia y permite quitar una versión',
        (tester) async {
      await _pump(
        tester,
        const TabSpec(kind: PanelKind.textComparison),
        resources: [testResources.first, testKjv],
      );

      await tester.enterText(
          find.byKey(const ValueKey('compare-reference')), 'JHN.2');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.textContaining('Y al tercer día…', findRichText: true),
          findsOneWidget);
      expect(find.text('No disponible en esta versión.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('compare-versions-button')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('compare-version-bible.kjv')));
      await tester.pumpAndSettle();
      // Cerrar el menú tocando fuera y comprobar el aviso de una sola versión.
      await tester.tapAt(const Offset(6, 6));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('compare-single-version')),
          findsOneWidget);
      expect(find.text('KJV'), findsNothing);
    });
  });

  // -------------------------------------------------------- diseños

  group('Diseños guardados', () {
    test('guardar, aplicar y eliminar conserva los paneles', () {
      final container = ProviderContainer(overrides: [
        workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
      ]);
      addTearDown(container.dispose);
      final ctrl = container.read(workspaceProvider.notifier);

      ctrl.openTab(const TabSpec(
        kind: PanelKind.bible,
        reference: 'JHN.1.1',
        resourceId: 'bible.rv1909',
      ));
      ctrl.saveCurrentLayout('Estudio de Juan');
      final saved = container.read(workspaceProvider).savedLayouts.single;
      expect(saved.name, 'Estudio de Juan');
      expect(saved.tiles.any((tile) => tile.tabs.isNotEmpty), isTrue);

      ctrl.closeAllTabs();
      expect(
        container.read(workspaceProvider).tiles.every((tile) => tile.tabs.isEmpty),
        isTrue,
      );

      expect(ctrl.applySavedLayout(saved.id), isTrue);
      final restored = container.read(workspaceProvider);
      expect(restored.tiles.any((tile) => tile.tabs.isNotEmpty), isTrue);
      expect(
        restored.tiles
            .expand((tile) => tile.tabs)
            .any((tab) => tab.reference == 'JHN.1.1'),
        isTrue,
      );

      ctrl.deleteSavedLayout(saved.id);
      expect(container.read(workspaceProvider).savedLayouts, isEmpty);
    });

    testWidgets('el menú lateral guarda el diseño actual', (tester) async {
      final container = await _pump(tester, null);

      await tester.tap(find.byKey(const ValueKey('layouts-menu-sidebar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('layout-save-current')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('layout-name-field')), 'Sermón dominical');
      await tester.tap(find.byKey(const ValueKey('layout-save-confirm')));
      await tester.pumpAndSettle();

      expect(container.read(workspaceProvider).savedLayouts.single.name,
          'Sermón dominical');
      expect(find.text('Diseño guardado'), findsOneWidget);

      // El diseño guardado aparece en el menú para volver a aplicarlo.
      await tester.tap(find.byKey(const ValueKey('layouts-menu-sidebar')));
      await tester.pumpAndSettle();
      expect(find.text('Sermón dominical'), findsOneWidget);
    });
  });
}
