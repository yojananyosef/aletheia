// M6.3: Panel de inicio (tarjetas locales: continuar, plan, notas,
// devocional, estudio guiado y herramientas).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/reading_plans/reading_plans_controller.dart';
import 'package:aletheia/reading_plans/reading_plans_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

void _setWindow(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1400, 950);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<ProviderContainer> _pump(WidgetTester tester) async {
  _setWindow(tester);
  final container = ProviderContainer(
    overrides: [
      workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
      notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
      readingPlansStoreProvider
          .overrideWithValue(ReadingPlansStore.inMemory()),
      catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
      documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
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

/// Reactiva la primera pestaña del tipo dado (las tarjetas abren otras).
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

/// ¿Existe una pestaña del tipo dado con esa referencia?
bool _hasRef(ProviderContainer container, PanelKind kind, String reference) {
  for (final tile in container.read(workspaceProvider).tiles) {
    for (final tab in tile.tabs) {
      if (tab.kind == kind && tab.reference == reference) return true;
    }
  }
  return false;
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
  testWidgets('Inicio: tarjetas locales, plan y accesos a herramientas',
      (tester) async {
    final container = await _pump(tester);
    container.read(workspaceProvider.notifier).openTab(const TabSpec(
          kind: PanelKind.bible,
          reference: 'JHN.1.1',
          resourceId: 'bible.rv1909',
        ));
    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.dashboard));
    await tester.pumpAndSettle();

    // La lectura reciente aparece como chip navegable.
    expect(find.byKey(const ValueKey('dashboard-continue-0')), findsOneWidget);
    expect(find.text('Juan 1:1'), findsWidgets);
    await _tap(tester, find.byKey(const ValueKey('dashboard-continue-0')));
    expect(_tab(container, PanelKind.bible)?.reference, 'JHN.1.1');

    // Sin plan activo se ofrece elegir uno y se abre el panel de planes.
    _activate(container, PanelKind.dashboard);
    await tester.pumpAndSettle();
    expect(find.textContaining('No tienes un plan activo'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('dashboard-plan-choose')));
    expect(_tab(container, PanelKind.readingPlans), isNotNull);

    // Con plan activo la tarjeta muestra el día y abre la lectura de hoy.
    container.read(readingPlansProvider.notifier).start('bible-year');
    _activate(container, PanelKind.dashboard);
    await tester.pumpAndSettle();
    expect(find.text('Día 1 de 3'), findsWidgets);
    expect(find.textContaining('Génesis 1'), findsWidgets);
    await _tap(tester, find.byKey(const ValueKey('dashboard-plan-open')));
    expect(_hasRef(container, PanelKind.bible, 'GEN.1'), isTrue);

    // Notas sin anotaciones y accesos directos.
    _activate(container, PanelKind.dashboard);
    await tester.pumpAndSettle();
    expect(find.textContaining('0 notas'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('dashboard-notes-open')));
    expect(_tab(container, PanelKind.notes), isNotNull);

    _activate(container, PanelKind.dashboard);
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('dashboard-tool-compare')));
    expect(_tab(container, PanelKind.textComparison), isNotNull);

    // Una guía abre el Estudio guiado ya en marcha.
    _activate(container, PanelKind.dashboard);
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('dashboard-guide-word')));
    expect(_tab(container, PanelKind.guidedStudy)?.reference, 'word');
    expect(find.byKey(const ValueKey('guide-back')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
  });
}
