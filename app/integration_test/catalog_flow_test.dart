// Prueba de integración de M2 sobre el binario Linux real: la app completa
// contra el servicio de catálogo (HTTP de verdad). Comprueba el flujo
// Biblioteca → lector con la KJV —que solo existe en el servicio, no en los
// assets de la app— y una búsqueda real que abre el resultado en el lector.
//
// El servicio se levanta automáticamente si no está corriendo en :8787.
//
// Ejecutar:  flutter test integration_test/catalog_flow_test.dart -d linux
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'support/catalog_fixture.dart';

const _baseUrl = 'http://127.0.0.1:8787';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Idioma de diseño del clon (M3): las expectativas de texto son en español.
  TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];

  testWidgets('biblioteca y búsqueda contra el servicio de catálogo real',
      (tester) async {
    final service = await _Service.ensure();
    addTearDown(service.dispose);

    // Workspace en memoria con el estado inicial real (tiles del layout):
    // no toca el del usuario y usa la dirección por defecto del catálogo.
    final store = WorkspaceStore.inMemory();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogDiskOverride,
        workspaceStoreProvider.overrideWithValue(store),
        notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
      ],
      child: const AletheiaApp(),
    ));
    await tester.pumpAndSettle();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

    // --- Biblioteca: los recursos llegan del servicio -------------------
    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await _pumpUntilAny(tester, [
      find.byKey(const ValueKey('library-list')),
      find.textContaining('No se pudo consultar'),
      find.textContaining('Sin recursos'),
    ]);
    debugPrint('TEXTOS CON LA BIBLIOTECA ABIERTA: ${_visibleTexts(tester)}');
    await _waitFor(tester, find.text('King James Version'));
    expect(find.text('14 recursos'), findsOneWidget);
    expect(find.text('Reina-Valera 1909'), findsOneWidget);
    expect(find.text('Matthew Henry — Comentario conciso'), findsOneWidget);
    expect(find.text('Diccionario bíblico de Easton'), findsOneWidget);

    // Abrir la KJV: su contenido solo puede venir del servicio.
    await tester.tap(find.byKey(const ValueKey('library-row-bible.kjv')));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(find.byKey(const ValueKey('library-open')));
    await _waitFor(
      tester,
      find.textContaining('In the beginning God created', findRichText: true),
    );

    var bible = _bibleTab(container);
    expect(bible.resourceId, 'bible.kjv');
    expect(bible.reference, 'GEN.1.1');

    // --- Búsqueda real: frase, resultados y apertura ---------------------
    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await _waitFor(tester, find.byKey(const ValueKey('search-field')));
    await tester.enterText(
        find.byKey(const ValueKey('search-field')), '"In the beginning"');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    await _waitFor(tester, find.text('John 1:2'));
    expect(find.textContaining('resultados para'), findsOneWidget);
    expect(find.text('Genesis 1:1'), findsWidgets);

    await tester.tap(find.text('John 1:2'));
    await _waitFor(
      tester,
      find.textContaining('The same was in the beginning with God.',
          findRichText: true),
    );

    bible = _bibleTab(container);
    expect(bible.resourceId, 'bible.kjv');
    expect(bible.reference, 'JHN.1.2');

    // Historial de la pestaña de búsqueda.
    final searchTab = container
        .read(workspaceProvider)
        .tiles
        .expand((tile) => tile.tabs)
        .firstWhere((tab) => tab.kind == PanelKind.search);
    expect(searchTab.history, ['"In the beginning"']);

    // --- Búsqueda dentro del panel del lector (modo «Buscar») ------------
    // La barra del lector se desplaza en horizontal cuando el panel es
    // estrecho: hay que asegurar el botón antes de pulsarlo.
    await tester.ensureVisible(find.byTooltip('Buscar en este recurso'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buscar en este recurso'));
    await _waitFor(tester, find.byKey(const ValueKey('reader-search-field')));
    await tester.enterText(
        find.byKey(const ValueKey('reader-search-field')), 'beginning');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _waitFor(
      tester,
      find.byKey(const ValueKey('reader-search-results-beginning')),
    );
    expect(find.textContaining('resultados para «beginning»'), findsWidgets);

    // Tocar un resultado navega el panel a ese versículo.
    final hitFinder = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('reader-search-hit-');
    });
    expect(hitFinder, findsWidgets);
    final hitRef = ((tester.widget(hitFinder.first).key as ValueKey<String>)
            .value)
        .replaceFirst('reader-search-hit-', '');
    await tester.tap(hitFinder.first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_bibleTab(container).reference, hitRef);

    // --- Abrir la RV1909 no roba la pestaña de la KJV --------------------
    // (regresión: antes la pestaña existente cambiaba de recurso y el panel
    // seguía mostrando el texto anterior)
    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await _waitFor(tester, find.text('Reina-Valera 1909'));
    await tester.tap(find.byKey(const ValueKey('library-row-bible.rv1909')));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(find.byKey(const ValueKey('library-open')));
    await _waitFor(
      tester,
      find.textContaining('EN el principio crió Dios', findRichText: true),
    );

    final bibles = container
        .read(workspaceProvider)
        .tiles
        .expand((tile) => tile.tabs)
        .where((tab) => tab.kind == PanelKind.bible)
        .toList();
    expect(bibles.length, 2);
    expect(
      bibles.map((tab) => tab.resourceId).toSet(),
      {'bible.kjv', 'bible.rv1909'},
    );

    // --- M5: Devocional, Factbook y Comparación de textos ----------------
    // Devocional: la acción rápida abre la lectura de hoy.
    await tester.ensureVisible(find.byKey(const ValueKey('quick-devotional')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-devotional')));
    await _waitFor(tester, find.byKey(const ValueKey('devotional-body')));
    expect(find.byKey(const ValueKey('devotional-date')), findsOneWidget);

    // Factbook: buscar un tema y abrir el artículo con sus referencias.
    await tester.ensureVisible(find.byKey(const ValueKey('nav-topics')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-topics')));
    await _waitFor(tester, find.byKey(const ValueKey('factbook-topics')));
    await tester.enterText(
        find.byKey(const ValueKey('factbook-search')), 'Jesucristo');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('factbook-topic-jesucristo')));
    await _waitFor(tester, find.text('Referencias'));
    expect(find.byKey(const ValueKey('factbook-back')), findsOneWidget);

    // Comparación de textos: la RV1909 (local) y la KJV (servicio).
    await tester.ensureVisible(find.byKey(const ValueKey('quick-compare')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-compare')));
    await _waitFor(tester, find.byKey(const ValueKey('compare-body')));
    expect(find.text('KJV'), findsWidgets);
    expect(find.text('RV1909'), findsWidgets);
    expect(
      find.byKey(const ValueKey('compare-single-version')),
      findsNothing,
    );
  });
}

WorkspaceTab _bibleTab(ProviderContainer container) => container
    .read(workspaceProvider)
    .tiles
    .expand((tile) => tile.tabs)
    .firstWhere((tab) => tab.kind == PanelKind.bible);

/// Sondea la UI hasta que aparezca [finder] (los `pump` de la zona real dejan
/// correr temporizadores y E/S de verdad).
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 25),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('No apareció en pantalla: $finder\n'
      'Textos visibles: ${_visibleTexts(tester)}');
}

/// Sondea hasta que aparezca cualquiera de [finders] (diagnóstico).
Future<void> _pumpUntilAny(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 25),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finders.any((finder) => finder.evaluate().isNotEmpty)) return;
  }
}

/// Texto de todos los `Text` montados (para depurar fallos).
List<String> _visibleTexts(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
    .where((value) => value.trim().isNotEmpty)
    .toList();

/// Servicio de catálogo: usa el que ya corre o lo levanta desde el repo.
class _Service {
  _Service._(this.process);

  final Process? process;

  static Future<_Service> ensure() async {
    if (await _healthy()) return _Service._(null);

    // `flutter test` corre con cwd = app/; la raíz del repo es la superior.
    final root = Directory.current.parent.path;
    final process = await Process.start(
      'python3',
      ['catalog/server/catalog_server.py', '--port', '8787'],
      workingDirectory: root,
    );
    process.stdout.transform(utf8.decoder).listen(stdout.write);
    process.stderr.transform(utf8.decoder).listen(stderr.write);

    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(deadline)) {
      if (await _healthy()) return _Service._(process);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    process.kill();
    throw StateError('El servicio de catálogo no respondió en $_baseUrl '
        '(¿falta `python3 catalog/tools/build_catalog.py`?)');
  }

  Future<void> dispose() async {
    final running = process;
    if (running == null) return;
    running.kill();
    try {
      await running.exitCode;
    } catch (_) {
      // Ya estaba terminado.
    }
  }

  static Future<bool> _healthy() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final request = await client.getUrl(Uri.parse('$_baseUrl/v1/health'));
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
