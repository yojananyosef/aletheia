/// Fuentes de lectura del catálogo.
///
/// La app puede leer el catálogo de dos sitios sin cambiar los repositorios:
/// los assets empaquetados (escritorio y pruebas) o los archivos estáticos
/// publicados en `aletheia-mods` (web). Las rutas lógicas son las mismas que
/// usa el contrato del catálogo, por ejemplo:
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
import 'gzip_platform.dart';

/// La descarga se canceló desde la interfaz.
class CatalogDownloadCancelled implements Exception {
  const CatalogDownloadCancelled();

  @override
  String toString() => 'descarga del catálogo cancelada';
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
