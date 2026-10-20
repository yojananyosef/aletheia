import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'core/database.dart';
import 'core/localization.dart';
import 'core/theme.dart';
import 'notes/notes_persistence.dart';
import 'reading_plans/reading_plans_persistence.dart';
import 'shell/shell.dart';
import 'workspace/persistence.dart';
import 'workspace/workspace_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Persistencia local-first en un único archivo SQLite (M4.3).
  final dir = await getApplicationSupportDirectory();
  final database = AletheiaDatabase.open('${dir.path}/aletheia.db');
  await AletheiaDatabase.importLegacyJson(database, dir);

  final store = WorkspaceStore.onDatabase(database);
  final notes = NotesStore.onDatabase(database);
  final readingPlans = ReadingPlansStore.onDatabase(database);
  runApp(
    ProviderScope(
      overrides: [
        workspaceStoreProvider.overrideWithValue(store),
        notesStoreProvider.overrideWithValue(notes),
        readingPlansStoreProvider.overrideWithValue(readingPlans),
      ],
      child: const AletheiaApp(),
    ),
  );
}

class AletheiaApp extends ConsumerWidget {
  const AletheiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Idioma de la interfaz (Ajustes 8.5): `null` = el del sistema.
    final state = ref.watch(workspaceProvider);
    final locale = state.fixedLocale;
    final themeMode = switch (state.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        setActivePalette(
          dark ? AletheiaPalette.dark : AletheiaPalette.light,
        );
        // Recrea el subárbol al cambiar de tema para que los widgets `const`
        // que leen la paleta activa vuelvan a construir sus colores.
        return KeyedSubtree(
          key: ValueKey(dark ? 'dark' : 'light'),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const Shell(),
    );
  }
}
