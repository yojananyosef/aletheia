/// Router de fuentes del catálogo en escritorio.
///
/// Decide de dónde se lee cada ruta lógica sin reconstruir proveedores:
///
/// 1. **Módulo instalado en disco** (`ModulesStore.ownsPath`): la Tienda
///    descargó el módulo a `<datos>/modules/…` → [DiskCatalogSource].
/// 2. **Empaquetado con la app** (RV1909 y el léxico Strongs, para que las
///    primeras cargas funcionen sin instalar nada) → [AssetCatalogSource].
/// 3. **No instalado** → [CatalogNotInstalledException], que el Lector y la
///    Búsqueda traducen en una tarjeta con CTA «Instalar en la Tienda».
///
/// La web no usa este router: su cadena es remoto → empaquetado y el service
/// worker se encarga de la caché.
library;

import 'dart:typed_data';

import '../catalog_asset_source.dart';
import 'disk_catalog_source.dart';
import 'mods_manifest.dart';
import 'modules_store.dart';

/// Módulos que siguen dentro del ejecutable aunque el catálogo sea
/// desacoplado: leen en frío sin red ni instalación. Platense y el léxico
/// cubren la primera lectura; el devocional diario y el Factbook son el
/// «arranque en frío» de Inicio e Ideas (y suman ~40 KB embebidos).
const kBundledCatalogModules = {
  'bible.platense',
  'lexicon.strongs',
  'devotional.daily',
  'factbook.core',
};

class RoutingCatalogSource implements CatalogAssetSource {
  RoutingCatalogSource({
    required this.modulesStore,
    required this.disk,
    required this.assets,
  });

  final ModulesStore modulesStore;
  final DiskCatalogSource disk;
  final CatalogAssetSource assets;

  @override
  Future<String> loadText(String path) async {
    final source = _route(path);
    if (source == null) {
      throw CatalogNotInstalledException(
        moduleId: ModuleEntry.idForPath(path) ?? path,
        path: path,
      );
    }
    return source.loadText(path);
  }

  @override
  Future<Uint8List> loadBytes(String path) async {
    final source = _route(path);
    if (source == null) {
      throw CatalogNotInstalledException(
        moduleId: ModuleEntry.idForPath(path) ?? path,
        path: path,
      );
    }
    return source.loadBytes(path);
  }

  /// La fuente que atiende la ruta, o `null` para «módulo no instalado».
  CatalogAssetSource? _route(String path) {
    final moduleId = ModuleEntry.idForPath(path);
    if (moduleId == null) {
      // Metadatos compartidos (index, morfología, mapa): empaquetados.
      return assets;
    }
    if (modulesStore.ownsPath(path)) return disk;
    if (kBundledCatalogModules.contains(moduleId)) return assets;
    return null;
  }

  @override
  void dispose() {
    disk.dispose();
    assets.dispose();
  }
}
