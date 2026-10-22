import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/core/theme.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/shell/shell.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

// Paquete de paridad 1: conjuntos de vínculos, tienda local, pantalla completa
// por panel y tema oscuro.

ProviderContainer _container({CatalogGateway? gateway}) => ProviderContainer(
  overrides: [
    workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
    notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
    catalogGatewayProvider.overrideWithValue(gateway ?? FakeCatalogGateway()),
    documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
  ],
);

Widget _app(ProviderContainer container) =>
    UncontrolledProviderScope(container: container, child: const AletheiaApp());

void _setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

List<WorkspaceTab> _tabs(ProviderContainer container) =>
    container.read(workspaceProvider).tiles.expand((t) => t.tabs).toList();

Future<void> _tapInToolbar(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];

  tearDown(() => setActivePalette(AletheiaPalette.light));

  test('link set: la navegación se propaga solo a Biblias del mismo grupo', () {
    final container = _container();
    addTearDown(container.dispose);
    final ctrl = container.read(workspaceProvider.notifier);
    ctrl.openTab(
      const TabSpec(
        kind: PanelKind.bible,
        title: 'RV1909',
        reference: 'JHN.1.1',
        resourceId: 'bible.rv1909',
      ),
    );
    ctrl.openTab(
      const TabSpec(
        kind: PanelKind.bible,
        title: 'KJV',
        reference: 'JHN.1.1',
        resourceId: 'bible.kjv',
      ),
    );
    ctrl.openTab(const TabSpec(kind: PanelKind.search, query: 'gracia'));

    var tabs = _tabs(container);
    final rv = tabs.firstWhere((t) => t.resourceId == 'bible.rv1909');
    final kjv = tabs.firstWhere((t) => t.resourceId == 'bible.kjv');
    final search = tabs.firstWhere((t) => t.kind == PanelKind.search);
    String tileOf(String tabId) => container
        .read(workspaceProvider)
        .tiles
        .firstWhere((tile) => tile.tabs.any((t) => t.id == tabId))
        .id;
    final tile = tileOf(rv.id);
    // Las dos Biblias caen en paneles distintos: el vínculo las sincroniza
    // cruzando los dos paneles.
    expect(tileOf(kjv.id), isNot(tile));

    ctrl.setTabLinkSet(tileId: tileOf(rv.id), tabId: rv.id, linkSet: 'A');
    ctrl.setTabLinkSet(tileId: tileOf(kjv.id), tabId: kjv.id, linkSet: 'A');
    ctrl.setTabLinkSet(
      tileId: tileOf(search.id),
      tabId: search.id,
      linkSet: 'A',
    );

    ctrl.navigateTabReference(
      tileId: tile,
      tabId: rv.id,
      reference: 'JHN.3.16',
    );

    tabs = _tabs(container);
    final rvAfter = tabs.firstWhere((t) => t.id == rv.id);
    final kjvAfter = tabs.firstWhere((t) => t.id == kjv.id);
    final searchAfter = tabs.firstWhere((t) => t.id == search.id);
    expect(rvAfter.reference, 'JHN.3.16');
    expect(kjvAfter.reference, 'JHN.3.16');
    expect(kjvAfter.history, contains('JHN.3.16'));
    // La búsqueda no es un panel bíblico: no participa en el vínculo.
    expect(searchAfter.reference, isNull);

    ctrl.setTabLinkSet(tileId: tile, tabId: rv.id, linkSet: null);
    ctrl.navigateTabReference(
      tileId: tile,
      tabId: rv.id,
      reference: 'ROM.8.28',
    );
    tabs = _tabs(container);
    expect(tabs.firstWhere((t) => t.id == rv.id).reference, 'ROM.8.28');
    expect(
      tabs.firstWhere((t) => t.id == kjv.id).reference,
      'JHN.3.16',
      reason: 'al quitarse del grupo, el panel deja de seguir al primero',
    );
  });

  test('link set y tema sobreviven al JSON del workspace', () {
    final tab = WorkspaceTab.fromJson(
      WorkspaceTab(
        id: 'tab_1',
        kind: PanelKind.bible,
        title: 'RV1909',
        reference: 'JHN.1.1',
        linkSet: 'C',
      ).toJson(),
    );
    expect(tab.linkSet, 'C');

    final state = WorkspaceState.fromJson({
      ...WorkspaceState.fresh().toJson(),
      'themeMode': 'dark',
    });
    expect(state.themeMode, 'dark');
  });

  testWidgets('tienda local: lista, filtra y abre el recurso', (tester) async {
    _setWindow(tester, const Size(1400, 900));
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.store));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('store-panel')), findsOneWidget);
    expect(find.text('Tienda de módulos'), findsOneWidget);
    expect(find.text('2 recursos disponibles'), findsOneWidget);
    expect(find.text('Reina-Valera 1909'), findsOneWidget);
    expect(find.text('Comentario de prueba'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('store-search')),
      'Comentario',
    );
    await tester.pump();
    expect(find.text('Comentario de prueba'), findsOneWidget);
    expect(find.text('Reina-Valera 1909'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('store-open-commentary.test')));
    await tester.pump(const Duration(milliseconds: 450));
    final opened = _tabs(container).where(
      (t) => t.kind == PanelKind.resource && t.resourceId == 'commentary.test',
    );
    expect(opened, isNotEmpty);
  });

  testWidgets('pantalla completa del panel oculta el chrome y se restaura', (
    tester,
  ) async {
    _setWindow(tester, const Size(1400, 900));
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-bible')));
    await tester.pumpAndSettle();
    await _tapInToolbar(tester, const ValueKey('reader-mode-view'));

    await _tapInToolbar(tester, const ValueKey('reader-full-screen'));
    expect(find.byKey(const ValueKey('panel-fullscreen')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-bible')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('panel-fullscreen-exit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('panel-fullscreen')), findsNothing);
    expect(find.byKey(const ValueKey('nav-bible')), findsOneWidget);
  });

  testWidgets('Esc también sale de la pantalla completa', (tester) async {
    _setWindow(tester, const Size(1400, 900));
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-bible')));
    await tester.pumpAndSettle();
    await _tapInToolbar(tester, const ValueKey('reader-mode-view'));
    await _tapInToolbar(tester, const ValueKey('reader-full-screen'));
    expect(find.byKey(const ValueKey('panel-fullscreen')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('panel-fullscreen')), findsNothing);
  });

  testWidgets('el selector de conjunto de vínculos actualiza la pestaña', (
    tester,
  ) async {
    _setWindow(tester, const Size(1400, 900));
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-bible')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-link-set')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();

    expect(
      _tabs(container).firstWhere((t) => t.kind == PanelKind.bible).linkSet,
      'A',
    );
  });

  testWidgets('tema oscuro: cambia la paleta y el brightness de MaterialApp', (
    tester,
  ) async {
    _setWindow(tester, const Size(1200, 800));
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(Shell))).brightness,
      Brightness.light,
    );

    container.read(workspaceProvider.notifier).setThemeMode('dark');
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(Shell))).brightness,
      Brightness.dark,
    );
    expect(activePalette.isDark, isTrue);
    expect(kPanelBg, AletheiaPalette.dark.panelBg);
    expect(kTextPrimary, AletheiaPalette.dark.textPrimary);
  });
}
