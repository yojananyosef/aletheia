import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog/catalog_source_providers.dart';
import 'catalog/install/modules_store.dart';
import 'catalog/mods_catalog_source.dart';
import 'core/app_backup.dart';
import 'core/app_database.dart';
import 'core/crash_log.dart';
import 'core/data_care.dart';
import 'core/localization.dart';
import 'core/theme.dart';
import 'courses/course_progress_persistence.dart';
import 'favorites/favorites_persistence.dart';
import 'notes/notes_persistence.dart';
import 'reading_plans/reading_plans_persistence.dart';
import 'shell/shell.dart';
import 'workspace/persistence.dart';
import 'workspace/workspace_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registro local de fallos (escritorio): captura errores de framework y de
  // zona en `<datos>/crash.log`, exportable desde Ajustes. Sin telemetría.
  final crashLog = CrashLog.install(resolveDir: openAppSupportDirectory);

  // Persistencia local-first en un único SQLite (archivo nativo o IndexedDB
  // en web).
  final database = await openAppDatabase();

  final store = WorkspaceStore.onDatabase(database);
  final notes = NotesStore.onDatabase(database);
  final readingPlans = ReadingPlansStore.onDatabase(database);
  final favorites = FavoritesStore.onDatabase(database);
  final courseProgress = CourseProgressStore.onDatabase(database);

  // Catálogo desacoplado (solo escritorio): los módulos se instalan a
  // `<datos>/modules` desde la Tienda; en web el service worker cachea.
  ModsCatalogSource? mods;
  ModulesStore? modules;
  AppBackup? backup;
  if (!kIsWeb) {
    mods = ModsCatalogSource();
    final support = await openAppSupportDirectory();
    modules = ModulesStore(
      baseDirectory: '${support.path}/modules',
      loadManifest: mods.loadManifest,
    );
    await modules.load();
    backup = AppBackup(dataDirectory: support);
  }

  runApp(
    ProviderScope(
      overrides: [
        if (!kIsWeb) ...[
          modsCatalogSourceProvider.overrideWithValue(mods!),
          modulesStoreProvider.overrideWithValue(modules!),
          appBackupProvider.overrideWithValue(backup!),
          crashLogProvider.overrideWithValue(crashLog),
        ],
        workspaceStoreProvider.overrideWithValue(store),
        notesStoreProvider.overrideWithValue(notes),
        readingPlansStoreProvider.overrideWithValue(readingPlans),
        favoritesStoreProvider.overrideWithValue(favorites),
        courseProgressStoreProvider.overrideWithValue(courseProgress),
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
        setActivePalette(dark ? AletheiaPalette.dark : AletheiaPalette.light);
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
