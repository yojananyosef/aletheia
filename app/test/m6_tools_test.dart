// M6.4: Atlas, Medios, Cursos, Documentos, Favoritos y Explorador de Salmos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/catalog/sections_repository.dart';
import 'package:aletheia/favorites/favorites_controller.dart';
import 'package:aletheia/favorites/favorites_models.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/maps/bible_map.dart';
import 'package:aletheia/maps/visual_sections.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/shell/sidebar_state.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

const _visualCatalog = VisualSectionCatalog(
  maps: [
    VisualSectionEntry(
      resource: 'factbook.core',
      resourceTitle: 'Factbook de prueba',
      section: 'fe',
      title: 'Belén y Jerusalén',
      caption: 'Mapa de prueba del Factbook.',
    ),
  ],
  media: [
    VisualSectionEntry(
      resource: 'factbook.core',
      resourceTitle: 'Factbook de prueba',
      section: 'fe',
      title: 'Belén y Jerusalén',
      caption: 'Mapa de prueba del Factbook.',
    ),
  ],
  journeys: [
    VisualJourney(
      id: 'pablo-01',
      title: 'Primer viaje de Pablo',
      order: 1,
      caption: 'De Antioquía a Chipre y Galacia.',
      refs: ['ACT.13.1', 'ACT.14.26'],
      stops: [
        MapMarker(name: 'Antioquía', lat: 36.2, lon: 36.16, ref: 'ACT.13.1'),
        MapMarker(name: 'Pafos', lat: 34.77, lon: 32.42, ref: 'ACT.13.6'),
        MapMarker(name: 'Derbe', lat: 37.4, lon: 33.51, ref: 'ACT.14.6'),
      ],
    ),
  ],
);

void _setWindow(WidgetTester tester, [Size size = const Size(1400, 900)]) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

ProviderContainer _container() => ProviderContainer(
  overrides: [
    workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
    notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
    catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
    documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
    sectionsRepositoryProvider.overrideWithValue(FakeSectionsRepository()),
    mapGeometryProvider.overrideWith(
      (ref) => const MapGeometry(land: [], lakes: []),
    ),
    visualSectionsProvider.overrideWith((ref) async => _visualCatalog),
  ],
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  PanelKind kind, {
  Size size = const Size(1400, 900),
}) async {
  _setWindow(tester, size);
  final container = _container();
  addTearDown(container.dispose);
  container.read(workspaceProvider.notifier).openTab(TabSpec(kind: kind));
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AletheiaApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
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
  testWidgets('Atlas lista y abre un mapa del catálogo', (tester) async {
    final container = await _pump(tester, PanelKind.atlas);

    expect(find.text('Belén y Jerusalén'), findsOneWidget);
    await _tap(
      tester,
      find.byKey(const ValueKey('atlas-entry-factbook.core-fe')),
    );
    expect(find.byKey(const ValueKey('atlas-detail-back')), findsOneWidget);
    expect(find.text('Mapa de prueba del Factbook.'), findsWidgets);
    expect(find.byType(BibleMap), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('atlas-favorite')));
    expect(container.read(favoritesProvider).single.kind, FavoriteKind.map);
    expect(container.read(favoritesProvider).single.reference, 'fe');
  });

  testWidgets('Atlas dibuja un viaje con flechas y abre la lectura', (
    tester,
  ) async {
    final container = await _pump(tester, PanelKind.atlas);

    // La ruta va primera en la lista del Atlas, con su icono propio.
    expect(find.text('Primer viaje de Pablo'), findsOneWidget);
    await _tap(
      tester,
      find.byKey(const ValueKey('atlas-entry-atlas-pablo-01')),
    );
    expect(find.byKey(const ValueKey('journey-detail-back')), findsOneWidget);
    expect(find.byType(BibleMap), findsOneWidget);
    expect(find.byKey(const ValueKey('map-route-layer')), findsOneWidget);
    expect(find.text('De Antioquía a Chipre y Galacia.'), findsWidgets);

    // Favorito del viaje: entra y sale con la misma operación.
    await _tap(tester, find.byKey(const ValueKey('journey-favorite')));
    expect(
      container.read(favoritesProvider).where(
        (favorite) =>
            favorite.kind == FavoriteKind.map &&
            favorite.resourceId == 'atlas' &&
            favorite.reference == 'pablo-01',
      ),
      hasLength(1),
    );

    // La lectura sugerida abre el recurso bíblico en el mismo pasaje (el
    // panel del Atlas se desmonta al enfocar la pestaña del texto).
    await _tap(tester, find.byKey(const ValueKey('journey-ref-ACT.13.1')));
    final opened = container
        .read(workspaceProvider)
        .tiles
        .expand((tile) => tile.tabs)
        .where((tab) => tab.resourceId == 'bible.platense')
        .toList();
    expect(opened, hasLength(1));
    expect(opened.single.reference, 'ACT.13.1');
  });

  testWidgets('Medios muestra la galería y abre el detalle', (tester) async {
    await _pump(tester, PanelKind.media);

    expect(find.byKey(const ValueKey('media-gallery')), findsOneWidget);
    await _tap(
      tester,
      find.byKey(const ValueKey('media-entry-factbook.core-fe')),
    );
    expect(find.byKey(const ValueKey('media-detail-back')), findsOneWidget);
    expect(find.byType(BibleMap), findsOneWidget);
  });

  testWidgets('Cursos abre una lección en el lector', (tester) async {
    final container = await _pump(tester, PanelKind.courses);

    await _tap(tester, find.byKey(const ValueKey('course-card-panorama')));
    expect(find.byKey(const ValueKey('course-progress')), findsOneWidget);
    await _tap(
      tester,
      find.byKey(const ValueKey('course-lesson-read-panorama/creation')),
    );
    expect(_tab(container, PanelKind.bible)?.reference, 'GEN.1.1');
  });

  testWidgets('Documentos abre una guía propia', (tester) async {
    await _pump(tester, PanelKind.documents);

    await _tap(tester, find.byKey(const ValueKey('documents-card-reading')));
    expect(find.byKey(const ValueKey('documents-body')), findsOneWidget);
    expect(find.textContaining('La Biblia es una biblioteca'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Favoritos añade, abre y quita un pasaje', (tester) async {
    final container = await _pump(tester, PanelKind.favorites);

    await tester.enterText(
      find.byKey(const ValueKey('favorites-add-reference')),
      'Juan 3:16',
    );
    await _tap(tester, find.byKey(const ValueKey('favorites-add-button')));

    final favorites = container.read(favoritesProvider);
    expect(favorites, hasLength(1));
    expect(favorites.single.reference, 'JHN.3.16');
    expect(find.text('Juan 3:16'), findsOneWidget);

    final id = favorites.single.id;
    await _tap(tester, find.byKey(ValueKey('favorite-open-$id')));
    expect(_tab(container, PanelKind.bible)?.reference, 'JHN.3.16');

    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.favorites));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(ValueKey('favorite-remove-$id')));
    expect(container.read(favoritesProvider), isEmpty);
  });

  testWidgets('la estrella del lector guarda y quita el pasaje', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    _setWindow(tester);
    container
        .read(workspaceProvider.notifier)
        .openTab(
          const TabSpec(
            kind: PanelKind.bible,
            reference: 'JHN.1.1',
            resourceId: 'bible.rv1909',
          ),
        );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AletheiaApp(),
      ),
    );
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const ValueKey('reader-favorite')));
    expect(container.read(favoritesProvider), hasLength(1));
    expect(container.read(favoritesProvider).single.reference, 'JHN.1.1');

    await _tap(tester, find.byKey(const ValueKey('reader-favorite')));
    expect(container.read(favoritesProvider), isEmpty);
  });

  testWidgets('Explorador de Salmos filtra y abre un salmo', (tester) async {
    final container = await _pump(tester, PanelKind.psalmsExplorer);

    expect(find.byKey(const ValueKey('psalms-grid')), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('psalms-category-trust')));
    expect(find.byKey(const ValueKey('psalm-23')), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('psalm-23')));
    expect(_tab(container, PanelKind.bible)?.reference, 'PSA.23');
  });

  testWidgets('Favoritos conserva el tipo de un mapa', (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    container
        .read(favoritesProvider.notifier)
        .add(
          kind: FavoriteKind.map,
          title: 'Belén y Jerusalén',
          resourceId: 'factbook.core',
          reference: 'fe',
        );
    expect(container.read(favoritesProvider).single.kind, FavoriteKind.map);
  });

  testWidgets('en móvil el menú pliega la barra lateral', (tester) async {
    _setWindow(tester, const Size(390, 844));
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AletheiaApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(sidebarCollapsedProvider.notifier).setCollapsed(false);
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const ValueKey('tools-menu-sidebar')));
    await _tap(tester, find.byKey(const ValueKey('tool-atlas')));
    expect(container.read(sidebarCollapsedProvider), isTrue);
    expect(_tab(container, PanelKind.atlas), isNotNull);
    expect(tester.takeException(), isNull);
  });

  for (final kind in const [
    PanelKind.atlas,
    PanelKind.courses,
    PanelKind.documents,
    PanelKind.favorites,
    PanelKind.media,
    PanelKind.psalmsExplorer,
  ]) {
    testWidgets('${kind.name} no desborda en móvil', (tester) async {
      await _pump(tester, kind, size: const Size(390, 844));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });
  }
}
