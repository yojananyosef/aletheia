import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/notes/notes_persistence.dart';

// --------------------------------------------------------------- utilidades

/// Repositorio de prueba que lee los assets reales desde disco con E/S
/// síncrona: los `pumpAndSettle` de widget tests no esperan E/S real
/// (zona de async falso), así que la carga debe resolverse en microtasks.
class _DiskRepository extends DocumentRepository {
  static const _root = 'assets/catalog/rv1909';

  static String _read(String path) {
    final plain = File(path);
    if (plain.existsSync()) return plain.readAsStringSync();
    return utf8.decode(gzip.decode(File('$path.gz').readAsBytesSync()));
  }

  @override
  Future<DocumentManifest> loadManifest(String resourceId) async =>
      DocumentManifest.fromJson(
        jsonDecode(_read('$_root/manifest.json')) as Map<String, dynamic>,
      );

  @override
  Future<BookDocument> loadBook(String resourceId, String code) async =>
      BookDocument.fromJson(
        jsonDecode(_read('$_root/books/$code.json')) as Map<String, dynamic>,
      );
}

Widget _app({DocumentRepository? repository}) => ProviderScope(
  overrides: [
    workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
    notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
    documentRepositoryProvider.overrideWithValue(
      repository ?? _DiskRepository(),
    ),
  ],
  child: const AletheiaApp(),
);

void _setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _openBible(WidgetTester tester) async {
  await tester.tap(find.text('Biblia'));
  await tester.pumpAndSettle();
}

Future<void> _goTo(WidgetTester tester, String reference) async {
  await tester.enterText(
    find.byKey(const ValueKey('reader-reference-box')),
    reference,
  );
  await tester.testTextInput.receiveAction(TextInputAction.go);
  await tester.pumpAndSettle();
}

Finder _richText(String text) => find.textContaining(text, findRichText: true);

// ---------------------------------------------------- documento sintético

class _FakeRepository extends DocumentRepository {
  static final DocumentManifest _manifest = DocumentManifest.fromJson({
    'resourceId': 'bible.rv1909',
    'title': 'Biblia de prueba',
    'abbrev': 'TST',
    'language': 'es',
    'source': 'test',
    'license': 'test',
    'books': [
      {
        'code': 'GEN',
        'name': 'Génesis',
        'chapters': [
          {'n': 1, 'verses': 1},
        ],
      },
      {
        'code': 'JHN',
        'name': 'Juan',
        'chapters': [
          {'n': 1, 'verses': 2},
        ],
      },
      {
        'code': 'PSA',
        'name': 'Salmos',
        'chapters': [
          {'n': 23, 'verses': 1},
        ],
      },
    ],
  });

  static final Map<String, Map<String, dynamic>> _books = {
    'GEN': {
      'code': 'GEN',
      'name': 'Génesis',
      'chapters': [
        {
          'n': 1,
          'blocks': [
            {'type': 'chapterNumber', 'value': 1},
            {
              'type': 'verseGroup',
              'verses': [
                {
                  'n': 1,
                  'inlines': [
                    {'t': 'text', 'v': 'Texto de Génesis 1:1.'},
                  ],
                },
              ],
            },
          ],
        },
      ],
    },
    'JHN': {
      'code': 'JHN',
      'name': 'Juan',
      'chapters': [
        {
          'n': 1,
          'footnotes': {
            'fn.1': {'label': 'a', 'text': 'Cf. la nota del traductor.'},
          },
          'blocks': [
            {'type': 'chapterNumber', 'value': 1},
            {
              'type': 'verseGroup',
              'verses': [
                {
                  'n': 1,
                  'inlines': [
                    {'t': 'text', 'v': 'En el principio era el Verbo, '},
                    {'t': 'span', 'style': 'italic', 'v': 'la Palabra'},
                    {'t': 'text', 'v': '. '},
                    {'t': 'footnote', 'id': 'fn.1', 'label': 'a'},
                    {'t': 'text', 'v': ' '},
                    {'t': 'xref', 'ref': 'PSA.23.1', 'label': 'Sal 23:1'},
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
          ],
        },
      ],
    },
    'PSA': {
      'code': 'PSA',
      'name': 'Salmos',
      'chapters': [
        {
          'n': 23,
          'blocks': [
            {'type': 'chapterNumber', 'value': 23},
            {
              'type': 'verseGroup',
              'verses': [
                {
                  'n': 1,
                  'inlines': [
                    {'t': 'text', 'v': 'JEHOVÁ es mi pastor.'},
                  ],
                },
              ],
            },
          ],
        },
      ],
    },
  };

  @override
  Future<DocumentManifest> loadManifest(String resourceId) async => _manifest;

  @override
  Future<BookDocument> loadBook(String resourceId, String code) async {
    final raw = _books[code];
    if (raw == null) throw StateError('sin datos de prueba para $code');
    return BookDocument.fromJson(raw);
  }
}

// ------------------------------------------------------------------- tests

void main() {
  // El clon tiene el español como idioma de diseño: se fija el idioma de la
  // plataforma para que las expectativas de los textos no dependan del
  // entorno (M3).
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];
  testWidgets('lector: abre la Biblia y navega con la caja de referencia', (
    tester,
  ) async {
    _setWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await _openBible(tester);
    expect(
      find.textContaining('EN el principio crió Dios', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Génesis'), findsOneWidget); // barra de ubicación

    await _goTo(tester, 'Juan 1:1');
    expect(_richText('EN el principio era el Verbo'), findsOneWidget);
    // La barra de ubicación usa el título del artículo («San Juan»); la cita
    // de la caja de referencia sigue siendo «Juan 1:1».
    expect(find.text('San Juan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('índice: muestra el árbol libro → capítulos y navega', (
    tester,
  ) async {
    _setWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _openBible(tester);
    await _goTo(tester, 'Juan 1:1');

    await tester.tap(find.text('Índice'));
    await tester.pumpAndSettle();
    expect(find.text('Índice de contenidos'), findsOneWidget);
    expect(find.text('Capítulo 1'), findsOneWidget);
    expect(find.text('Capítulo 21'), findsOneWidget);

    await tester.tap(find.text('Capítulo 2'));
    await tester.pumpAndSettle();
    expect(find.text('Juan 2'), findsOneWidget); // caja de referencia
    expect(_richText('Y AL tercer día'), findsOneWidget);
  });

  testWidgets('historial: registra visitas y permite volver', (tester) async {
    _setWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _openBible(tester);
    await _goTo(tester, 'Juan 1:1');

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('Historial del panel'), findsOneWidget);
    expect(find.text('Génesis 1:1'), findsOneWidget);

    await tester.tap(find.text('Génesis 1:1'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('EN el principio crió Dios', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Génesis 1:1'), findsOneWidget); // caja de referencia
  });

  testWidgets('toolbar: steppers de capítulo y referencia inválida', (
    tester,
  ) async {
    _setWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _openBible(tester);
    await _goTo(tester, 'Juan 1:1');

    await tester.tap(find.byTooltip('Capítulo siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Juan 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Capítulo anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Juan 1'), findsOneWidget);

    await _goTo(tester, 'no es una referencia');
    // la entrada inválida se revierte al perder el foco (caja renormalizada)
    expect(find.text('Juan 1'), findsOneWidget);
    expect(_richText('EN el principio era el Verbo'), findsOneWidget);
  });

  testWidgets('notas al pie, itálicas y cross-refs (documento sintético)', (
    tester,
  ) async {
    _setWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(_app(repository: _FakeRepository()));
    await tester.pumpAndSettle();
    await _openBible(tester);
    await _goTo(tester, 'Juan 1:1');

    expect(_richText('En el principio era el Verbo'), findsOneWidget);

    // La palabra añadida se renderiza en cursiva.
    final rich = tester.widget<RichText>(
      find
          .byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('la Palabra'),
          )
          .first,
    );
    var italic = false;
    rich.text.visitChildren((span) {
      if (span is TextSpan &&
          span.text == 'la Palabra' &&
          span.style?.fontStyle == FontStyle.italic) {
        italic = true;
        return false;
      }
      return true;
    });
    expect(italic, isTrue, reason: 'la adición debe ir en cursiva');

    // Nota al pie: abre la tarjeta con el texto (clic la fija). El marcador
    // es un asterisco al final del versículo (v1.0.3: la «a» se confundía
    // con texto y quedaba junto al número).
    await tester.tap(find.text('*'));
    await tester.pumpAndSettle();
    expect(find.text('Nota *'), findsOneWidget);
    expect(find.text('Cf. la nota del traductor.'), findsOneWidget);
    await tester.tapAt(const Offset(20, 6)); // clic fuera descarta (fijada)
    await tester.pumpAndSettle();
    expect(find.text('Nota *'), findsNothing);

    // Cross-ref: navega a la referencia.
    await tester.tap(find.text('Sal 23:1'));
    await tester.pumpAndSettle();
    expect(find.text('Salmos 23:1'), findsOneWidget);
    expect(_richText('JEHOVÁ es mi pastor'), findsOneWidget);
  });

  testWidgets('nota al pie: vista previa en hover y fijado por clic', (
    tester,
  ) async {
    _setWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(_app(repository: _FakeRepository()));
    await tester.pumpAndSettle();
    await _openBible(tester);
    await _goTo(tester, 'Juan 1:1');

    // Hover con el ratón: tras la demora breve aparece la tarjeta.
    final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await hover.addPointer(location: Offset.zero);
    await hover.moveTo(tester.getCenter(find.text('*')));
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.text('Nota *'), findsOneWidget);
    expect(find.text('Cf. la nota del traductor.'), findsOneWidget);

    // Al salir del marcador, la tarjeta (sin fijar) se cierra.
    await hover.moveTo(const Offset(40, 620));
    await tester.pump();
    expect(find.text('Nota *'), findsNothing);

    // Con clic queda fijada: salir del marcador no la cierra, el segundo
    // clic sobre el mismo marcador sí.
    await tester.tap(find.text('*'));
    await tester.pumpAndSettle();
    expect(find.text('Nota *'), findsOneWidget);
    await hover.moveTo(const Offset(40, 620));
    await tester.pump();
    expect(find.text('Nota *'), findsOneWidget);
    await tester.tap(find.text('*'));
    await tester.pumpAndSettle();
    expect(find.text('Nota *'), findsNothing);
  });

  testWidgets('nota al pie: la tarjeta queda dentro del viewport', (
    tester,
  ) async {
    _setWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(_app(repository: _FakeRepository()));
    await tester.pumpAndSettle();
    await _openBible(tester);
    await _goTo(tester, 'Juan 1:1');

    // El indicador se difiere al final del versículo (tras «Sal 23:1»; los
    // WidgetSpan no aportan texto plano, así que se compara por posición).
    await tester.tap(find.text('*'));
    await tester.pumpAndSettle();
    final marker = tester.getCenter(find.text('*'));
    final xref = tester.getCenter(find.text('Sal 23:1'));
    final afterXref =
        marker.dx > xref.dx || (marker.dy > xref.dy + 10.0); // o en línea nueva
    expect(afterXref, isTrue, reason: 'el marcador va al final del versículo');
    final card = tester.getRect(find.byKey(const ValueKey('footnote-card')));
    expect(card.left, greaterThanOrEqualTo(0.0));
    expect(card.top, greaterThanOrEqualTo(0.0));
    expect(card.right, lessThanOrEqualTo(1400.0));
    expect(card.bottom, lessThanOrEqualTo(900.0));
  });
}
