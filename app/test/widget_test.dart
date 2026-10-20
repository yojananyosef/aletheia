import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/references/reference_parser.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/notes/notes_persistence.dart';

Widget _app() => ProviderScope(
      overrides: [
        workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
      ],
      child: const AletheiaApp(),
    );

void _setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  // El clon tiene el español como idioma de diseño: se fija el idioma de la
  // plataforma para que las expectativas de los textos no dependan del
  // entorno (M3).
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];
  test('parser de referencias', () {
    expect(parseReference('Jn 1:1')?.canonical, 'JHN.1.1');
    expect(parseReference('Juan 1:1-3')?.canonical, 'JHN.1.1-3');
    expect(parseReference('Romanos 8:28')?.canonical, 'ROM.8.28');
    expect(parseReference('1 Corintios 13:4')?.canonical, '1CO.13.4');
    expect(parseReference('Salmos 23')?.canonical, 'PSA.23');
    expect(parseReference('sanjuan 3:16')?.canonical, 'JHN.3.16');
    expect(parseReference('JHN.1.1')?.canonical, 'JHN.1.1');
    expect(parseReference('amor al prójimo'), isNull);
    expect(displayFromCanonical('JHN.1.1'), 'Juan 1:1');
  });

  test('estado fresco usa el layout de dos columnas', () {
    final state = WorkspaceState.fresh();
    expect(state.layoutId, 'two');
    expect(state.tiles.length, 2);
  });

  testWidgets('smoke: shell y sidebar en ventana amplia', (tester) async {
    _setWindow(tester, const Size(1532, 834));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Cerrar todas las pestañas'), findsOneWidget);
    expect(find.text('Acciones rápidas'), findsOneWidget);
  });

  testWidgets('sin overflow en distintos tamaños de ventana', (tester) async {
    for (final size in const [
      Size(1532, 834),
      Size(1100, 700),
      Size(880, 640),
      Size(760, 600),
      Size(560, 520),
      Size(420, 480),
      Size(320, 400),
    ]) {
      _setWindow(tester, size);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'overflow a $size');
    }
  });

  testWidgets('los tiles nunca se apilan: se ocultan los que no caben',
      (tester) async {
    _setWindow(tester, const Size(1532, 834));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final wide0 = tester.getTopLeft(find.byKey(const ValueKey('tile-tile_0')));
    final wide1 = tester.getTopLeft(find.byKey(const ValueKey('tile-tile_1')));
    expect(wide1.dy, wide0.dy, reason: 'en ventana amplia van lado a lado');
    expect(wide1.dx, greaterThan(wide0.dx));

    // Ventana angosta: igual que el original, no se apilan; se muestran solo
    // los tiles que caben con el mínimo legible.
    tester.view.physicalSize = const Size(560, 700);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tile-tile_1')), findsNothing,
        reason: 'el tile que no cabe se oculta, no se apila');
    final narrow0 = tester.getRect(find.byKey(const ValueKey('tile-tile_0')));
    expect(narrow0.width, greaterThanOrEqualTo(320 - 0.5),
        reason: 'el tile visible conserva el mínimo legible');
    expect(tester.takeException(), isNull);

    // Al ensanchar, el tile oculto vuelve a su sitio.
    tester.view.physicalSize = const Size(1532, 834);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tile-tile_1')), findsOneWidget);
  });
}
