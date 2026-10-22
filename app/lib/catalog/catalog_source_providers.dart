/// Selección de la fuente del catálogo según la plataforma.
///
/// - **Web**: `aletheia-mods` al vuelo (con respaldo empaquetado ligero) y el
///   service worker cachea lo descargado.
/// - **Escritorio**: catálogo desacoplado con módulos explícitos: la Tienda
///   instala en disco con progreso y cancelación (`ModulesStore`, anulado por
///   `main()`), y el lector pasa por el router: instalado → empaquetado →
///   no instalado.
///
/// La [ModsCatalogSource] existe solo para lectura en web: en escritorio la
/// Tienda usa el manifiesto que trae el propio [ModulesStore] en su
/// constructor, de modo que ningún panel conecta a la red sin pedirlo.
library;

import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_asset_source.dart';
import 'install/disk_catalog_source.dart';
import 'install/mods_manifest.dart';
import 'install/modules_store.dart';
import 'install/routing_catalog_source.dart';
import 'mods_catalog_source.dart';

/// Cliente del catálogo remoto (`aletheia-mods`) para *leer*.
///
/// `null` en escritorio: allí las lecturas van por el router del catálogo y
/// la Tienda usa su propio cliente (`ModulesStore.loadManifest`).
final modsCatalogSourceProvider = Provider<ModsCatalogSource?>((ref) {
  if (!kIsWeb) return null;
  final source = ModsCatalogSource();
  ref.onDispose(source.dispose);
  return source;
});

/// Progreso de la descarga del índice (solo web), o `null` si no hay activa.
final catalogTransferProvider = Provider<ValueNotifier<CatalogTransfer?>?>(
  (ref) => ref.watch(modsCatalogSourceProvider)?.transfer,
);

/// Manifiesto de módulos del catálogo remoto (`mods.json` v2), para la
/// Tienda. `null` sin red, en web (no hay tienda de módulos) y también
/// cuando el publicado todavía no trae el listado de archivos por módulo.
final catalogModulesManifestProvider =
    FutureProvider.autoDispose<CatalogModulesManifest?>((ref) {
      final store = ref.watch(modulesStoreProvider);
      if (store == null) return null;
      return store.loadManifest();
    });

/// Store de módulos instalables (instalar/cancelar/desinstalar).
///
/// Por defecto `null`: la web no instala (su service worker cachea al usar)
/// y `main()` lo sustituye por el real con el directorio de datos. Las
/// pruebas pueden anularlo con un store temporal o dejarlo nulo.
final modulesStoreProvider = Provider<ModulesStore?>((ref) => null);

/// Fuente del catálogo que usan lector, búsqueda y secciones.
final catalogAssetSourceProvider = Provider<CatalogAssetSource>((ref) {
  if (kIsWeb) {
    final mods = ref.watch(modsCatalogSourceProvider);
    if (mods != null) {
      return FallbackCatalogSource(primary: mods, fallback: AssetCatalogSource());
    }
  }
  final store = ref.watch(modulesStoreProvider);
  if (store == null) return AssetCatalogSource();
  return RoutingCatalogSource(
    modulesStore: store,
    disk: DiskCatalogSource(baseDirectory: store.baseDirectory),
    assets: AssetCatalogSource(),
  );
});
