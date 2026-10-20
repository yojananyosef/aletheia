import 'dart:convert';
import 'dart:math' show min;
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle;
import 'package:sqlite3/common.dart';

import '../core/web_sqlite.dart';
import 'gzip_platform.dart';

const _indexAsset = 'assets/catalog/search.sqlite.gz';
const _metaAsset = 'assets/catalog/search.meta.json';

var _nextFileSystem = 0;

/// En web no hay un directorio de datos síncrono: se descomprime el índice y
/// se monta en un VFS en memoria, que SQLite puede consultar con FTS5.
Future<CommonDatabase> openLocalSearchDatabase({
  required AssetBundle bundle,
  Future<String> Function()? cacheDirectoryProvider,
}) async {
  final meta = await _readMeta(bundle);
  final data = await bundle.load(_indexAsset);
  final compressed = data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
  final bytes = await decompressGzip(compressed);
  if (bytes.length != meta.bytes) {
    throw FormatException(
      'el índice empaquetado tiene ${bytes.length} bytes; '
      'se esperaban ${meta.bytes}',
    );
  }

  final sqlite = await loadWebSqlite();
  final fileSystem = _ReadOnlyBytesFileSystem(
    bytes,
    name: 'aletheia-search-${_nextFileSystem++}',
  );
  sqlite.registerVirtualFileSystem(fileSystem, makeDefault: false);

  return sqlite.open(
    _databasePath,
    vfs: fileSystem.name,
    mode: OpenMode.readOnly,
  );
}

const _databasePath = '/catalog.search.sqlite';

/// VFS de solo lectura que expone el índice sin copiarlo otra vez a memoria.
final class _ReadOnlyBytesFileSystem extends BaseVirtualFileSystem {
  _ReadOnlyBytesFileSystem(this.bytes, {required super.name});

  final Uint8List bytes;

  @override
  XOpenResult xOpen(Sqlite3Filename path, int flags) {
    if (path.path != _databasePath) {
      throw const VfsException(SqlError.SQLITE_CANTOPEN);
    }
    return (outFlags: 0, file: _BytesFile(bytes));
  }

  @override
  void xDelete(String path, int syncDir) {}

  @override
  int xAccess(String path, int flags) => path == _databasePath ? 1 : 0;

  @override
  String xFullPathName(String path) => path;

  @override
  void xSleep(Duration duration) {}
}

final class _BytesFile extends BaseVfsFile {
  _BytesFile(this.bytes);

  final Uint8List bytes;

  @override
  int readInto(Uint8List buffer, int offset) {
    if (offset >= bytes.length) return 0;
    final available = min(buffer.length, bytes.length - offset);
    buffer.setRange(0, available, bytes, offset);
    return available;
  }

  @override
  void xClose() {}

  @override
  void xWrite(Uint8List buffer, int fileOffset) {
    throw const VfsException(SqlError.SQLITE_READONLY);
  }

  @override
  void xTruncate(int size) {
    throw const VfsException(SqlError.SQLITE_READONLY);
  }

  @override
  void xSync(int flags) {}

  @override
  int xFileSize() => bytes.length;

  @override
  void xLock(int mode) {}

  @override
  void xUnlock(int mode) {}

  @override
  int xCheckReservedLock() => 0;
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
  return _IndexMeta(bytes: bytes);
}

class _IndexMeta {
  const _IndexMeta({required this.bytes});

  final int bytes;
}
