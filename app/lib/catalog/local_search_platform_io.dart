import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show AssetBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

const _indexAsset = 'assets/catalog/search.sqlite.gz';
const _metaAsset = 'assets/catalog/search.meta.json';

/// Extrae el índice comprimido al directorio de datos y lo abre en lectura.
Future<CommonDatabase> openLocalSearchDatabase({
  required AssetBundle bundle,
  Future<String> Function()? cacheDirectoryProvider,
}) async {
  final meta = await _readMeta(bundle);
  final directoryPath = cacheDirectoryProvider != null
      ? await cacheDirectoryProvider()
      : (await getApplicationSupportDirectory()).path;
  final directory = Directory(directoryPath);
  await directory.create(recursive: true);
  final path =
      '${directory.path}${Platform.pathSeparator}catalog.search.${meta.hash}.sqlite';
  final file = File(path);

  if (!await file.exists() || await file.length() != meta.bytes) {
    final data = await bundle.load(_indexAsset);
    final compressed = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final bytes = gzip.decode(compressed);
    if (bytes.length != meta.bytes) {
      throw FormatException(
        'el índice empaquetado tiene ${bytes.length} bytes; '
        'se esperaban ${meta.bytes}',
      );
    }

    // Escritura atómica: si la app se cierra a mitad, no queda un SQLite
    // truncado con el nombre definitivo.
    final temp = File('$path.${DateTime.now().microsecondsSinceEpoch}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    if (await file.exists()) await file.delete();
    await temp.rename(path);
  }

  return sqlite3.open(path, mode: OpenMode.readOnly);
}

Future<_IndexMeta> _readMeta(AssetBundle bundle) async {
  final raw = await bundle.loadString(_metaAsset);
  final json = jsonDecode(raw);
  if (json is! Map) {
    throw const FormatException('manifiesto del índice no válido');
  }
  final hash = json['indexHash'];
  final bytes = json['bytes'];
  if (hash is! String || hash.isEmpty || bytes is! int || bytes <= 0) {
    throw const FormatException('manifiesto del índice incompleto');
  }
  return _IndexMeta(hash: hash, bytes: bytes);
}

class _IndexMeta {
  const _IndexMeta({required this.hash, required this.bytes});

  final String hash;
  final int bytes;
}
