// M6.1: drawers «Ideas» (💡) e «Información» (ⓘ) del lector y menú Artículo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/catalog_models.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/catalog/sections_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/reader/related_content.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

/// Secciones propias que citan Juan 1 (Factbook + devocional).
class _RelatedSectionsRepository implements SectionsRepository {
  @override
  Future<List<SectionSummary>> loadIndex(String resourceId) async {
    switch (resourceId) {
      case 'factbook.core':
        return [
          SectionSummary.fromJson({
            'id': 'gracia',
            'title': 'Gracia',
            'summary': 'Favor inmerecido de Dios.',
            'tags': ['Teología'],
            'references': ['JHN.1.1', 'JHN.1.2', 'ROM.5.8'],
          }),
        ];
      case 'devotional.daily':
        return [
          SectionSummary.fromJson({
            'id': 'dayofyear.10.19',
            'day': '10.19',
            'title': '19 de octubre',
            'theme': 'Amor de Dios',
            'reference': 'JHN.1.1',
            'referenceLabel': 'Juan 1:1',
          }),
        ];
      case 'commentary.matthew-henry-concise':
        return [
          SectionSummary.fromJson({
            'id': 'JHN.1',
            'title': 'John 1',
            'summary': 'The Word made flesh.',
            'reference': 'JHN.1',
            'referenceLabel': 'John 1',
            'tags': ['Comentario'],
          }),
        ];
    }
    return const [];
  }

  @override
  Future<CatalogSection?> loadSection(
          String resourceId, String sectionId) async =>
      null;
}

/// Pulsa un control aunque quede fuera del viewport estrecho.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _setWindow(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1400, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<ProviderContainer> _pumpReader(WidgetTester tester) async {
  _setWindow(tester);
  final gateway = FakeCatalogGateway()
    ..crossReferenceResult = const [
      CrossReference(reference: 'ROM.5.8'),
    ];
  final container = ProviderContainer(
    overrides: [
      workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
      notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
      catalogGatewayProvider.overrideWithValue(gateway),
      documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
      sectionsRepositoryProvider
          .overrideWithValue(_RelatedSectionsRepository()),
    ],
  );
  addTearDown(container.dispose);
  container.read(workspaceProvider.notifier).openTab(
        const TabSpec(
          kind: PanelKind.bible,
          reference: 'JHN.1.1',
          resourceId: 'bible.rv1909',
        ),
      );
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const AletheiaApp(),
  ));
  await tester.pumpAndSettle();
  return container;
}

String? _tabReference(ProviderContainer container, PanelKind kind) {
  for (final tile in container.read(workspaceProvider).tiles) {
    for (final tab in tile.tabs) {
      if (tab.kind == kind) return tab.reference;
    }
  }
  return null;
}

void main() {
  // ------------------------------------------------------- referencias puras

  group('referencesOverlap', () {
    test('compara libro, capítulo y versículo', () {
      expect(referencesOverlap('JHN.3.16', 'JHN.3.16'), isTrue);
      expect(referencesOverlap('JHN.3', 'JHN.3.16'), isTrue);
      expect(referencesOverlap('JHN.3.16-18', 'JHN.3.16'), isTrue);
      expect(referencesOverlap('JHN.3.15', 'JHN.3.16'), isFalse);
      expect(referencesOverlap('ROM.5.8', 'JHN.3.16'), isFalse);
      expect(referencesOverlap('JHN', 'JHN.3.16'), isFalse);
    });
  });

  // -------------------------------------------------------------- Ideas (💡)

  testWidgets('Ideas: pestañas, libros y pasajes relacionados', (tester) async {
    final container = await _pumpReader(tester);

    await _tap(tester, find.byKey(const ValueKey('reader-insights')));

    expect(find.text('Ideas'), findsOneWidget);
    expect(find.text('Información del libro'), findsOneWidget);
    expect(find.text('Libros relacionados'), findsOneWidget);
    expect(find.text('Pasajes relacionados'), findsOneWidget);
    expect(find.text('Referencias cruzadas'), findsOneWidget);

    // Libros propios que citan la referencia.
    expect(find.byKey(const ValueKey('insights-book-gracia')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('insights-book-dayofyear.10.19')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('insights-book-JHN.1')), findsOneWidget);

    // Referencias cruzadas reales del TSK, además de las del catálogo.
    expect(
      find.byKey(const ValueKey('insights-passage-ROM.5.8')),
      findsOneWidget,
    );
    expect(find.textContaining('Tesoro de conocimiento bíblico'), findsOneWidget);

    // Co-referencias del catálogo, con el texto del versículo de la RV1909.
    expect(
      find.byKey(const ValueKey('insights-passage-JHN.1.2')),
      findsOneWidget,
    );
    expect(find.text('Este era en el principio con Dios.'), findsOneWidget);

    // Un pasaje navega el lector.
    await _tap(tester, find.byKey(const ValueKey('insights-passage-JHN.1.2')));
    expect(_tabReference(container, PanelKind.bible), 'JHN.1.2');

    // Un libro abre su panel (Factbook) en el artículo.
    await _tap(tester, find.byKey(const ValueKey('insights-book-gracia')));
    expect(_tabReference(container, PanelKind.factbook), 'gracia');
  });

  // -------------------------------------------------------- Información (ⓘ)

  testWidgets('Ideas abre el comentario en una pestaña de recurso',
      (tester) async {
    final container = await _pumpReader(tester);

    await _tap(tester, find.byKey(const ValueKey('reader-insights')));
    await _tap(tester, find.byKey(const ValueKey('insights-book-JHN.1')));
    expect(_tabReference(container, PanelKind.resource), 'JHN.1');
  });

  testWidgets('Información: ficha del recurso y plan de lectura',
      (tester) async {
    await _pumpReader(tester);

    await _tap(tester, find.byKey(const ValueKey('reader-info')));

    expect(find.text('Acerca de Biblia de prueba'), findsOneWidget);
    // «Comenzar plan de lectura» abre el gestor de planes (M6.3).
    final plan = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('insights-reading-plan')),
    );
    expect(plan.onPressed, isNotNull);
    expect(find.text('Comenzar plan de lectura'), findsOneWidget);

    // Información auxiliar con el identificador del recurso.
    await _tap(tester, find.text('Información auxiliar'));
    expect(find.text('bible.rv1909'), findsOneWidget);

    // Cerrar el panel.
    await _tap(tester, find.byKey(const ValueKey('drawer-close')));
    expect(find.text('Acerca de Biblia de prueba'), findsNothing);
  });

  // ----------------------------------------------------------- Artículo ▾

  testWidgets('Artículo ▾ pasa al capítulo siguiente', (tester) async {
    final container = await _pumpReader(tester);

    await _tap(tester, find.byKey(const ValueKey('reader-article')));
    expect(find.text('Ir a artículo'), findsOneWidget);

    await _tap(tester, find.text('Artículo siguiente'));
    expect(_tabReference(container, PanelKind.bible), 'JHN.2');
  });
}
