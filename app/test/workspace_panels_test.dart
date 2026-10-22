/// Pruebas de la disposición de paneles: destino al abrir pestañas, panel
/// activo y arrastre de pestañas entre paneles.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

ProviderContainer _container() => ProviderContainer(
  overrides: [
    workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
    notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
    catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
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

String _tileOf(ProviderContainer container, String tabId) => container
    .read(workspaceProvider)
    .tiles
    .firstWhere((tile) => tile.tabs.any((tab) => tab.id == tabId))
    .id;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];

  test(
    'la primera pestaña abre en el primer panel y la segunda en el libre',
    () {
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
      var state = container.read(workspaceProvider);
      expect(state.tiles[0].tabs, hasLength(1));
      expect(state.tiles[1].tabs, isEmpty);

      // El segundo recurso aprovecha el panel libre, no se apila a la derecha
      // del todo.
      ctrl.openTab(
        const TabSpec(
          kind: PanelKind.bible,
          title: 'KJV',
          reference: 'JHN.1.1',
          resourceId: 'bible.kjv',
        ),
      );
      state = container.read(workspaceProvider);
      expect(state.tiles[0].tabs.single.resourceId, 'bible.rv1909');
      expect(state.tiles[1].tabs.single.resourceId, 'bible.kjv');

      // Sin panel activo y ambos ocupados, la tercera cae en el primero.
      ctrl.openTab(const TabSpec(kind: PanelKind.search, query: 'gracia'));
      state = container.read(workspaceProvider);
      expect(state.tiles[0].tabs, hasLength(2));
      expect(state.tiles[1].tabs, hasLength(1));
    },
  );

  test('abrir desde un panel ocupado usa el otro panel, sin taparlo', () {
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
    // La Biblia vive en el primer panel y sigue a la vista.
    ctrl.focusTile('tile_0');
    ctrl.openTab(const TabSpec(kind: PanelKind.notes));
    var state = container.read(workspaceProvider);
    expect(state.tiles[0].tabs, hasLength(1));
    expect(state.tiles[1].tabs.last.kind, PanelKind.notes);

    // Al tocar el otro panel ocurre lo mismo en espejo.
    ctrl.focusTile('tile_1');
    ctrl.openTab(const TabSpec(kind: PanelKind.favorites));
    state = container.read(workspaceProvider);
    expect(state.tiles[1].tabs, hasLength(2));
    expect(state.tiles[0].tabs.last.kind, PanelKind.favorites);
  });

  test('un panel vacío tocado por el usuario recibe la pestaña nueva', () {
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
    ctrl.focusTile('tile_1');
    ctrl.openTab(const TabSpec(kind: PanelKind.notes));
    final state = container.read(workspaceProvider);
    expect(state.tiles[0].tabs, hasLength(1));
    expect(state.tiles[1].tabs.single.kind, PanelKind.notes);
  });

  test('el chrome olvida el panel activo y usa el primer panel libre', () {
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
    // Aunque el segundo panel tenga el foco, una apertura desde el chrome
    // vuelve al primer panel libre (aquí el primero).
    ctrl.focusTile('tile_1');
    ctrl.clearActiveTile();
    ctrl.openTab(const TabSpec(kind: PanelKind.dashboard));
    final state = container.read(workspaceProvider);
    expect(state.tiles[0].tabs.last.kind, PanelKind.dashboard);
  });

  test('moveTab mueve la pestaña, activa el destino y ajusta el origen', () {
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
    final kjv = container.read(workspaceProvider).tiles[1].tabs.single;

    ctrl.moveTab(fromTileId: 'tile_1', tabId: kjv.id, toTileId: 'tile_0');
    final state = container.read(workspaceProvider);
    expect(state.tiles[0].tabs.map((tab) => tab.id), hasLength(2));
    expect(state.tiles[0].activeIndex, 1);
    expect(state.tiles[1].tabs, isEmpty);
    expect(ctrl.activeTileId, 'tile_0');
  });

  testWidgets('arrastrar una pestaña de un panel a otro', (tester) async {
    _setWindow(tester, const Size(1400, 900));
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
    final kjvId = container.read(workspaceProvider).tiles[1].tabs.single.id;
    expect(_tileOf(container, kjvId), 'tile_1');

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    final chip = find.byKey(ValueKey('tab-chip-$kjvId'));
    final target = tester.getCenter(find.byKey(const ValueKey('tile-tile_0')));
    final gesture = await tester.startGesture(tester.getCenter(chip));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_tileOf(container, kjvId), 'tile_0');
    expect(container.read(workspaceProvider).tiles[1].tabs, isEmpty);

    // Deja vencer el guardado con retardo antes de desmontar el árbol.
    await tester.pump(const Duration(milliseconds: 500));
  });
}
