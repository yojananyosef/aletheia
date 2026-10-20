/// Lector genérico de contenido: comentario y diccionario desde el catálogo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/catalog/sections_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/maps/bible_map.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

class _ContentSections implements SectionsRepository {
  static final _commentary = [
    SectionSummary.fromJson({
      'id': 'JHN.3',
      'title': 'John 3',
      'summary': 'Nicodemus and the new birth.',
      'reference': 'JHN.3',
      'referenceLabel': 'John 3',
      'tags': ['Comentario', 'Matthew Henry'],
    }),
    SectionSummary.fromJson({
      'id': 'GEN.1',
      'title': 'Genesis 1',
      'summary': 'The creation.',
      'reference': 'GEN.1',
      'referenceLabel': 'Genesis 1',
      'tags': ['Comentario', 'Matthew Henry'],
    }),
  ];

  static final _dictionary = [
    SectionSummary.fromJson({
      'id': 'grace',
      'title': 'Grace',
      'summary': 'Favor, kindness.',
      'tags': ['Diccionario', 'Easton'],
    }),
  ];

  @override
  Future<List<SectionSummary>> loadIndex(String resourceId) async {
    if (resourceId == 'commentary.test') return _commentary;
    if (resourceId == 'dictionary.test') return _dictionary;
    return const [];
  }

  @override
  Future<CatalogSection?> loadSection(
    String resourceId,
    String sectionId,
  ) async {
    if (resourceId == 'commentary.test' && sectionId == 'JHN.3') {
      return CatalogSection.fromJson({
        'id': 'JHN.3',
        'title': 'John 3',
        'reference': 'JHN.3',
        'blocks': [
          {'type': 'heading', 'text': 'Verses 1–8', 'style': 'section'},
          {
            'type': 'paragraph',
            'inlines': [
              {
                't': 'text',
                'v': 'Nicodemus came to Jesus by night and heard of the new birth.',
              },
            ],
          },
          {
            'type': 'map',
            'title': 'Jerusalén en el siglo I',
            'center': [31.78, 35.23],
            'latSpan': 0.8,
            'lonSpan': 0.9,
            'markers': [
              {'name': 'Jerusalén', 'lat': 31.776667, 'lon': 35.234167,
               'ref': 'JHN.3.1'},
            ],
          },
        ],
      });
    }
    if (resourceId == 'dictionary.test' && sectionId == 'grace') {
      return CatalogSection.fromJson({
        'id': 'grace',
        'title': 'Grace',
        'blocks': [
          {
            'type': 'paragraph',
            'inlines': [
              {
                't': 'text',
                'v': 'Grace is the free favor of God toward sinners.',
              },
            ],
          },
        ],
      });
    }
    return null;
  }
}

Future<ProviderContainer> _pump(WidgetTester tester, TabSpec tab) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1400, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final container = ProviderContainer(
    overrides: [
      workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
      notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
      catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
      documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
      sectionsRepositoryProvider.overrideWithValue(_ContentSections()),
      mapGeometryProvider.overrideWith(
        (ref) => const MapGeometry(land: [], lakes: []),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(workspaceProvider.notifier).openTab(tab);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const AletheiaApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('el comentario muestra su índice y abre el pasaje', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      const TabSpec(
        kind: PanelKind.resource,
        title: 'Matthew Henry',
        reference: 'JHN.3',
        resourceId: 'commentary.test',
        resourceType: 'commentary',
      ),
    );

    expect(
      find.byKey(const ValueKey('catalog-resource-detail')),
      findsOneWidget,
    );
    expect(find.text('Verses 1–8'), findsOneWidget);
    expect(
      find.text('Nicodemus came to Jesus by night and heard of the new birth.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('bible-map')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-marker-Jerusalén')),
      findsOneWidget,
    );
    // El resumen vive en el índice; el detalle no lo repite.
    expect(find.text('Nicodemus and the new birth.'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('catalog-resource-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('catalog-resource-index')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('catalog-resource-detail')), findsNothing);
    expect(find.byKey(const ValueKey('catalog-entry-GEN.1')), findsOneWidget);
    // El título y la etiqueta de referencia no se duplican en la fila.
    expect(find.text('John 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('catalog-entry-JHN.3')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const ValueKey('catalog-open-passage')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    var reference = '';
    for (final tile in container.read(workspaceProvider).tiles) {
      for (final tab in tile.tabs) {
        if (tab.kind == PanelKind.bible) reference = tab.reference ?? '';
      }
    }
    expect(reference, 'JHN.3');
  });

  testWidgets('el diccionario filtra por título y muestra la entrada', (
    tester,
  ) async {
    await _pump(
      tester,
      const TabSpec(
        kind: PanelKind.resource,
        title: 'Easton',
        resourceId: 'dictionary.test',
        resourceType: 'dictionary',
      ),
    );

    expect(
      find.byKey(const ValueKey('catalog-resource-index')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('catalog-entry-grace')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('catalog-resource-filter')),
      'gra',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('catalog-entry-grace')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('catalog-entry-grace')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('catalog-resource-detail')),
      findsOneWidget,
    );
    expect(
      find.text('Grace is the free favor of God toward sinners.'),
      findsOneWidget,
    );
  });
}
