/// Estados de catálogo desacoplado en el lector (vistos en la app Linux):
///
/// 1. Pedir un libro que el recurso no contiene (Génesis en TAGNT) ya no
///    muestra «Unable to load asset»: hay tarjeta amistosa con CTA para abrir
///    el recurso equivalente (TAHOT para el Antiguo Testamento).
/// 2. Un recurso cuya fuente no está instalada (catálogo en módulos de la
///    Tienda) muestra la tarjeta de instalación, no el error crudo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aletheia/catalog/catalog_asset_source.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

class _TagntOnlyRepository implements DocumentRepository {
  @override
  Future<DocumentManifest> loadManifest(String resourceId) async =>
      FakeDocumentRepository.manifestOf('bible.tagnt');

  @override
  Future<BookDocument> loadBook(String resourceId, String code) async {
    // No debería llamarse para un libro fuera del manifest.
    throw StateError('no debió pedirse $resourceId/$code');
  }
}

/// Un recurso leído desde una fuente que no está instalada (para probar el
/// flujo «instalar módulo» en la web, donde no hay tienda).
class _NotInstalledRepository implements DocumentRepository {
  @override
  Future<DocumentManifest> loadManifest(String resourceId) async =>
      // El manifest remoto puede existir; el fallo llega al pedir el libro.
      FakeDocumentRepository.manifestOf(resourceId);

  @override
  Future<BookDocument> loadBook(String resourceId, String code) async {
    throw CatalogNotInstalledException(
      moduleId: resourceId,
      path: 'assets/catalog/${code == 'GEN' ? 'kjv' : code}/books/JHN.json.gz',
    );
  }
}

Widget _app(ProviderContainer container) =>
    UncontrolledProviderScope(container: container, child: const AletheiaApp());

ProviderContainer _container(DocumentRepository repository) =>
    ProviderContainer(
      overrides: [
        workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
        notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
        catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
        documentRepositoryProvider.overrideWithValue(repository),
      ],
    );

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];

  void setWindow(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  List<WorkspaceTab> tabs(ProviderContainer container) => container
      .read(workspaceProvider)
      .tiles
      .expand((tile) => tile.tabs)
      .toList();

  testWidgets('Génesis en TAGNT muestra la tarjeta y abre TAHOT con el CTA', (
    tester,
  ) async {
    setWindow(tester);
    final container = _container(_TagntOnlyRepository());
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    container.read(workspaceProvider.notifier).openTab(
      const TabSpec(
        kind: PanelKind.bible,
        title: 'TAGNT',
        reference: 'GEN.1.1',
        resourceId: 'bible.tagnt',
        resourceType: 'bible',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-book-unavailable')), findsOneWidget);
    expect(
      find.textContaining('Génesis no está disponible'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('reader-open-equivalent')));
    await tester.pump(const Duration(milliseconds: 450));

    expect(
      tabs(container).any((tab) => tab.resourceId == 'bible.tahot'),
      isTrue,
      reason: 'el CTA debe abrir la pestaña equivalente de TAHOT',
    );
  });

  testWidgets('un recurso sin módulo muestra la tarjeta de instalación', (
    tester,
  ) async {
    setWindow(tester);
    final container = _container(_NotInstalledRepository());
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    container.read(workspaceProvider.notifier).openTab(
      const TabSpec(
        kind: PanelKind.bible,
        title: 'KJV',
        reference: 'JHN.1.1',
        resourceId: 'bible.kjv',
        resourceType: 'bible',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-module-missing')),
      findsOneWidget,
    );
  });
}
