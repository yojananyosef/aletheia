import 'package:sqlite3/wasm.dart';

import 'database.dart';
import 'web_sqlite.dart';

/// Abre `aletheia.db` en IndexedDB para que el workspace y las notas
/// sobrevivan a recargas del navegador.
Future<AletheiaDatabase> openAppDatabase() async {
  final sqlite = await loadWebSqlite();
  final fileSystem = await IndexedDbFileSystem.open(dbName: 'aletheia_app');
  sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);
  final database = sqlite.open('aletheia.db');
  return AletheiaDatabase.fromDatabase(database);
}
