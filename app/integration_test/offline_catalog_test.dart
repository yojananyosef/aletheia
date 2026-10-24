// Prueba de integración de la autonomía local: sin servicio de catálogo, la
// Biblioteca, el lector (RV1909 y KJV) y la Búsqueda funcionan con los assets
// y el índice FTS5 empaquetados. También verifica la extracción real del
// índice comprimido en el directorio de datos de la app.
//
// Ejecutar: flutter test integration_test/offline_catalog_test.dart -d linux
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'support/catalog_fixture.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];

  testWidgets('catálogo, lector y búsqueda funcionan sin servicio', (
    tester,
  ) async {
    final initial = WorkspaceState.fromJson({
      ...WorkspaceState.fresh().toJson(),
      'catalogMode': 'local',
    });
    final store = WorkspaceStore.inMemory(initial);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogDiskOverride,
          workspaceStoreProvider.overrideWithValue(store),
          notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
        ],
        child: const AletheiaApp(),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    // Biblioteca: los veintisiete recursos salen de los assets.
    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await _waitFor(tester, find.byKey(const ValueKey('library-list')));
    await _waitFor(tester, find.text('27 recursos'));
    // Lista virtualizada: la KJV queda por debajo del pliegue.
    await _scrollLibraryRow(tester, 'King James Version');
    expect(find.text('King James Version'), findsOneWidget);

    // Abrir la KJV desde los assets.
    await tester.tap(find.byKey(const ValueKey('library-row-bible.kjv')));
    await _waitFor(tester, find.byKey(const ValueKey('library-open')));
    await tester.tap(find.byKey(const ValueKey('library-open')));
    await _waitFor(
      tester,
      find.textContaining('In the beginning God created', findRichText: true),
    );

    var bible = _bibleTab(container);
    expect(bible.resourceId, 'bible.kjv');
    expect(bible.reference, 'GEN.1.1');

    // Búsqueda global contra el índice FTS5 local.
    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await _waitFor(tester, find.byKey(const ValueKey('search-field')));
    await tester.enterText(
      find.byKey(const ValueKey('search-field')),
      '"In the beginning"',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _waitFor(tester, find.textContaining('resultados para'));
    expect(find.text('Genesis 1:1'), findsWidgets);

    // Búsqueda dentro del panel del lector, limitada a la KJV.
    await tester.ensureVisible(find.byTooltip('Buscar en este recurso'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buscar en este recurso'));
    await _waitFor(tester, find.byKey(const ValueKey('reader-search-field')));
    await tester.enterText(
      find.byKey(const ValueKey('reader-search-field')),
      'beginning',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _waitFor(
      tester,
      find.byKey(const ValueKey('reader-search-results-beginning')),
    );
    expect(find.textContaining('resultados para «beginning»'), findsWidgets);

    final hitFinder = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('reader-search-hit-');
    });
    expect(hitFinder, findsWidgets);
    final hitRef =
        ((tester.widget(hitFinder.first).key as ValueKey<String>).value)
            .replaceFirst('reader-search-hit-', '');
    await tester.tap(hitFinder.first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_bibleTab(container).reference, hitRef);

    // Búsqueda de estudio en el Factbook: campo type: y salto a la sección.
    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await _waitFor(tester, find.byKey(const ValueKey('search-field')));
    await tester.enterText(
      find.byKey(const ValueKey('search-field')),
      'type:factbook gracia',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _waitFor(
      tester,
      find.byKey(const ValueKey('search-group-factbook.core')),
    );
    await _waitFor(
      tester,
      find.byKey(const ValueKey('search-hit-factbook.core-gracia')),
    );
    await tester.tap(
      find.byKey(const ValueKey('search-hit-factbook.core-gracia')),
    );
    await _waitFor(tester, find.byKey(const ValueKey('factbook-article')));
    await _waitFor(
      tester,
      find.textContaining('favor que Dios concede', findRichText: true),
    );
    final factbook = container
        .read(workspaceProvider)
        .tiles
        .expand((tile) => tile.tabs)
        .firstWhere((tab) => tab.kind == PanelKind.factbook);
    expect(factbook.reference, 'gracia');

    // Mapa offline del Factbook: la geometría sale de los assets y el marcador
    // de Jerusalén está presente. La atribución queda visible.
    container.read(workspaceProvider.notifier).openTab(
          const TabSpec(kind: PanelKind.factbook, reference: 'jerusalen'),
        );
    await _waitFor(tester, find.byKey(const ValueKey('bible-map')));
    await _waitFor(
      tester,
      find.byKey(const ValueKey('map-marker-Jerusalén')),
    );
    expect(find.textContaining('Natural Earth'), findsOneWidget);
    expect(find.textContaining('OpenBible.info'), findsOneWidget);

    // El ámbito de devocional también participa y abre su sección.
    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await _waitFor(tester, find.byKey(const ValueKey('search-field')));
    await tester.tap(find.byKey(const ValueKey('search-field')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(
      find.byKey(const ValueKey('search-field')),
      'type:devotional',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 100));
    final searchTab = container
        .read(workspaceProvider)
        .tiles
        .expand((tile) => tile.tabs)
        .firstWhere((tab) => tab.kind == PanelKind.search);
    expect(searchTab.query, 'type:devotional');
    await _waitFor(
      tester,
      find.byKey(const ValueKey('search-group-devotional.daily')),
    );
    final devotionalHit = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('search-hit-devotional.daily-');
    });
    expect(devotionalHit, findsWidgets);
    final devotionalRef =
        (tester.widget(devotionalHit.first).key as ValueKey<String>).value
            .replaceFirst('search-hit-devotional.daily-', '');
    await tester.tap(devotionalHit.first);
    await _waitFor(tester, find.byKey(const ValueKey('devotional-body')));
    final devotional = container
        .read(workspaceProvider)
        .tiles
        .expand((tile) => tile.tabs)
        .firstWhere((tab) => tab.kind == PanelKind.devotional);
    expect(devotional.reference, devotionalRef);

    // Comentario: búsqueda por tipo y apertura de la sección en el lector
    // genérico de recursos.
    container.read(workspaceProvider.notifier).openTab(
          const TabSpec(
            kind: PanelKind.search,
            query: 'type:commentary Nicodemus',
          ),
        );
    await tester.pump(const Duration(milliseconds: 500));
    await _waitFor(
      tester,
      find.byKey(const ValueKey('search-group-commentary.matthew-henry-concise')),
    );
    await tester.tap(
      find.byKey(const ValueKey(
        'search-hit-commentary.matthew-henry-concise-JHN.3',
      )),
    );
    await _waitFor(
      tester,
      find.byKey(const ValueKey('catalog-resource-detail')),
    );
    await _waitFor(
      tester,
      find.textContaining('Nicodemus', findRichText: true),
    );
    final commentary = container
        .read(workspaceProvider)
        .tiles
        .expand((tile) => tile.tabs)
        .firstWhere(
          (tab) =>
              tab.kind == PanelKind.resource &&
              tab.resourceId == 'commentary.matthew-henry-concise',
        );
    expect(commentary.reference, 'JHN.3');
    // El comentario de Juan 3 termina con el mapa inyectado; los assets
    // reales deben cargar la geometría también en este panel.
    await _waitFor(tester, find.byKey(const ValueKey('bible-map')));

    // Diccionario: entrada alfabética desde el mismo índice.
    container.read(workspaceProvider.notifier).openTab(
          const TabSpec(
            kind: PanelKind.search,
            query: 'type:dictionary "Grace, means of"',
          ),
        );
    await tester.pump(const Duration(milliseconds: 500));
    await _waitFor(
      tester,
      find.byKey(const ValueKey('search-group-dictionary.easton')),
    );
    await tester.tap(
      find.byKey(
        const ValueKey('search-hit-dictionary.easton-grace-means-of'),
      ),
    );
    await _waitFor(
      tester,
      find.byKey(const ValueKey('catalog-resource-detail')),
    );
    expect(find.text('Grace, means of'), findsWidgets);
    final dictionary = container
        .read(workspaceProvider)
        .tiles
        .expand((tile) => tile.tabs)
        .firstWhere(
          (tab) =>
              tab.kind == PanelKind.resource &&
              tab.resourceId == 'dictionary.easton',
        );
    expect(dictionary.reference, 'grace-means-of');

    // La RV1909 también está completa: abrir otro recurso no rompe la KJV.
    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await _waitFor(tester, find.text('27 recursos'));
    // Lista virtualizada: con diecisiete entradas la fila de RV1909 queda
    // por debajo del pliegue; arrástrala a la vista antes de abrirla.
    await _scrollLibraryRow(tester, 'Reina-Valera 1909');
    await tester.tap(find.byKey(const ValueKey('library-row-bible.rv1909')));
    await _waitFor(tester, find.byKey(const ValueKey('library-open')));
    await tester.tap(find.byKey(const ValueKey('library-open')));
    await _waitFor(
      tester,
      find.textContaining('EN el principio crió Dios', findRichText: true),
    );

    // Ideas: las referencias cruzadas del TSK se suman al contenido propio.
    await tester.tap(find.byKey(const ValueKey('reader-insights')));
    await _waitFor(
      tester,
      find.textContaining('Tesoro de conocimiento bíblico'),
    );
    expect(
      find.byKey(const ValueKey('insights-passage-1CH.16.26')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('drawer-close')));
    await tester.pumpAndSettle();

    final bibles = container
        .read(workspaceProvider)
        .tiles
        .expand((tile) => tile.tabs)
        .where((tab) => tab.kind == PanelKind.bible)
        .map((tab) => tab.resourceId)
        .toSet();
    expect(bibles, containsAll(['bible.kjv', 'bible.rv1909']));
  });
}

WorkspaceTab _bibleTab(ProviderContainer container) => container
    .read(workspaceProvider)
    .tiles
    .expand((tile) => tile.tabs)
    .firstWhere((tab) => tab.kind == PanelKind.bible);

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  final visible = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .where((value) => value.trim().isNotEmpty)
      .toList();
  fail('No apareció en pantalla: $finder\nTextos visibles: $visible');
}

/// La biblioteca lista con física virtualizada: con diecisiete entradas la
/// fila de RV1909 queda fuera del rango construido; arrastra la lista hasta
/// que el título aparezca.
Future<void> _scrollLibraryRow(WidgetTester tester, String title) async {
  final list = find.byKey(const ValueKey('library-list'));
  for (var i = 0; i < 30; i++) {
    if (find.text(title).evaluate().isNotEmpty) return;
    await tester.drag(list, const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 120));
  }
  fail('No se pudo desplazar a la vista la fila «$title»');
}
