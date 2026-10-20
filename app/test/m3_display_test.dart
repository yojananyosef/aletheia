/// Pruebas de M3: Formato (reformato real del texto), Vista (zoom, barra de
/// ubicación y vista paginada), Ajustes (idioma, ubicación de la barra,
/// restablecer) y citas (estilos + copia).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/references/citation.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';
import 'package:aletheia/notes/notes_persistence.dart';

import 'support/test_fakes.dart';

// -------------------------------------------------------- documento de prueba

const _resourceId = 'bible.formato';

final _manifest = DocumentManifest.fromJson({
  'resourceId': _resourceId,
  'title': 'Biblia de prueba',
  'abbrev': 'RV1909',
  'language': 'es',
  'source': 'test',
  'license': 'test',
  'books': [
    {
      'code': 'JHN',
      'name': 'Juan',
      'chapters': [
        {'n': 1, 'verses': 3}
      ],
    },
  ],
});

/// Juan 1 con un párrafo de dos versículos (nota al pie y referencia cruzada)
/// y un grupo de poesía.
final _jhn = BookDocument.fromJson({
  'code': 'JHN',
  'name': 'Juan',
  'chapters': [
    {
      'n': 1,
      'footnotes': {
        'a': {'label': 'a', 'text': 'Cf. el texto griego.'},
      },
      'blocks': [
        {'type': 'heading', 'text': 'Evangelio según Juan', 'style': 'section'},
        {'type': 'chapterNumber', 'value': 1},
        {
          'type': 'verseGroup',
          'verses': [
            {
              'n': 1,
              'inlines': [
                {'t': 'text', 'v': 'EN el principio era el Verbo.'},
                {'t': 'footnote', 'id': 'a', 'label': 'a'},
                {'t': 'xref', 'label': '1', 'ref': 'GEN.1.1'},
              ],
            },
            {
              'n': 2,
              'inlines': [
                {'t': 'text', 'v': 'Este era en el principio con Dios.'},
              ],
            },
          ],
        },
        {
          'type': 'verseGroup',
          'style': 'poetry',
          'indent': 1,
          'verses': [
            {
              'n': 3,
              'inlines': [
                {'t': 'text', 'v': 'Todas las cosas por él fueron hechas.'},
              ],
            },
          ],
        },
      ],
    },
  ],
});

class _FormatRepository implements DocumentRepository {
  @override
  Future<DocumentManifest> loadManifest(String resourceId) async => _manifest;

  @override
  Future<BookDocument> loadBook(String resourceId, String code) async => _jhn;
}

// ------------------------------------------------------------------ utilidades

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: const AletheiaApp(),
    );

ProviderContainer _container() => ProviderContainer(
      overrides: [
        workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
        catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
        documentRepositoryProvider.overrideWithValue(_FormatRepository()),
      ],
    );

void _setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

/// Texto plano de los `Text` (incluidos los `Text.rich`).
String _plain(Widget widget) {
  final text = widget as Text;
  return text.textSpan?.toPlainText() ?? text.data ?? '';
}

/// Textos planos que contienen [needle].
List<String> _textsWith(WidgetTester tester, String needle) => tester
    .widgetList<Text>(find.byType(Text))
    .map(_plain)
    .where((s) => s.contains(needle))
    .toList();

WorkspaceTab _bibleTab(ProviderContainer container) => container
    .read(workspaceProvider)
    .tiles
    .expand((t) => t.tabs)
    .firstWhere((t) => t.kind == PanelKind.bible);

TabDisplay _display(ProviderContainer container) =>
    _bibleTab(container).display;

/// Abre el lector con el documento sintético y espera a que pinte.
///
/// Ventana ancha: la barra del lector tiene desplazamiento horizontal y con
/// poco ancho los botones de modo quedan fuera.
Future<ProviderContainer> _pumpReader(WidgetTester tester) async {
  _setWindow(tester, const Size(2200, 1000));
  final container = _container();
  addTearDown(container.dispose);
  container.read(workspaceProvider.notifier).openTab(const TabSpec(
        kind: PanelKind.bible,
        title: 'RV1909',
        reference: 'JHN.1.1',
        resourceId: _resourceId,
      ));
  await tester.pumpWidget(_app(container));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Interruptor dentro de una fila del flyout (el centro de la fila cae en la
/// etiqueta, no en el control).
Finder _switchInside(Key key) => find.descendant(
      of: find.byKey(key),
      matching: find.byType(Switch),
    );

/// Deja correr el guardado diferido del controlador de espacio de trabajo
/// (400 ms) para que la prueba no termine con temporizadores pendientes.
Future<void> _flushSave(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 500));

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];

  // -------------------------------------------------------------- citas

  test('estilos de cita y enlaces', () {
    String cite(String style, {bool hyperlink = false}) => formatCitation(
          reference: 'Juan 1:1',
          title: 'Biblia de prueba',
          abbrev: 'RV1909',
          style: style,
          hyperlink: hyperlink,
          canonical: 'JHN.1.1',
        );

    expect(cite('turabian'), 'Juan 1:1 (Biblia de prueba).');
    expect(cite('chicago'), 'Juan 1:1 (RV1909).');
    expect(cite('sbl'), 'Juan 1:1 (RV1909)');
    expect(cite('plain'), 'Juan 1:1 — RV1909');
    expect(
      cite('turabian', hyperlink: true),
      '[Juan 1:1 (Biblia de prueba).](ref:JHN.1.1)',
    );
  });

  // ----------------------------------------------------------- Formato

  testWidgets('el reformato afecta de verdad al texto', (tester) async {
    final container = await _pumpReader(tester);

    // Por defecto (sin reformato): párrafo continuo, números y notas.
    expect(_textsWith(tester, 'EN el principio era el Verbo'), hasLength(1));
    expect(
      _textsWith(tester, 'EN el principio era el Verbo').single,
      contains('Este era en el principio'),
    );
    expect(find.text('2'), findsOneWidget); // número del versículo 2

    // Formato ▸ Reformato.
    await _tap(tester, find.byKey(const ValueKey('reader-mode-format')));
    await _tap(tester, find.byKey(const ValueKey('reader-reformat')));
    expect(find.text('Reformato del texto'), findsWidgets);
    final reformatSwitch = _switchInside(const ValueKey('reader-reformat-switch'));
    expect(reformatSwitch, findsOneWidget);
    await _tap(tester, reformatSwitch);
    expect(_display(container).reformat, isTrue);

    // Números de capítulo y versículo fuera.
    await _tap(tester, find.text('Números de capítulo y versículo'));
    expect(_display(container).numbers, isFalse);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);

    // Un versículo por línea: cada versículo es su propio párrafo.
    await _tap(tester, find.text('Números de capítulo y versículo'));
    expect(_display(container).numbers, isTrue);
    await _tap(tester, find.text('Un versículo por línea'));
    expect(_display(container).oneVersePerLine, isTrue);
    final lines = _textsWith(tester, 'principio');
    expect(lines, hasLength(2));
    expect(lines.where((s) => s.contains('Verbo') && s.contains('Dios')),
        isEmpty);

    // Interruptor maestro: vuelve al formato del recurso.
    await _tap(tester, reformatSwitch);
    expect(_display(container).reformat, isFalse);
    expect(_textsWith(tester, 'EN el principio era el Verbo'), hasLength(1));
    expect(find.text('2'), findsOneWidget);
    await _flushSave(tester);
  });

  testWidgets('la vista limitada desactiva la paginación y lista las notas',
      (tester) async {
    final container = await _pumpReader(tester);
    container.read(workspaceProvider.notifier).setLimitedView(true);
    await tester.pumpAndSettle();

    // Nota al pie como lista al final del capítulo (Ajustes 8.4).
    expect(find.text('Notas al pie'), findsOneWidget);
    expect(_textsWith(tester, 'Cf. el texto griego.'), isNotEmpty);

    // Con el modo accesible la vista paginada no se activa.
    container.read(workspaceProvider.notifier).updateTabDisplay(
          tileId: container.read(workspaceProvider).tiles.first.id,
          tabId: _bibleTab(container).id,
          display: _display(container).copyWith(paged: true),
        );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-pages')), findsNothing);
    expect(find.byKey(const ValueKey('reader-reference-box')), findsOneWidget);
    await _flushSave(tester);
  });

  // ------------------------------------------------------------- Vista

  testWidgets('vista: zoom, barra de ubicación y vista paginada',
      (tester) async {
    final container = await _pumpReader(tester);

    await _tap(tester, find.byKey(const ValueKey('reader-mode-view')));
    expect(find.text('Barra de ubicación'), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-hide-location-bar')),
        findsOneWidget);

    // Zoom.
    expect(find.text('100%'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('reader-zoom-in')));
    expect(_display(container).zoom, 110);
    expect(find.text('110%'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('reader-zoom-out')));
    expect(_display(container).zoom, 100);

    // Barra de ubicación.
    await _tap(tester, find.byKey(const ValueKey('reader-locator-bar')));
    expect(_display(container).locationBar, isFalse);
    expect(find.byKey(const ValueKey('reader-hide-location-bar')),
        findsNothing);

    // Vista paginada (flyout + switch).
    await _tap(tester, find.byKey(const ValueKey('reader-paged-view')));
    expect(find.text('Columnas'), findsOneWidget);
    await _tap(tester, _switchInside(const ValueKey('reader-paged-switch')));
    expect(_display(container).paged, isTrue);
    expect(find.byKey(const ValueKey('reader-pages')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('reader-page-indicator')))
          .data,
      'Página 1 de 1',
    );

    // Atajo Ctrl+Shift+P: la apaga.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(_display(container).paged, isFalse);
    expect(find.byKey(const ValueKey('reader-pages')), findsNothing);
    await _flushSave(tester);
  });

  // ----------------------------------------------------------- Ajustes

  testWidgets('ajustes: idioma, ubicación de la barra y restablecer',
      (tester) async {
    _setWindow(tester, const Size(1400, 900));
    final container = _container();
    addTearDown(container.dispose);
    container.read(workspaceProvider.notifier).openTab(
          const TabSpec(kind: PanelKind.settings),
        );
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    // Español por defecto (idioma de diseño del clon).
    expect(container.read(workspaceProvider).locale, 'es');
    expect(find.text('Activar el modo de vista limitada'), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);

    // English: la interfaz completa cambia de idioma (desplegable).
    await _tap(tester, find.byKey(const ValueKey('settings-language')));
    await _tap(tester, find.text('English').last);
    expect(find.text('Enable limited view mode'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Activar el modo de vista limitada'), findsNothing);

    // Sistema: vuelve al idioma de la plataforma (español en las pruebas).
    await _tap(tester, find.byKey(const ValueKey('settings-language')));
    await _tap(tester, find.text('System').last);
    expect(find.text('Activar el modo de vista limitada'), findsOneWidget);

    // Barra de aplicaciones arriba.
    await _tap(tester, find.text('Arriba'));
    expect(find.byKey(const ValueKey('top-nav-bar')), findsOneWidget);
    expect(find.byTooltip('Colapsar barra lateral'), findsNothing);

    // Restablecer valores vuelve a la izquierda y a los valores por defecto.
    await _tap(tester, find.byKey(const ValueKey('settings-reset')));
    expect(find.byKey(const ValueKey('top-nav-bar')), findsNothing);
    expect(find.byTooltip('Colapsar barra lateral'), findsOneWidget);
    await _flushSave(tester);
  });

  testWidgets('copiar cita respeta el estilo y el enlace', (tester) async {
    final clipboard = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final container = await _pumpReader(tester);

    Future<void> copyCitation() async {
      await _tap(tester, find.byKey(const ValueKey('reader-more-menu')));
      await _tap(tester, find.text('Copiar cita'));
    }

    // Estilo por defecto (Turabian): nota completa con el título del recurso.
    await copyCitation();
    expect(clipboard.last, 'Juan 1:1 (Biblia de prueba).');

    // Estilo simple + enlaces internos.
    container
        .read(workspaceProvider.notifier)
        .setCitationSettings(style: 'plain', hyperlink: true);
    await tester.pumpAndSettle();
    await copyCitation();
    expect(clipboard.last, '[Juan 1:1 — RV1909](ref:JHN.1.1)');
    await _flushSave(tester);
  });
}
