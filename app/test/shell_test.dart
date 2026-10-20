import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

// Paquete A del repaso de diseño: cabecera lateral con ómnibus, banner en la
// columna del workspace, rail con el ómnibus en diálogo y pestañas de recurso.

void _setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

ProviderContainer _container() => ProviderContainer(
      overrides: [
        workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
        notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
        documentRepositoryProvider
            .overrideWithValue(FakeDocumentRepository()),
      ],
    );

Future<ProviderContainer> _pump(WidgetTester tester, Size size) async {
  _setWindow(tester, size);
  final container = _container();
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const AletheiaApp(),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];

  testWidgets('ventana angosta: rail y ómnibus en diálogo que navega',
      (tester) async {
    final container = await _pump(tester, const Size(760, 600));

    // El rail no muestra etiquetas; el logo es la entrada al ómnibus.
    expect(find.text('Biblioteca'), findsNothing);
    expect(find.byKey(const ValueKey('sidebar-omnibox')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byKey(const ValueKey('sidebar-omnibox')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Pasaje o tema'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Juan 2');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Al navegar, el diálogo se cierra y queda la pestaña abierta.
    expect(find.byType(Dialog), findsNothing);
    final tabs = container
        .read(workspaceProvider)
        .tiles
        .expand((tile) => tile.tabs)
        .toList();
    final tab = tabs.firstWhere((t) => t.reference != null);
    expect(tab.kind, PanelKind.bible);
    expect(tab.reference, 'JHN.2');
  });

  testWidgets('banner: en la columna del workspace y se puede cerrar',
      (tester) async {
    final container = await _pump(tester, const Size(1400, 900));

    expect(find.byKey(const ValueKey('app-banner')), findsOneWidget);
    expect(find.text('Abrir Biblioteca'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar banner'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app-banner')), findsNothing);
    expect(
      container.read(workspaceProvider).layoutBannersVisible,
      isFalse,
    );
    // Guardado diferido del workspace (debounce).
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('pestaña de biblia: se rotula con la abreviatura del recurso',
      (tester) async {
    final container = await _pump(tester, const Size(1400, 900));
    container.read(workspaceProvider.notifier).openTab(
          const TabSpec(
            kind: PanelKind.bible,
            title: 'Juan 1:1',
            reference: 'JHN.1.1',
          ),
        );
    await tester.pumpAndSettle();

    final tab = container
        .read(workspaceProvider)
        .tiles
        .expand((tile) => tile.tabs)
        .firstWhere((t) => t.kind == PanelKind.bible);
    expect(tab.title, 'Juan 1:1');

    final chip = find.byKey(ValueKey('tab-chip-${tab.id}'));
    expect(chip, findsOneWidget);
    // La tira usa la abreviatura del manifiesto; la referencia vive en el
    // panel (caja de referencia), no en la pestaña.
    expect(
      find.descendant(of: chip, matching: find.text('RV1909')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: chip, matching: find.text('Juan 1:1')),
      findsNothing,
    );
  });
}
