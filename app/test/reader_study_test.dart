/// Pruebas del estudio de originales: botón «Original», palabras enlazadas al
/// léxico Strong y apertura de la entrada desde el popover.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/catalog/sections_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

class _StudySectionsRepository implements SectionsRepository {
  static final CatalogSection _hebrew = CatalogSection.fromJson({
    'id': 'H0430',
    'title': 'H0430 · אֱלֹהִים',
    'summary': 'Dios',
    'referenceLabel': 'H0430',
    'tags': ['Hebreo', 'Léxico', 'Strong'],
    'blocks': [
      {
        'type': 'paragraph',
        'inlines': [
          {'t': 'text', 'v': 'Definición de prueba del léxico hebreo.'},
        ],
      },
    ],
  });

  @override
  Future<List<SectionSummary>> loadIndex(String resourceId) async =>
      resourceId == 'lexicon.strongs' ? [_hebrew.summary] : const [];

  @override
  Future<CatalogSection?> loadSection(
    String resourceId,
    String sectionId,
  ) async =>
      resourceId == 'lexicon.strongs' && sectionId == 'H0430' ? _hebrew : null;
}

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: const AletheiaApp(),
    );

ProviderContainer _container({
  required String resourceId,
  required String reference,
}) {
  final container = ProviderContainer(
    overrides: [
      workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
      notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
      catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
      documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
      sectionsRepositoryProvider.overrideWithValue(_StudySectionsRepository()),
    ],
  );
  container.read(workspaceProvider.notifier).openTab(
        TabSpec(
          kind: PanelKind.bible,
          title: resourceId == 'bible.tahot' ? 'TAHOT' : 'RV1909',
          reference: reference,
          resourceId: resourceId,
        ),
      );
  return container;
}

void _setWindow(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1400, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

List<WorkspaceTab> _tabs(ProviderContainer container) =>
    container.read(workspaceProvider).tiles.expand((tile) => tile.tabs).toList();

GestureRecognizer? _wordRecognizer(WidgetTester tester, String word) {
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    GestureRecognizer? found;
    rich.text.visitChildren((span) {
      if (span is TextSpan &&
          (span.text?.contains(word) ?? false) &&
          span.recognizer != null) {
        found = span.recognizer;
        return false;
      }
      return true;
    });
    if (found != null) return found;
  }
  return null;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];

  testWidgets('«Original» abre el texto griego en la misma referencia',
      (tester) async {
    _setWindow(tester);
    final container = _container(
      resourceId: 'bible.rv1909',
      reference: 'JHN.1.1',
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-original')), findsOneWidget);
    final originalButton = find.byKey(const ValueKey('reader-original'));
    await tester.ensureVisible(originalButton);
    await tester.pumpAndSettle();
    await tester.tap(originalButton);
    await tester.pumpAndSettle();

    final original = _tabs(container).where(
      (tab) => tab.resourceId == 'bible.tagnt',
    );
    expect(original, hasLength(1));
    expect(original.single.reference, 'JHN.1.1');
    expect(
      find.textContaining('Ἐν', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('el original hebreo no muestra «Original» y abre el léxico',
      (tester) async {
    _setWindow(tester);
    final container = _container(
      resourceId: 'bible.tahot',
      reference: 'PSA.3.1',
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-original')), findsNothing);
    expect(
      find.textContaining('אֱלֹהִים', findRichText: true),
      findsOneWidget,
    );

    final recognizer = _wordRecognizer(tester, 'אֱלֹהִים');
    expect(recognizer, isNotNull, reason: 'la palabra debe ser enlazable');
    (recognizer! as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('word-study-dialog')), findsOneWidget);
    expect(find.textContaining('H0430'), findsWidgets);
    expect(find.text('Dios'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('word-study-open-lexicon')));
    await tester.pumpAndSettle();

    final lexiconTabs = _tabs(container).where(
      (tab) => tab.resourceId == 'lexicon.strongs',
    );
    expect(lexiconTabs, hasLength(1));
    expect(lexiconTabs.single.reference, 'H0430');
    expect(
      find.textContaining('H0430 · אֱלֹהִים'),
      findsWidgets,
    );
  });
}
