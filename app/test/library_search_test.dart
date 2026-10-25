import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_client.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/catalog_models.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/catalog/sections_repository.dart';
import 'package:aletheia/library/library_overlay.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';
import 'package:aletheia/notes/notes_persistence.dart';

import 'support/test_fakes.dart';

// --------------------------------------------------------------- utilidades

Widget _app(ProviderContainer container) =>
    UncontrolledProviderScope(container: container, child: const AletheiaApp());

ProviderContainer _container(
  CatalogGateway gateway, {
  SectionsRepository? sections,
}) => ProviderContainer(
  overrides: [
    workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
    notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
    catalogGatewayProvider.overrideWithValue(gateway),
    documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
    if (sections != null)
      sectionsRepositoryProvider.overrideWithValue(sections),
  ],
);

void _setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

List<WorkspaceTab> _tabs(ProviderContainer container) =>
    container.read(workspaceProvider).tiles.expand((t) => t.tabs).toList();

WorkspaceTab _tabOfKind(ProviderContainer container, PanelKind kind) =>
    _tabs(container).firstWhere((t) => t.kind == kind);

class _LibrarySections implements SectionsRepository {
  @override
  Future<List<SectionSummary>> loadIndex(String resourceId) async => [
    SectionSummary.fromJson({
      'id': 'JHN.3',
      'title': 'John 3',
      'summary': 'Nicodemus and the new birth.',
      'reference': 'JHN.3',
      'referenceLabel': 'John 3',
    }),
  ];

  @override
  Future<CatalogSection?> loadSection(
    String resourceId,
    String sectionId,
  ) async => CatalogSection.fromJson({
    'id': sectionId,
    'title': 'John 3',
    'reference': 'JHN.3',
    'blocks': [
      {
        'type': 'paragraph',
        'inlines': [
          {'t': 'text', 'v': 'Nicodemus came to Jesus by night.'},
        ],
      },
    ],
  });
}

void main() {
  // El clon tiene el español como idioma de diseño: se fija el idioma de la
  // plataforma para que las expectativas de los textos no dependan del
  // entorno (M3).
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];
  testWidgets('biblioteca: lista, filtros por faceta y abre la Biblia', (
    tester,
  ) async {
    _setWindow(tester, const Size(1500, 900));
    final gateway = FakeCatalogGateway();
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-list')), findsOneWidget);
    expect(find.text('2 recursos'), findsOneWidget);
    expect(find.text('Reina-Valera 1909'), findsOneWidget);
    expect(find.text('Comentario de prueba'), findsOneWidget);
    expect(
      find.text('Biblia · Reina, Casiodoro de; Valera, Cipriano de'),
      findsOneWidget,
    );

    // Faceta por tipo: solo el comentario.
    await tester.tap(find.byKey(const ValueKey('facet-type-commentary')));
    await tester.pumpAndSettle();
    expect(find.text('Comentario de prueba'), findsOneWidget);
    expect(find.text('Reina-Valera 1909'), findsNothing);
    expect(find.text('1 recurso'), findsOneWidget);

    // Limpiar filtros y probar las facetas de tema y editorial.
    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();
    find.text('2 recursos');

    await tester.tap(find.byKey(const ValueKey('facet-subject-Comentario')));
    await tester.pumpAndSettle();
    expect(find.text('Comentario de prueba'), findsOneWidget);
    expect(find.text('Reina-Valera 1909'), findsNothing);

    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('facet-publisher-Sociedad Bíblica de prueba')));
    await tester.pumpAndSettle();
    expect(find.text('Reina-Valera 1909'), findsOneWidget);
    expect(find.text('Comentario de prueba'), findsNothing);

    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('2 recursos'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-row-bible.rv1909')));
    // La fila distingue toque simple y doble: hay que agotar la ventana.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-detail')), findsOneWidget);
    expect(find.textContaining('31'), findsWidgets); // 31 102 versículos

    await tester.tap(find.byKey(const ValueKey('library-open')));
    await tester.pumpAndSettle();

    expect(container.read(libraryOverlayVisibleProvider), isFalse);
    final bible = _tabOfKind(container, PanelKind.bible);
    expect(bible.resourceId, 'bible.rv1909');
    expect(bible.reference, 'GEN.1.1');
    expect(
      find.textContaining('Texto de Génesis 1:1', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('biblioteca abre el comentario en el panel de recursos', (
    tester,
  ) async {
    _setWindow(tester, const Size(1500, 900));
    final gateway = FakeCatalogGateway();
    final container = _container(gateway, sections: _LibrarySections());
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('library-row-commentary.test')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('library-open')));
    await tester.pumpAndSettle();
    // Agota el debounce de persistencia del workspace.
    await tester.pump(const Duration(milliseconds: 500));

    final tab = _tabOfKind(container, PanelKind.resource);
    expect(tab.resourceId, 'commentary.test');
    expect(tab.title, 'Comentario de prueba');
    expect(
      find.byKey(const ValueKey('catalog-resource-index')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('catalog-entry-JHN.3')), findsOneWidget);
  });

  testWidgets(
    'biblioteca en ventana estrecha: el detalle sustituye a la lista',
    (tester) async {
      _setWindow(tester, const Size(764, 900));
      final gateway = FakeCatalogGateway();
      final container = _container(gateway);
      addTearDown(container.dispose);
      addTearDown(gateway.client.close);

      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-library')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('library-row-bible.rv1909')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('library-detail')), findsOneWidget);
      expect(find.byKey(const ValueKey('library-list')), findsNothing);
      expect(find.text('Volver a la lista'), findsOneWidget);

      await tester.tap(find.text('Volver a la lista'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library-list')), findsOneWidget);
      expect(find.byKey(const ValueKey('library-detail')), findsNothing);
    },
  );

  testWidgets('biblioteca: si el catálogo falla muestra reintento', (
    tester,
  ) async {
    _setWindow(tester, const Size(1500, 900));
    final gateway = FakeCatalogGateway(
      listError: CatalogException('no se pudo conectar con el catálogo'),
    );
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo consultar el catálogo'), findsOneWidget);

    gateway.listError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('2 recursos'), findsOneWidget);
  });

  testWidgets('búsqueda: consulta, resultados, historial y apertura', (
    tester,
  ) async {
    _setWindow(tester, const Size(1500, 900));
    final gateway = FakeCatalogGateway(
      searchResult: SearchResult(
        query: 'Verbo',
        scope: 'all',
        total: 2,
        page: 1,
        pageSize: 20,
        hits: [
          testHit(
            'JHN.1.1',
            'Juan 1:1',
            'EN el principio era el <em>Verbo</em>, y el <em>Verbo</em> era con Dios.',
          ),
          testHit(
            'JHN.1.14',
            'Juan 1:14',
            'Y aquel <em>Verbo</em> fué hecho carne.',
          ),
        ],
      ),
    );
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    // La consulta llega como `query` de la pestaña (p. ej. desde el omnibox).
    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.search, query: 'Verbo'));

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 resultados'), findsOneWidget);
    expect(find.text('Juan 1:1'), findsOneWidget);
    expect(find.text('Juan 1:14'), findsOneWidget);
    expect(gateway.searchCalls, ['Verbo|all']);

    // Segunda consulta → historial con dos entradas.
    await tester.enterText(
      find.byKey(const ValueKey('search-field')),
      'principio',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    var searchTab = _tabOfKind(container, PanelKind.search);
    expect(gateway.searchCalls.last, 'principio|all');
    expect(searchTab.history, ['Verbo', 'principio']);
    expect(searchTab.historyIndex, 1);

    // Atrás vuelve a la consulta anterior y la reejecuta.
    await tester.tap(find.byKey(const ValueKey('search-back')));
    await tester.pumpAndSettle();
    searchTab = _tabOfKind(container, PanelKind.search);
    expect(searchTab.query, 'Verbo');
    expect(gateway.searchCalls.last, 'Verbo|all');
    expect(find.textContaining('2 resultados'), findsOneWidget);

    // Ámbito Biblia.
    await tester.tap(find.byKey(const ValueKey('scope-bible')));
    await tester.pumpAndSettle();
    expect(gateway.searchCalls.last, 'Verbo|bible');

    // Abrir un resultado navega el lector (crea la pestaña si no existe).
    await tester.tap(
      find.byKey(const ValueKey('search-hit-bible.rv1909-JHN.1.1')),
    );
    await tester.pumpAndSettle();

    final bible = _tabOfKind(container, PanelKind.bible);
    expect(bible.resourceId, 'bible.rv1909');
    expect(bible.reference, 'JHN.1.1');
    expect(
      find.textContaining('EN el principio era el Verbo.', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('búsqueda: filtros, grupos y salto a Factbook y devocional', (
    tester,
  ) async {
    _setWindow(tester, const Size(1500, 900));
    final gateway = FakeCatalogGateway(
      searchResult: SearchResult(
        query: 'Verbo',
        scope: 'all',
        total: 3,
        page: 1,
        pageSize: 20,
        facets: const {
          'type': {'bible': 1, 'factbook': 1, 'devotional': 1},
          'language': {'es': 1},
          'book': {'JHN': 1},
        },
        hits: [
          testHit(
            'JHN.1.1',
            'Juan 1:1',
            'EN el principio era el <em>Verbo</em>.',
          ),
          const SearchHit(
            resourceId: 'factbook.core',
            resourceTitle: 'Enciclopedia bíblica',
            resourceType: 'factbook',
            abbrev: 'FB',
            sectionId: 'gracia',
            book: '',
            bookName: 'Gracia',
            chapter: 0,
            verse: 0,
            ref: 'gracia',
            citation: 'Gracia',
            snippet: 'La <em>gracia</em> es el favor que Dios concede.',
          ),
          const SearchHit(
            resourceId: 'devotional.daily',
            resourceTitle: 'Devocional diario',
            resourceType: 'devotional',
            abbrev: 'DEV',
            sectionId: 'dayofyear.10.19',
            book: '',
            bookName: '19 de octubre',
            chapter: 0,
            verse: 0,
            ref: 'dayofyear.10.19',
            citation: '19 de octubre',
            snippet: 'Una lectura sobre el <em>Verbo</em>.',
          ),
        ],
      ),
    );
    final sections = FakeSectionsRepository();
    final container = _container(gateway, sections: sections);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.search, query: 'Verbo'));
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('search-group-bible.rv1909')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('search-group-factbook.core')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('search-group-devotional.daily')),
      findsOneWidget,
    );

    // Filtro de tipo: se envía al motor y aparece el botón de limpiar.
    await tester.tap(find.byKey(const ValueKey('search-filter-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artículos'));
    await tester.pumpAndSettle();
    expect(gateway.searchCalls.last, 'Verbo|all|type=factbook');
    expect(find.byKey(const ValueKey('search-filters-clear')), findsOneWidget);

    // Un resultado del Factbook abre su artículo, no el lector.
    await tester.tap(
      find.byKey(const ValueKey('search-hit-factbook.core-gracia')),
    );
    await tester.pumpAndSettle();
    final factbook = _tabOfKind(container, PanelKind.factbook);
    expect(factbook.reference, 'gracia');
    expect(sections.sectionCalls, contains('factbook.core/gracia'));
    expect(find.textContaining('La gracia es el favor'), findsWidgets);

    // Un resultado del devocional abre el día.
    await tester.tap(
      find.byKey(const ValueKey('search-hit-devotional.daily-dayofyear.10.19')),
    );
    await tester.pumpAndSettle();
    final devotional = _tabOfKind(container, PanelKind.devotional);
    expect(devotional.reference, 'dayofyear.10.19');
    expect(sections.sectionCalls, contains('devotional.daily/dayofyear.10.19'));
    expect(
      find.textContaining('Contenido devocional de prueba'),
      findsOneWidget,
    );
  });

  testWidgets('búsqueda: el teclado griego y hebreo inserta letras', (
    tester,
  ) async {
    _setWindow(tester, const Size(1500, 900));
    final gateway = FakeCatalogGateway();
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.search));
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-keyboard')));
    await tester.pumpAndSettle();
    expect(find.text('Griego'), findsOneWidget);
    expect(find.text('Hebreo'), findsOneWidget);

    await tester.tap(find.text('α'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('search-keyboard-hebrew')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('א'));
    await tester.pump();
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('search-field')),
    );
    expect(field.controller?.text, 'αא');
  });

  testWidgets('búsqueda: ámbitos de morfología y mapas', (tester) async {
    _setWindow(tester, const Size(1500, 900));
    final gateway = FakeCatalogGateway(
      searchResult: const SearchResult(
        query: 'Vqp3ms',
        scope: 'all',
        total: 1,
        page: 1,
        pageSize: 20,
        hits: [
          SearchHit(
            resourceId: 'morphology',
            resourceTitle: 'Morfología',
            resourceType: 'morphology',
            abbrev: 'MORF',
            sectionId: 'HVqp3ms',
            book: '',
            bookName: 'HVqp3ms',
            chapter: 0,
            verse: 0,
            ref: 'HVqp3ms',
            citation: 'HVqp3ms',
            snippet: 'función: <em>verbo</em>; tema: qal',
            detail: 'función: verbo; tema: qal; forma: perfecto',
          ),
        ],
      ),
    );
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.search, query: 'Vqp3ms'));
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('scope-morph')));
    await tester.pumpAndSettle();
    expect(gateway.searchCalls.last, 'Vqp3ms|morph');

    await tester.tap(
      find.byKey(const ValueKey('search-hit-morphology-HVqp3ms')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('función: verbo; tema: qal; forma: perfecto'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('scope-maps')));
    await tester.pumpAndSettle();
    expect(gateway.searchCalls.last, 'Vqp3ms|maps');
  });

  testWidgets('búsqueda: un ámbito de mapas lista sin consulta', (
    tester,
  ) async {
    _setWindow(tester, const Size(1500, 900));
    final gateway = FakeCatalogGateway();
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.search));
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('scope-maps')));
    await tester.pumpAndSettle();
    expect(gateway.searchCalls.last, '|maps');
  });

  testWidgets('búsqueda sin servicio: aviso y reintento', (tester) async {
    _setWindow(tester, const Size(1500, 900));
    final gateway = FakeCatalogGateway(
      searchError: CatalogException(
        'El servicio de catálogo no está disponible.',
      ),
    );
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.search, query: 'Verbo'));
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo buscar'), findsOneWidget);
    expect(find.textContaining('servicio de catálogo'), findsOneWidget);

    gateway.searchError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Sin resultados para «Verbo»'), findsOneWidget);
  });
}
