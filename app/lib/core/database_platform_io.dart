/// Apertura de SQLite nativa.
///
/// En web no se usa esta fábrica: la aplicación abre SQLite mediante
/// `package:sqlite3/wasm.dart` en `app_database_web.dart`.
library;

import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

CommonDatabase openDatabaseFile(String path) => sqlite3.open(path);

CommonDatabase openMemoryDatabase() => sqlite3.openInMemory();
