/// Carga de JSON del catálogo empaquetado.
///
/// Los libros de las Biblias y los índices de secciones grandes se guardan
/// como `.json.gz` para reducir el tamaño de la instalación (el hebreo, el
/// griego y el léxico comprimen a ~10–15 % de su tamaño original). Los
/// manifiestos y las secciones pequeñas pueden seguir en JSON plano. La
/// lectura intenta primero el archivo plano y, si no existe, el comprimido.
library;

import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart' show AssetBundle;

Future<String> loadCatalogAssetText(AssetBundle bundle, String path) async {
  try {
    return await bundle.loadString(path);
  } on FlutterError {
    final data = await bundle.load('$path.gz');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return utf8.decode(gzip.decode(bytes));
  }
}
