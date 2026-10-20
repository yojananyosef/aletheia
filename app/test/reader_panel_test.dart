/// Pruebas de los arreglos del panel del lector:
/// - cambiar de versión en la misma pestaña recarga el texto (bug «sale la
///   misma Biblia»),
/// - abrir otra versión no reutiliza la pestaña de otro recurso,
/// - el modo «Buscar» del panel busca dentro del recurso y navega,
/// - la barra lateral puede expandirse en ventanas estrechas y el apilado de
///   paneles ya no depende de su estado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_client.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/catalog_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';
import 'package:aletheia/notes/notes_persistence.dart';

import 'support/test_fakes.dart';

// --------------------------------------------------------------- utilidades

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: const AletheiaApp(),
    );

ProviderContainer _container(CatalogGateway gateway) => ProviderContainer(
      overrides: [
        workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
        catalogGatewayProvider.overrideWithValue(gateway),
        documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
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

void main() {
  // El clon tiene el español como idioma de diseño: se fija el idioma de la
  // plataforma para que las expectativas de los textos no dependan del
  // entorno (M3).
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];
  testWidgets('cambiar de versión en la misma pestaña recarga el texto',
      (tester) async {
    _setWindow(tester, const Size(1400, 900));
    final gateway = FakeCatalogGateway();
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    container.read(workspaceProvider.notifier).openTab(const TabSpec(
          kind: PanelKind.bible,
          title: 'RV1909',
          reference: 'JHN.1.1',
          resourceId: 'bible.rv1909',
        ));

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('EN el principio era el Verbo.', findRichText: true),
      findsOneWidget,
    );

    // «Cambiar libro» → KJV en la *misma* pestaña: el cuerpo debe recargarse.
    final tab = _tabOfKind(container, PanelKind.bible);
    final tile = container
        .read(workspaceProvider)
        .tiles
        .firstWhere((t) => t.tabs.any((x) => x.id == tab.id));
    container.read(workspaceProvider.notifier).switchBibleResource(
          tileId: tile.id,
          tabId: tab.id,
          resourceId: 'bible.kjv',
          title: 'KJV',
        );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('In the beginning was the Word', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('EN el principio era el Verbo.', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('buscar dentro del panel: consulta, resultados y navegación',
      (tester) async {
    _setWindow(tester, const Size(1400, 900));
    final gateway = FakeCatalogGateway(
      searchResult: SearchResult(
        query: 'principio',
        scope: 'all',
        total: 2,
        page: 1,
        pageSize: 20,
        hits: [
          testHit('JHN.1.1', 'Juan 1:1',
              'EN el <em>principio</em> era el Verbo.'),
          testHit('JHN.1.2', 'Juan 1:2',
              'Este era en el <em>principio</em> con Dios.'),
        ],
      ),
    );
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    container.read(workspaceProvider.notifier).openTab(const TabSpec(
          kind: PanelKind.bible,
          title: 'RV1909',
          reference: 'JHN.2.1',
          resourceId: 'bible.rv1909',
        ));

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    // El modo «Buscar» del panel abre la búsqueda dentro del recurso.
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-search-field')), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('reader-search-field')), 'principio');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // La consulta se limita al recurso del panel.
    expect(gateway.searchCalls, ['principio|all|bible.rv1909']);
    expect(find.textContaining('2 resultados'), findsOneWidget);
    expect(find.text('Juan 1:1'), findsOneWidget);
    expect(find.text('Juan 1:2'), findsOneWidget);

    // Tocar un resultado navega el panel y vuelve al modo Inicio.
    await tester.tap(find.byKey(const ValueKey('reader-search-hit-JHN.1.2')));
    await tester.pumpAndSettle();

    final bible = _tabOfKind(container, PanelKind.bible);
    expect(bible.reference, 'JHN.1.2');
    expect(
      find.textContaining('Este era en el principio con Dios.',
          findRichText: true),
      findsOneWidget,
    );
    final refBox = tester.widget<TextField>(
        find.byKey(const ValueKey('reader-reference-box')));
    expect(refBox.controller!.text, 'Juan 1:2');
  });

  testWidgets('búsqueda en el panel sin servicio: aviso y reintento',
      (tester) async {
    _setWindow(tester, const Size(1400, 900));
    final gateway = FakeCatalogGateway(
      searchError: CatalogException('El servicio de catálogo no está disponible.'),
    );
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    container.read(workspaceProvider.notifier).openTab(const TabSpec(
          kind: PanelKind.bible,
          title: 'RV1909',
          reference: 'JHN.1.1',
          resourceId: 'bible.rv1909',
        ));

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('reader-search-field')), 'Verbo');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('No se pudo buscar'), findsOneWidget);
    expect(find.textContaining('servicio de catálogo'), findsOneWidget);
  });

  test('abrir otra versión no reutiliza la pestaña de otro recurso', () {
    final container = _container(FakeCatalogGateway());
    addTearDown(container.dispose);
    final ctrl = container.read(workspaceProvider.notifier);

    ctrl.openTab(const TabSpec(
        kind: PanelKind.bible,
        title: 'RV1909',
        reference: 'GEN.1.1',
        resourceId: 'bible.rv1909'));
    // Otra versión en la misma referencia: pestaña nueva, no se reemplaza la
    // que ya estaba abierta.
    ctrl.openTab(const TabSpec(
        kind: PanelKind.bible,
        title: 'KJV',
        reference: 'GEN.1.1',
        resourceId: 'bible.kjv'));

    final bibles =
        _tabs(container).where((t) => t.kind == PanelKind.bible).toList();
    expect(bibles.length, 2);
    expect(
      bibles.map((t) => t.resourceId).toSet(),
      {'bible.rv1909', 'bible.kjv'},
    );

    // La misma versión y la misma referencia sí se reutiliza.
    ctrl.openTab(const TabSpec(
        kind: PanelKind.bible,
        title: 'RV1909',
        reference: 'GEN.1.1',
        resourceId: 'bible.rv1909'));
    expect(
      _tabs(container).where((t) => t.kind == PanelKind.bible).length,
      2,
    );
  });

  testWidgets('la barra lateral se puede expandir en ventana estrecha',
      (tester) async {
    _setWindow(tester, const Size(764, 900));
    final gateway = FakeCatalogGateway();
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    // Ventana estrecha: por defecto es un rail de iconos sin etiquetas.
    expect(find.text('Biblia'), findsNothing);
    expect(find.text('Búsqueda'), findsNothing);

    // La flecha del pie fija la preferencia explícita del usuario.
    await tester.tap(find.byTooltip('Expandir barra lateral'));
    await tester.pumpAndSettle();
    expect(find.text('Biblia'), findsOneWidget);
    expect(find.text('Búsqueda'), findsOneWidget);

    // Y también se puede volver a plegar.
    await tester.tap(find.byTooltip('Colapsar barra lateral'));
    await tester.pumpAndSettle();
    expect(find.text('Biblia'), findsNothing);
  });

  testWidgets('los paneles se mantienen lado a lado a cualquier ancho',
      (tester) async {
    _setWindow(tester, const Size(1000, 900));
    final gateway = FakeCatalogGateway();
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    container.read(workspaceProvider.notifier).openTab(const TabSpec(
          kind: PanelKind.bible,
          title: 'RV1909',
          reference: 'GEN.1.1',
          resourceId: 'bible.rv1909',
        ));
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    final first = tester.getRect(find.byKey(const ValueKey('tile-tile_0')));
    final second = tester.getRect(find.byKey(const ValueKey('tile-tile_1')));
    // Lado a lado: mismo alto y distinta x.
    expect(first.top, second.top);
    expect(first.left, lessThan(second.left));

    // Plegar la barra a mano no debe reordenar los paneles (antes el umbral
    // de apilado dependía del ancho del workspace).
    await tester.tap(find.byTooltip('Colapsar barra lateral'));
    await tester.pumpAndSettle();
    final firstAfter = tester.getRect(find.byKey(const ValueKey('tile-tile_0')));
    final secondAfter =
        tester.getRect(find.byKey(const ValueKey('tile-tile_1')));
    expect(firstAfter.top, secondAfter.top);
    expect(firstAfter.left, lessThan(secondAfter.left));

    // Ventana que no da para dos paneles legibles: queda visible el que tiene
    // la pestaña abierta (la Biblia vive en el último tile) y el tile vacío se
    // oculta. Los paneles nunca se apilan.
    tester.view.physicalSize = const Size(520, 700);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tile-tile_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('tile-tile_0')), findsNothing);
    final only = tester.getRect(find.byKey(const ValueKey('tile-tile_1')));
    expect(only.width, greaterThanOrEqualTo(320 - 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('el círculo oculta la barra secundaria y el ⋮ abre los comandos',
      (tester) async {
    _setWindow(tester, const Size(1400, 900));
    final gateway = FakeCatalogGateway();
    final container = _container(gateway);
    addTearDown(container.dispose);
    addTearDown(gateway.client.close);

    container.read(workspaceProvider.notifier).openTab(const TabSpec(
          kind: PanelKind.bible,
          title: 'RV1909',
          reference: 'JHN.1.1',
          resourceId: 'bible.rv1909',
        ));
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    // La barra de ubicación titula el artículo «San Juan» (home2), pero la
    // referencia del lector sigue siendo «Juan».
    expect(find.text('San Juan'), findsOneWidget);

    // Círculo «^»: oculta la barra secundaria y lo recuerda en la pestaña.
    expect(find.byKey(const ValueKey('reader-insights')), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('reader-secondary-toolbar-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-insights')), findsNothing);
    expect(_tabOfKind(container, PanelKind.bible).display.secondaryToolbar,
        isFalse);
    expect(find.byTooltip('Mostrar la barra secundaria'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('reader-secondary-toolbar-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-insights')), findsOneWidget);
    expect(_tabOfKind(container, PanelKind.bible).display.secondaryToolbar,
        isTrue);

    // ⋮ «Comandos del panel»: duplicar y cerrar pestañas.
    await tester.tap(find.byKey(const ValueKey('reader-panel-commands')));
    await tester.pumpAndSettle();
    // La barra lateral repite «Cerrar todas las pestañas»: se busca dentro
    // del menú.
    final menu = find.byType(PopupMenuItem<String>);
    for (final label in [
      'Duplicar esta pestaña',
      'Cerrar esta pestaña',
      'Cerrar pestañas a la derecha',
      'Cerrar otras pestañas',
      'Cerrar todas las pestañas',
    ]) {
      expect(find.descendant(of: menu, matching: find.text(label)),
          findsOneWidget);
    }
  });
}
