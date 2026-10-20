// Prueba de integración sobre el binario Linux real: arranca la app completa
// (assets vía rootBundle, path_provider, SQLite en disco) y comprueba que el
// workspace y las notas guardados sobreviven a un relanzamiento.
//
// Ejecutar:  flutter test integration_test/persistence_test.dart -d linux
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aletheia/core/database.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Idioma de diseño del clon (M3): las expectativas de texto son en español.
  TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];

  testWidgets('el workspace sobrevive a un relanzamiento', (tester) async {
    // Base temporal propia del test: no se toca la del usuario.
    final dbPath = await _tempDatabasePath();

    var launches = 0;
    Future<void> launch() async {
      launches++;
      final database = AletheiaDatabase.open(dbPath);
      await tester.pumpWidget(
        ProviderScope(
          // Key distinta por arranque: obliga a crear un contenedor de
          // providers nuevo que lea el estado desde SQLite.
          key: ValueKey('launch-$launches'),
          overrides: [
            workspaceStoreProvider
                .overrideWithValue(WorkspaceStore.onDatabase(database)),
            notesStoreProvider.overrideWithValue(NotesStore.onDatabase(database)),
          ],
          child: const AletheiaApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Primer arranque: sin estado previo.
    await launch();
    expect(find.textContaining('Sin pestañas'), findsWidgets);

    // La Biblia del sidebar abre el lector y carga los assets reales.
    await tester.tap(find.byKey(const ValueKey('nav-bible')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-reference-box')), findsOneWidget);
    expect(find.textContaining('EN el principio crió Dios', findRichText: true),
        findsOneWidget);

    // El guardado del workspace tiene un debounce de 400 ms.
    final saved = await _waitForBibleTab(dbPath);
    final bible = saved.tiles
        .expand((tile) => tile.tabs)
        .firstWhere((tab) => tab.kind.name == 'bible');
    expect(bible.reference, 'GEN.1.1');
    expect(bible.history, contains('GEN.1.1'));

    // Segundo arranque: el lector se restaura desde SQLite, sin tocar nada.
    await launch();
    expect(find.textContaining('EN el principio crió Dios', findRichText: true),
        findsOneWidget);
  });

  testWidgets('las notas sobreviven a un relanzamiento', (tester) async {
    // Base temporal propia del test: no se toca la del usuario.
    final dbPath = await _tempDatabasePath();

    var launches = 0;
    Future<void> launch() async {
      launches++;
      final database = AletheiaDatabase.open(dbPath);
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey('notes-launch-$launches'),
          overrides: [
            workspaceStoreProvider
                .overrideWithValue(WorkspaceStore.onDatabase(database)),
            notesStoreProvider.overrideWithValue(NotesStore.onDatabase(database)),
          ],
          child: const AletheiaApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    await launch();

    // Abre el panel de Notas y crea una nota con título.
    await tester.tap(find.byKey(const ValueKey('nav-notes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notes-new-note')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('note-title-field')), 'Nota de prueba M4');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-title-field')), findsOneWidget);

    // Debounce del editor (300 ms) + guardado en la base (400 ms).
    await _waitForNote(dbPath, 'Nota de prueba M4');

    // Segundo arranque: el panel de Notas se restaura y la nota sigue ahí.
    await launch();
    expect(find.text('Nota de prueba M4'), findsOneWidget);
  });
}

/// Crea una base temporal para el test (se borra al terminar) y devuelve su
/// ruta: así nunca se toca el `aletheia.db` real del usuario.
Future<String> _tempDatabasePath() async {
  final dir = await Directory.systemTemp.createTemp('aletheia-it');
  addTearDown(() => dir.delete(recursive: true));
  return '${dir.path}/aletheia.db';
}

/// Espera (hasta 5 s) a que la app guarde el workspace con la pestaña de
/// Biblia y devuelve el estado guardado.
Future<WorkspaceState> _waitForBibleTab(String dbPath) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    AletheiaDatabase? db;
    try {
      db = AletheiaDatabase.open(dbPath);
      final state = db.loadWorkspace();
      if (state != null) {
        final hasBible = state.tiles
            .any((tile) => tile.tabs.any((tab) => tab.kind.name == 'bible'));
        if (hasBible) return state;
      }
    } catch (_) {
      // Base a medio escribir: reintentar.
    } finally {
      db?.close();
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  throw StateError('La app no guardó la pestaña de Biblia en $dbPath');
}

/// Espera (hasta 5 s) a que la nota con [title] esté guardada en la base.
Future<void> _waitForNote(String dbPath, String title) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    AletheiaDatabase? db;
    try {
      db = AletheiaDatabase.open(dbPath);
      if (db.loadNotes().notes.any((note) => note.title == title)) return;
    } catch (_) {
      // Base a medio escribir: reintentar.
    } finally {
      db?.close();
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  throw StateError('La app no guardó la nota "$title" en $dbPath');
}
