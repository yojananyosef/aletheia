/// Fuente de catálogo leída del directorio de módulos instalados en disco.
///
/// Mapea las rutas lógicas del catálogo (`assets/catalog/asv/manifest.json`)
/// a archivos reales bajo el directorio base (p. ej.
/// `<datos>/modules/asv/manifest.json`). `ModulesStore` guarda las descargas
/// con la misma ruta relativa que el catálogo, así que el mapeo es directo.
///
/// Si el archivo no existe lanza [FileNotFoundError]: es «el módulo está
/// instalado pero falta un archivo», distinto de «el módulo no está
/// instalado». El router ([RoutingCatalogSource]) decide que fuente responder
/// antes de llegar aquí.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../catalog_asset_source.dart';
import '../gzip_platform.dart';

class DiskCatalogSource implements CatalogAssetSource {
  DiskCatalogSource({required this.baseDirectory});

  /// Raíz de los módulos instalados (`<datos>/modules`).
  final String baseDirectory;

  File? fileFor(String logicalPath) {
    if (baseDirectory.isEmpty) return null;
    if (!logicalPath.startsWith(kCatalogAssetsPrefix)) return null;
    final relative = catalogRelativePath(logicalPath);
    final normalized = relative.replaceAll('/', Platform.pathSeparator);
    return File(
      '$baseDirectory${Platform.pathSeparator}$normalized',
    );
  }

  /// `true` si el archivo ya está en disco (instalado o parcial).
  Future<bool> exists(String logicalPath) async {
    final file = fileFor(logicalPath);
    if (file == null) return false;
    return await file.exists();
  }

  @override
  Future<String> loadText(String logicalPath) async {
    final file = fileFor(logicalPath);
    if (file == null || !await file.exists()) {
      throw FileNotFoundError(logicalPath);
    }
    final bytes = await file.readAsBytes();
    final plain = logicalPath.endsWith('.gz')
        ? await decompressGzip(bytes)
        : bytes;
    return utf8.decode(plain);
  }

  @override
  Future<Uint8List> loadBytes(String logicalPath) async {
    final file = fileFor(logicalPath);
    if (file == null || !await file.exists()) {
      throw FileNotFoundError(logicalPath);
    }
    return file.readAsBytes();
  }

  @override
  void dispose() {}
}
