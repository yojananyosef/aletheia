/// Fuentes de lectura del catálogo.
///
/// La app puede leer el catálogo de varios sitios sin cambiar los
/// repositorios: los assets empaquetados (siempre disponibles), los archivos
/// estáticos publicados en `aletheia-mods` (web) y los módulos instalados en
/// disco (escritorio). Las rutas lógicas son las mismas que usa el contrato
/// del catálogo, por ejemplo:
///
///   assets/catalog/rv1909/manifest.json
///   assets/catalog/rv1909/books/GEN.json.gz
///   assets/catalog/search.sqlite.gz
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'asset_json.dart';
import 'catalog_client.dart' show CatalogException;
import 'gzip_platform.dart';

export 'catalog_client.dart' show CatalogException;

/// La descarga se canceló desde la interfaz.
class CatalogDownloadCancelled implements Exception {
  const CatalogDownloadCancelled();

  @override
  String toString() => 'descarga del catálogo cancelada';
}

/// Prefijo lógico de todas las rutas del catálogo.
const kCatalogAssetsPrefix = 'assets/catalog/';

/// Ruta relativa al catálogo de una ruta lógica
/// (`assets/catalog/asv/manifest.json` → `asv/manifest.json`).
String catalogRelativePath(String logicalPath) =>
    logicalPath.startsWith(kCatalogAssetsPrefix)
    ? logicalPath.substring(kCatalogAssetsPrefix.length)
    : logicalPath;

/// El contenido pedido pertenece a un módulo del catálogo desacoplado que no
/// está instalado (y no viene empaquetado con la app).
///
/// El lector y la búsqueda lo traducen en una tarjeta con un CTA «Instalar en
/// la Tienda» en vez de un error crudo: guiar a la Tienda es parte del flujo
/// normal de un catálogo desacoplado.
class CatalogNotInstalledException extends CatalogException {
  const CatalogNotInstalledException({
    required this.moduleId,
    this.path,
  }) : super('módulo no instalado: $moduleId');

  /// Id del módulo (`bible.asv`, `catalog.search`, …).
  final String moduleId;

  /// Ruta lógica del archivo que se intentó leer, si aplica.
  final String? path;
}

/// El archivo no existe en ninguna fuente (p. ej. un módulo instalado al que
/// le falta un archivo). Distinto de [CatalogNotInstalledException]: el
/// remedio es reinstalar el módulo, no instalarlo.
class FileNotFoundError extends CatalogException {
  const FileNotFoundError(this.path) : super('no se encontró $path');

  final String path;
}

abstract class CatalogAssetSource {
  /// Carga un texto. Si la ruta termina en `.gz`, la descomprime.
  Future<String> loadText(String path);

  /// Carga bytes exactos (por ejemplo el índice SQLite comprimido).
  Future<Uint8List> loadBytes(String path);

  void dispose() {}
}

/// Catálogo empaquetado con la aplicación.
class AssetCatalogSource implements CatalogAssetSource {
  AssetCatalogSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<String> loadText(String path) async {
    if (path.endsWith('.gz')) {
      final data = await _bundle.load(path);
      return utf8.decode(
        await decompressGzip(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        ),
      );
    }
    return loadCatalogAssetText(_bundle, path);
  }

  @override
  Future<Uint8List> loadBytes(String path) async {
    final data = await _bundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  @override
  void dispose() {}
}

/// Intenta la fuente principal y, si falla, usa la empaquetada.
///
/// En web permite que RV1909 y los metadatos pequeños sigan disponibles sin
/// red, aunque el resto del catálogo se descargue de `aletheia-mods`.
class FallbackCatalogSource implements CatalogAssetSource {
  FallbackCatalogSource({required this.primary, required this.fallback});

  final CatalogAssetSource primary;
  final CatalogAssetSource fallback;

  Future<T> _withFallback<T>(
    Future<T> Function(CatalogAssetSource) call,
  ) async {
    try {
      return await call(primary);
    } on CatalogDownloadCancelled {
      rethrow;
    } on Object catch (error) {
      debugPrint('catálogo remoto no disponible ($error); uso copia local');
      return call(fallback);
    }
  }

  @override
  Future<String> loadText(String path) =>
      _withFallback((source) => source.loadText(path));

  @override
  Future<Uint8List> loadBytes(String path) =>
      _withFallback((source) => source.loadBytes(path));

  @override
  void dispose() {
    primary.dispose();
    fallback.dispose();
  }
}
